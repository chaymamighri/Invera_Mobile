import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/procurement_models.dart';

class ProcurementService {
  static const int _maxCreateProductAttempts = 6;

  Future<List<ProcurementCategory>> getCategories({String? keyword}) async {
    final hasKeyword = keyword != null && keyword.trim().isNotEmpty;
    final uri = hasKeyword
        ? Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.categoriesSearchEndpoint}',
          ).replace(queryParameters: {'keyword': keyword.trim()})
        : Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categoriesAllEndpoint}');
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(response, body, 'Erreur lors du chargement des categories');

    return _parseCategoryList(body);
  }

  Future<ProcurementCategory> createCategory(
    ProcurementCategoryUpsertPayload payload,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categoriesPrefix}');
    final response = await http
        .post(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseCategoryResponse(
      response,
      'Erreur lors de la creation de la categorie',
    );
  }

  Future<ProcurementCategory> updateCategory(
    int id,
    ProcurementCategoryUpsertPayload payload,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.categoriesPrefix}/$id',
    );
    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseCategoryResponse(
      response,
      'Erreur lors de la mise a jour de la categorie',
    );
  }

  Future<void> deleteCategory(int id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.categoriesPrefix}/$id',
    );
    final response = await http
        .delete(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la suppression de la categorie',
    );
  }

  Future<List<ProcurementSupplier>> getSuppliers({
    bool activeOnly = true,
  }) async {
    final endpoint = activeOnly
        ? ApiConfig.fournisseursActiveEndpoint
        : ApiConfig.fournisseursAllEndpoint;
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors du chargement des fournisseurs',
    );

    if (body is! List) return [];

    return body
        .whereType<Map<String, dynamic>>()
        .map(ProcurementSupplier.fromJson)
        .toList();
  }

  Future<List<ProcurementProduct>> getProducts({
    String? keyword,
    String? status,
    int? categorieId,
    bool? actif,
  }) async {
    final hasFilters =
        (keyword != null && keyword.trim().isNotEmpty) ||
        (status != null && status.trim().isNotEmpty) ||
        categorieId != null ||
        actif != null;

    final uri = hasFilters
        ? Uri.parse(
            '${ApiConfig.baseUrl}${ApiConfig.productsSearchEndpoint}',
          ).replace(
            queryParameters: {
              if (keyword != null && keyword.trim().isNotEmpty)
                'keyword': keyword.trim(),
              if (status != null && status.trim().isNotEmpty)
                'status': status.trim().toUpperCase(),
              if (categorieId != null) 'categorieId': '$categorieId',
              if (actif != null) 'actif': '$actif',
            },
          )
        : Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsAllEndpoint}');

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors du chargement des produits',
      requireSuccessFlag: true,
    );

    final produits = body is Map<String, dynamic> ? body['produits'] : null;
    if (produits is! List) return [];

    return produits
        .whereType<Map<String, dynamic>>()
        .map(ProcurementProduct.fromJson)
        .toList();
  }

  Future<List<ProcurementProduct>> getLowStockProducts() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.productsLowStockEndpoint}',
    );
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors du chargement des produits a stock faible',
      requireSuccessFlag: true,
    );

    final produits = body is Map<String, dynamic> ? body['produits'] : null;
    if (produits is! List) return [];

    return produits
        .whereType<Map<String, dynamic>>()
        .map(ProcurementProduct.fromJson)
        .toList();
  }

  Future<ProcurementProduct> createProduct(ProductUpsertPayload payload) async {
    http.Response? lastResponse;
    dynamic lastBody;

    for (var attempt = 1; attempt <= _maxCreateProductAttempts; attempt++) {
      final response = await _sendMultipartRequest(
        method: 'POST',
        uri: Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsAddEndpoint}'),
        fields: payload.toMultipartFields(),
        file: payload.hasImageUpload
            ? http.MultipartFile.fromBytes(
                'image',
                payload.imageBytes!,
                filename: payload.imageFileName,
                contentType: MediaType.parse(
                  payload.imageMimeType ?? 'image/jpeg',
                ),
              )
            : null,
      );

      final body = _decodeBody(response);
      lastResponse = response;
      lastBody = body;

      final successFlag = body is Map<String, dynamic> ? body['success'] : null;
      final statusOk = response.statusCode >= 200 && response.statusCode < 300;
      if (statusOk && successFlag == true) {
        final produit = body['produit'];
        if (produit is! Map<String, dynamic>) {
          throw Exception('Reponse produit invalide');
        }
        return ProcurementProduct.fromJson(produit);
      }

      final canRetry =
          attempt < _maxCreateProductAttempts &&
          _isRetriableCreateProductFailure(response, body);
      if (!canRetry) {
        _ensureSuccess(
          response,
          body,
          'Erreur lors de la creation du produit',
          requireSuccessFlag: true,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    _ensureSuccess(
      lastResponse!,
      lastBody,
      'Erreur lors de la creation du produit',
      requireSuccessFlag: true,
    );
    throw Exception('Erreur lors de la creation du produit');
  }

  Future<ProcurementProduct> updateProduct(
    int id,
    ProductUpsertPayload payload,
  ) async {
    final response = await _sendMultipartRequest(
      method: 'PUT',
      uri: Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.productsPrefix}/update/$id',
      ),
      fields: payload.toMultipartFields(),
      file: payload.hasImageUpload
          ? http.MultipartFile.fromBytes(
              'image',
              payload.imageBytes!,
              filename: payload.imageFileName,
              contentType: MediaType.parse(
                payload.imageMimeType ?? 'image/jpeg',
              ),
            )
          : null,
    );

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la mise a jour du produit',
      requireSuccessFlag: true,
    );

    final produit = body is Map<String, dynamic> ? body['produit'] : null;
    if (produit is! Map<String, dynamic>) {
      throw Exception('Reponse produit invalide');
    }

    return ProcurementProduct.fromJson(produit);
  }

  Future<void> deleteProduct(int id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.productsPrefix}/delete/$id',
    );
    final response = await http
        .delete(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la desactivation du produit',
      requireSuccessFlag: true,
    );
  }

  Future<ProcurementProduct> reactivateProduct(int id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.productsPrefix}/$id/reactiver',
    );
    final response = await http
        .patch(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la reactivation du produit',
      requireSuccessFlag: true,
    );

    final produit = body is Map<String, dynamic> ? body['produit'] : null;
    if (produit is! Map<String, dynamic>) {
      throw Exception('Reponse produit invalide');
    }

    return ProcurementProduct.fromJson(produit);
  }

  Future<ProcurementProduct> updateProductStock(int id, int quantite) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.productsPrefix}/$id/stock',
    ).replace(queryParameters: {'quantite': '$quantite'});
    final response = await http
        .patch(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la mise a jour du stock',
      requireSuccessFlag: true,
    );

    final produit = body is Map<String, dynamic> ? body['produit'] : null;
    if (produit is! Map<String, dynamic>) {
      throw Exception('Reponse produit invalide');
    }

    return ProcurementProduct.fromJson(produit);
  }

  Future<List<ProcurementOrder>> getOrders({bool archived = false}) async {
    final endpoint = archived
        ? ApiConfig.commandesFournisseursArchivedEndpoint
        : ApiConfig.commandesFournisseursAllEndpoint;
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(response, body, 'Erreur lors du chargement des commandes');

    if (body is! List) return [];

    return body
        .whereType<Map<String, dynamic>>()
        .map(ProcurementOrder.fromJson)
        .toList();
  }

  Future<ProcurementOrder> createOrder(
    ProcurementOrderCreatePayload payload,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursAddEndpoint}',
    );
    final response = await http
        .post(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors de la creation de la commande fournisseur',
    );
  }

  Future<ProcurementOrder> updateOrder(
    int id,
    ProcurementOrderUpdatePayload payload,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/update/$id',
    );
    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors de la mise a jour de la commande fournisseur',
    );
  }

  Future<void> deleteOrder(int id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/delete/$id',
    );
    final response = await http
        .delete(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    if (response.statusCode == 204) return;

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la suppression de la commande',
    );
  }

  Future<ProcurementOrder> validateOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/valider',
      'Erreur lors de la validation de la commande',
    );
  }

  Future<ProcurementOrder> sendOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/envoyer',
      'Erreur lors de l\'envoi de la commande',
    );
  }

  Future<ProcurementOrder> receiveOrder(
    int id, {
    Map<int, int>? quantitesRecues,
    String? numeroBL,
    Map<int, bool>? produitsAReactiver,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/$id/recevoir',
    );

    final bodyPayload = <String, dynamic>{
      if (numeroBL != null && numeroBL.trim().isNotEmpty)
        'numeroBL': numeroBL.trim(),
      if (quantitesRecues != null)
        'quantitesRecues': {
          for (final entry in quantitesRecues.entries)
            '${entry.key}': entry.value,
        },
      if (produitsAReactiver != null)
        'produitsAReactiver': {
          for (final entry in produitsAReactiver.entries)
            '${entry.key}': entry.value,
        },
    };

    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode(bodyPayload),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors de la reception de la commande',
    );
  }

  Future<ProcurementOrder> invoiceOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/facturer',
      'Erreur lors de la facturation de la commande',
    );
  }

  Future<ProcurementOrder> rejectOrder(int id, String motif) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/$id/rejeter',
    );

    final response = await http
        .put(
          uri,
          headers: await _buildHeaders(),
          body: json.encode({'motifRejet': motif.trim()}),
        )
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors du rejet de la commande',
    );
  }

  Future<ProcurementOrder> resendOrderAfterRejection(int id) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/$id/renvoyer_attente',
    );

    final response = await http
        .put(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors du renvoi de la commande apres rejet',
    );
  }

  Future<ProcurementOrder> cancelOrder(int id, {String? reason}) async {
    final uri =
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/$id/annuler',
        ).replace(
          queryParameters: {
            if (reason != null && reason.trim().isNotEmpty)
              'raison': reason.trim(),
          },
        );

    final response = await http
        .put(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors de l\'annulation de la commande',
    );
  }

  Future<ProcurementOrder> restoreOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/restore',
      'Erreur lors de la restauration de la commande',
    );
  }

  Future<ProcurementOrder> getOrderByNumber(String numero) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/recherche/numero',
    ).replace(queryParameters: {'numero': numero.trim()});

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(
      response,
      'Erreur lors de la recherche de la commande',
    );
  }

  Future<List<ProcurementOrder>> searchOrdersByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final uri =
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.commandesFournisseursPrefix}/recherche/periode',
        ).replace(
          queryParameters: {
            'debut': start.toIso8601String(),
            'fin': end.toIso8601String(),
          },
        );

    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la recherche des commandes par periode',
    );

    if (body is! List) return [];

    return body
        .whereType<Map<String, dynamic>>()
        .map(ProcurementOrder.fromJson)
        .toList();
  }

  Future<ProcurementOrder> _orderAction(
    String endpoint,
    String fallback,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http
        .put(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    return _parseOrderResponse(response, fallback);
  }

  Future<http.Response> _sendMultipartRequest({
    required String method,
    required Uri uri,
    required Map<String, String> fields,
    http.MultipartFile? file,
  }) async {
    final request = http.MultipartRequest(method, uri);
    request.fields.addAll(fields);
    if (file != null) {
      request.files.add(file);
    }
    request.headers.addAll(await _buildHeaders(includeContentType: false));
    final streamed = await request.send().timeout(
      const Duration(milliseconds: ApiConfig.connectionTimeout),
    );
    return http.Response.fromStream(streamed);
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeContentType = true,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': ApiConfig.contentType,
    };

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.trim().isNotEmpty) {
      headers[ApiConfig.authHeader] = '${ApiConfig.bearerPrefix}$token';
    }

    return headers;
  }

  ProcurementOrder _parseOrderResponse(
    http.Response response,
    String fallback,
  ) {
    final body = _decodeBody(response);
    _ensureSuccess(response, body, fallback);

    if (body is! Map<String, dynamic>) {
      throw Exception('Reponse commande invalide');
    }

    return ProcurementOrder.fromJson(body);
  }

  ProcurementCategory _parseCategoryResponse(
    http.Response response,
    String fallback,
  ) {
    final body = _decodeBody(response);
    _ensureSuccess(response, body, fallback);

    if (body is! Map<String, dynamic>) {
      throw Exception('Reponse categorie invalide');
    }

    return ProcurementCategory.fromJson(body);
  }

  List<ProcurementCategory> _parseCategoryList(dynamic body) {
    final categories = body is List
        ? body
        : (body is Map<String, dynamic> ? body['categories'] : null);
    if (categories is! List) return [];

    return categories
        .whereType<Map<String, dynamic>>()
        .map(ProcurementCategory.fromJson)
        .toList();
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;

    try {
      return json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      final raw = utf8.decode(response.bodyBytes).trim();
      return raw.isEmpty ? null : raw;
    }
  }

  void _ensureSuccess(
    http.Response response,
    dynamic body,
    String fallback, {
    bool requireSuccessFlag = false,
  }) {
    final statusOk = response.statusCode >= 200 && response.statusCode < 300;
    final successFlag = body is Map<String, dynamic> ? body['success'] : null;
    final successOk = !requireSuccessFlag || successFlag == true;

    if (statusOk && successOk) return;

    throw Exception(
      _extractMessage(body, fallback, statusCode: response.statusCode),
    );
  }

  String _extractMessage(dynamic body, String fallback, {int? statusCode}) {
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'] ?? body['details'];
      if (message is String && message.trim().isNotEmpty) {
        return _normalizeServerMessage(
          message.trim(),
          fallback,
          statusCode: statusCode,
        );
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      return _normalizeServerMessage(
        body.trim(),
        fallback,
        statusCode: statusCode,
      );
    }

    return _fallbackMessage(fallback, statusCode);
  }

  String _normalizeServerMessage(
    String raw,
    String fallback, {
    int? statusCode,
  }) {
    if (_isDuplicateProductPrimaryKeyError(raw)) {
      return 'Creation impossible: le serveur tente de reutiliser un identifiant produit deja existant. Reessayez apres correction de la base.';
    }

    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('erreur:') || lower.startsWith('error:')) {
        return line;
      }
    }

    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.startsWith('at ') ||
          lower.startsWith('org.') ||
          lower.startsWith('java.') ||
          lower.startsWith('jakarta.') ||
          lower.startsWith('caused by:')) {
        continue;
      }
      return line;
    }

    return _fallbackMessage(fallback, statusCode);
  }

  String _fallbackMessage(String fallback, int? statusCode) {
    switch (statusCode) {
      case 401:
        return 'Session invalide ou expiree';
      case 403:
        return 'Acces refuse pour cette operation';
      case 404:
        return 'Endpoint introuvable';
      case 500:
        return fallback;
      default:
        return fallback;
    }
  }

  bool _isRetriableCreateProductFailure(http.Response response, dynamic body) {
    if (response.statusCode < 500) return false;

    if (body is Map<String, dynamic>) {
      final raw = body['message'] ?? body['error'] ?? body['details'];
      if (raw is String) {
        return _isDuplicateProductPrimaryKeyError(raw);
      }
    }

    if (body is String) {
      return _isDuplicateProductPrimaryKeyError(body);
    }

    return false;
  }

  bool _isDuplicateProductPrimaryKeyError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('produit_pkey') ||
        (lower.contains('duplicate key') && lower.contains('id_produit')) ||
        (lower.contains('id_produit') && lower.contains('existe deja')) ||
        (lower.contains('id_produit') && lower.contains('already exists'));
  }
}