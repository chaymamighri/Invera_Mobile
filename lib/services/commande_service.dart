import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/commande_model.dart';

class CommandeService {
  Future<List<CommandeModel>> getCommandes({String? statut, int? clientId}) async {
    final query = <String, String>{};
    if (statut != null && statut.trim().isNotEmpty) {
      query['statut'] = statut.trim().toUpperCase();
    }
    if (clientId != null && clientId > 0) {
      query['clientId'] = clientId.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listCommandesEndpoint}')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors du chargement des commandes'));
    }

    final commandes = body['commandes'];
    if (commandes is! List) return [];

    return commandes
        .whereType<Map<String, dynamic>>()
        .map(CommandeModel.fromJson)
        .toList();
  }

  Future<CommandeModel> getCommandeById(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commandesPrefix}/$id');
    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors du chargement de la commande'));
    }

    final commande = body['commande'];
    if (commande is! Map<String, dynamic>) {
      throw Exception('Reponse commande invalide');
    }

    return CommandeModel.fromJson(commande);
  }

  Future<CommandeModel> createCommande(CommandeCreatePayload payload) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createCommandeEndpoint}');
    final response = await http
        .post(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors de la creation de la commande'));
    }

    final commande = body['commande'];
    if (commande is! Map<String, dynamic>) {
      throw Exception('Reponse commande invalide');
    }

    return CommandeModel.fromJson(commande);
  }

  Future<CommandeModel> updateCommande(int id, CommandeUpdatePayload payload) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commandesPrefix}/$id');
    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors de la mise a jour de la commande'));
    }

    final commande = body['commande'];
    if (commande is! Map<String, dynamic>) {
      throw Exception('Reponse commande invalide');
    }

    return CommandeModel.fromJson(commande);
  }

  Future<CommandeModel> rejeterCommande(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.commandesPrefix}/$id/rejeter');
    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(<String, dynamic>{}),
        )
        .timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors de l\'annulation de la commande'));
    }

    final commande = body['commande'];
    if (commande is! Map<String, dynamic>) {
      throw Exception('Reponse commande invalide');
    }

    return CommandeModel.fromJson(commande);
  }

  Future<List<ProduitOption>> getProduits() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsAllEndpoint}');
    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors du chargement des produits'));
    }

    final produits = body['produits'];
    if (produits is! List) return [];

    return produits
        .whereType<Map<String, dynamic>>()
        .map(ProduitOption.fromJson)
        .toList();
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  String _extractMessage(Map<String, dynamic> data, String fallback) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{'Content-Type': ApiConfig.contentType};
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.trim().isNotEmpty) {
      headers[ApiConfig.authHeader] = '${ApiConfig.bearerPrefix}$token';
    }

    return headers;
  }
}
