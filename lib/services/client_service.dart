import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/client_model.dart';

class ClientService {
  Future<List<ClientModel>> getClients({String? query}) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final uri = hasQuery
        ? Uri.parse('${ApiConfig.baseUrl}${ApiConfig.searchClientsEndpoint}')
            .replace(queryParameters: {'q': query.trim()})
        : Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listClientsEndpoint}');

    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractMessage(body, 'Erreur lors du chargement des clients'));
    }

    final success = body['success'] == true;
    if (!success) {
      throw Exception(_extractMessage(body, 'Requete client invalide'));
    }

    final rawClients = body['clients'];
    if (rawClients is! List) return [];

    return rawClients
        .whereType<Map<String, dynamic>>()
        .map(ClientModel.fromJson)
        .toList();
  }

  Future<List<String>> getClientTypes() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clientTypesEndpoint}');
    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }

    if (body['success'] != true) return [];

    final types = body['types'];
    if (types is! List) return [];

    return types.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  Future<ClientModel> createClient(NouveauClientPayload payload) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.createClientEndpoint}');
    const maxAttempts = 20;
    String? lastMessage;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
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
      final rawBody = response.body.trim();
      final message = _extractMessage(
        body,
        rawBody.isNotEmpty ? rawBody : 'Erreur lors de la creation du client',
      );

      if (response.statusCode >= 200 && response.statusCode < 300 && body['success'] == true) {
        final raw = body['client'];
        if (raw is! Map<String, dynamic>) {
          throw Exception('Reponse client invalide');
        }
        return ClientModel.fromJson(raw);
      }

      lastMessage = message;
      final retryablePkCollision = _isDuplicateClientPrimaryKeyError(message);
      if (!retryablePkCollision || attempt == maxAttempts) {
        throw Exception(message);
      }

      await Future.delayed(const Duration(milliseconds: 120));
    }

    throw Exception(lastMessage ?? 'Erreur lors de la creation du client');
  }

  Future<ClientModel> updateClient(int id, NouveauClientPayload payload) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateClientEndpoint}/$id');
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
      throw Exception(_extractMessage(body, 'Erreur lors de la modification du client'));
    }

    final raw = body['client'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Reponse client invalide');
    }

    return ClientModel.fromJson(raw);
  }

  Future<void> deleteClient(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.clientsPrefix}/$id');
    final response = await http.delete(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      throw Exception(_extractMessage(body, 'Erreur lors de la suppression du client'));
    }
  }

  Future<bool> checkTelephoneExists(String telephone) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.verifyClientPhoneEndpoint}')
        .replace(queryParameters: {'telephone': telephone.trim()});
    final response = await http.get(uri, headers: await _buildHeaders()).timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
        );

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || body['success'] != true) {
      return false;
    }

    return body['exists'] == true;
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

  bool _isDuplicateClientPrimaryKeyError(String message) {
    final lower = message.toLowerCase();
    return (lower.contains('client_pkey') && lower.contains('id_client')) ||
        (lower.contains('duplicate key') && lower.contains('id_client')) ||
        (lower.contains('cle dupliquee') && lower.contains('client_pkey'));
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
