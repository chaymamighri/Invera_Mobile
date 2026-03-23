import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/procurement_models.dart';

class ProcurementService {
  Future<List<ProcurementCategory>> getCategories() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.categoriesAllEndpoint}',
    );
    final response = await http
        .get(uri, headers: await _buildHeaders())
        .timeout(const Duration(milliseconds: ApiConfig.connectionTimeout));

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors du chargement des categories',
      requireSuccessFlag: true,
    );

    final categories = body is Map<String, dynamic> ? body['categories'] : null;
    if (categories is! List) return [];

    return categories
        .whereType<Map<String, dynamic>>()
        .map(ProcurementCategory.fromJson)
        .toList();
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
    final response = await _sendMultipartRequest(
      method: 'POST',
      uri: Uri.parse('${ApiConfig.baseUrl}${ApiConfig.productsAddEndpoint}'),
      fields: payload.toMultipartFields(),
    );

    final body = _decodeBody(response);
    _ensureSuccess(
      response,
      body,
      'Erreur lors de la creation du produit',
      requireSuccessFlag: true,
    );

    final produit = body is Map<String, dynamic> ? body['produit'] : null;
    if (produit is! Map<String, dynamic>) {
      throw Exception('Reponse produit invalide');
    }

    return ProcurementProduct.fromJson(produit);
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

  Future<ProcurementOrder> receiveOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/recevoir',
      'Erreur lors de la reception de la commande',
    );
  }

  Future<ProcurementOrder> invoiceOrder(int id) {
    return _orderAction(
      '${ApiConfig.commandesFournisseursPrefix}/$id/facturer',
      'Erreur lors de la facturation de la commande',
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
  }) async {
    final request = http.MultipartRequest(method, uri);
    request.fields.addAll(fields);
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

    throw Exception(_extractMessage(body, fallback));
  }

  String _extractMessage(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    return fallback;
  }
}
