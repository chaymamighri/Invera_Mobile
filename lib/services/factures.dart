import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api.dart';
import '../models/facture.dart';

class FactureService {
  Future<List<FactureModel>> getAllFactures() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.facturesAllEndpoint}',
    );

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _httpErrorMessage(
          response,
          decoded,
          fallback: 'Erreur lors du chargement des factures',
        ),
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FactureModel.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(FactureModel.fromJson)
            .toList();
      }
    }

    return <FactureModel>[];
  }

  Future<FactureModel?> getFactureByCommandeId(int commandeId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.facturesPrefix}/commande/$commandeId',
    );

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    if (response.statusCode == 404) return null;

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _httpErrorMessage(
          response,
          decoded,
          fallback: 'Erreur lors du chargement de la facture',
        ),
      );
    }

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'];
      final data = decoded['data'];

      if (success == false) return null;

      if (data is Map<String, dynamic>) {
        return FactureModel.fromJson(data);
      }

      return FactureModel.fromJson(decoded);
    }

    return null;
  }

  Future<FactureModel> generateFromCommande(int commandeId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.facturesGenerateEndpoint}/$commandeId',
    );

    final response = await http
        .post(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(<String, dynamic>{}),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final decoded = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _httpErrorMessage(
          response,
          decoded,
          fallback: 'Erreur lors de la generation de la facture',
        ),
      );
    }

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'];
      if (success == false) {
        throw Exception(
          _extractMessage(decoded, fallback: 'Generation de facture echouee'),
        );
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        final withCommande = Map<String, dynamic>.from(data)
          ..putIfAbsent('commandeId', () => commandeId)
          ..putIfAbsent('idCommandeClient', () => commandeId);
        try {
          return FactureModel.fromJson(withCommande);
        } catch (_) {
          // Fall back to loading generated invoice by commande ID.
        }
      }

      if (_looksLikeFacturePayload(decoded)) {
        final fallback = Map<String, dynamic>.from(decoded)
          ..putIfAbsent('commandeId', () => commandeId)
          ..putIfAbsent('idCommandeClient', () => commandeId);
        try {
          return FactureModel.fromJson(fallback);
        } catch (_) {
          // Fall back to loading generated invoice by commande ID.
        }
      }
    }

    try {
      final generated = await getFactureByCommandeId(commandeId);
      if (generated != null) return generated;
    } catch (_) {
      // Preserve original success path and return a clear functional error below.
    }

    throw Exception(
      'Generation terminee mais la facture de la commande $commandeId est introuvable.',
    );
  }

  dynamic _decodeResponse(http.Response response) {
    try {
      final decodedBody = utf8.decode(response.bodyBytes);
      if (decodedBody.trim().isEmpty) return <String, dynamic>{};
      return json.decode(decodedBody);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _httpErrorMessage(
    http.Response response,
    dynamic decoded, {
    required String fallback,
  }) {
    final fallbackByStatus = switch (response.statusCode) {
      401 => 'Session invalide ou expiree',
      403 => 'Acces refuse (verifiez role/permissions backend)',
      404 => 'Endpoint introuvable',
      _ => fallback,
    };

    final details = _extractMessage(decoded, fallback: fallbackByStatus);
    return 'HTTP ${response.statusCode}: $details';
  }

  String _extractMessage(dynamic payload, {required String fallback}) {
    if (payload is Map<String, dynamic>) {
      final rawMessage =
          payload['message'] ?? payload['error'] ?? payload['details'];
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        return rawMessage.trim();
      }

      final status = payload['status'];
      final path = payload['path'];
      if (status != null && path != null) {
        return '$status sur $path';
      }
    }

    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }

    return fallback;
  }

  bool _looksLikeFacturePayload(Map<String, dynamic> payload) {
    return payload.containsKey('idFactureClient') ||
        payload.containsKey('referenceFactureClient') ||
        payload.containsKey('montantTotal') ||
        payload.containsKey('commandeId') ||
        payload.containsKey('idCommandeClient');
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
