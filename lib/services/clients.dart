import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api.dart';
import '../models/client.dart';

class ClientService {
  Future<List<ClientModel>> getClients({String? query}) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final uri = hasQuery
        ? Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.searchClientsEndpoint}',
          ).replace(queryParameters: {'q': query.trim()})
        : Uri.parse('${ApiConfig.baseUrl}${ApiConfig.listClientsEndpoint}');

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(body, 'Erreur lors du chargement des clients'),
      );
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
    return List<String>.from(ClientType.allowedValues);
  }

  Future<double> getRemiseByType(String? typeClient) async {
    final normalizedType = ClientType.normalize(
      typeClient,
      fallbackToDefault: false,
    );
    if (normalizedType.trim().isEmpty) return 0;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.clientsPrefix}/remise/$normalizedType',
    );
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeResponse(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractMessage(body, 'Erreur lors du chargement de la remise client'),
      );
    }

    final rawValue = body['remise'];
    if (rawValue is num) {
      return rawValue.toDouble().clamp(0, 100).toDouble();
    }
    if (rawValue is String) {
      final parsed = double.tryParse(rawValue.trim());
      if (parsed != null) {
        return parsed.clamp(0, 100).toDouble();
      }
    }

    return 0;
  }

  Future<ClientModel> createClient(NouveauClientPayload payload) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.createClientEndpoint}',
    );
    const maxAttempts = 20;
    String? lastMessage;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final response = await http
          .post(
            uri,
            headers: await _buildHeaders(),
            body: json.encode(payload.toJson()),
          )
          .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

      final body = _decodeResponse(response);
      final rawBody = response.body.trim();
      final message = _extractMessage(
        body,
        rawBody.isNotEmpty ? rawBody : 'Erreur lors de la creation du client',
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
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
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.updateClientEndpoint}/$id',
    );
    final response = await http
        .post(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
      throw Exception(
        _extractMessage(body, 'Erreur lors de la modification du client'),
      );
    }

    final raw = body['client'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Reponse client invalide');
    }

    return ClientModel.fromJson(raw);
  }

  Future<void> deleteClient(int id) async {
    final headers = await _buildHeaders();
    final candidates = <({String method, String path})>[
      (method: 'DELETE', path: '${ApiConfig.clientsPrefix}/delete/$id'),
      (method: 'DELETE', path: '${ApiConfig.clientsPrefix}/$id'),
      (method: 'DELETE', path: '${ApiConfig.clientsPrefix}/supprimer/$id'),
      (method: 'POST', path: '${ApiConfig.clientsPrefix}/delete/$id'),
      (method: 'POST', path: '${ApiConfig.clientsPrefix}/supprimer/$id'),
    ];

    String? lastMessage;
    String? lastAttempt;
    int? lastStatusCode;

    for (final candidate in candidates) {
      final uri = Uri.parse('${ApiConfig.baseUrl}${candidate.path}');
      lastAttempt = '${candidate.method} ${candidate.path}';
      final response = await _sendDeleteRequest(
        candidate.method,
        uri,
        headers,
      ).timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));
      lastStatusCode = response.statusCode;

      if (response.statusCode == 204) return;

      final body = _decodeResponse(response);
      if (_isDeleteSuccess(response, body)) {
        return;
      }

      lastMessage = _extractMessage(
        body,
        'Erreur lors de la suppression du client',
      );

      final shouldTryNextRoute =
          response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 405 ||
          response.statusCode == 500 ||
          response.statusCode == 501;
      if (!shouldTryNextRoute) {
        break;
      }
    }

    final fallback = [
      'Erreur lors de la suppression du client',
      if (lastAttempt != null) 'route testee: $lastAttempt',
      if (lastStatusCode != null) 'status: $lastStatusCode',
    ].join(' | ');

    throw Exception(lastMessage ?? fallback);
  }

  Future<bool> checkTelephoneExists(String telephone) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.verifyClientPhoneEndpoint}',
    ).replace(queryParameters: {'telephone': telephone.trim()});
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeResponse(response);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] != true) {
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

  bool _isDeleteSuccess(http.Response response, Map<String, dynamic> body) {
    if (response.statusCode < 200 || response.statusCode >= 300) return false;
    if (body.isEmpty) return true;

    final success = body['success'];
    if (success is bool) return success;
    return true;
  }

  Future<http.Response> _sendDeleteRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
  ) {
    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers);
      case 'DELETE':
      default:
        return http.delete(uri, headers: headers);
    }
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
