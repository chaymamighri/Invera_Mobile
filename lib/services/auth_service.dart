import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthActionResult {
  final bool success;
  final String message;
  final int? statusCode;

  const AuthActionResult({
    required this.success,
    required this.message,
    this.statusCode,
  });
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;
  late final Future<void> _readyFuture;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthService() {
    _readyFuture = _loadStoredData();
  }

  Future<void> ready() => _readyFuture;

  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      final userJson = prefs.getString('user');

      if (_token != null && userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        notifyListeners();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement donnees: $e');
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
      final request = LoginRequest(email: email, password: password);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': ApiConfig.contentType,
              'Accept': 'application/json',
            },
            body: json.encode(request.toJson()),
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          json.decode(response.body),
        );

        _token = loginResponse.token;
        _currentUser = User(
          id: loginResponse.id,
          email: loginResponse.email,
          nom: loginResponse.nom,
          prenom: loginResponse.prenom,
          role: User.parseRole(loginResponse.role),
          active: true,
        );

        await _saveUserData(rememberMe);
        _setLoading(false);
        return true;
      }

      _error = _extractResponseMessage(
        response,
        fallback: 'Erreur de connexion (${response.statusCode})',
      );
      _setLoading(false);
      return false;
    } catch (e) {
      _error = _formatExceptionMessage(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> fetchCurrentUser() async {
    if (_token == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meEndpoint}');
      final response = await http.get(url, headers: _getAuthHeaders());

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(json.decode(response.body));
        await _saveUserData(true);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur fetch user: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _error = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }

  /// âœ… FIXED:
  /// - First attempt: POST with JSON body { email: ... } (most common Spring)
  /// - Fallback attempt: POST with query param (your old behavior)
  /// - NEVER sends Authorization header
  Future<AuthActionResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await ready();
      if (_token == null || _token!.trim().isEmpty) {
        _setLoading(false);
        return const AuthActionResult(
          success: false,
          message: 'Session invalide. Veuillez vous reconnecter.',
        );
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}',
      );
      final response = await http
          .put(
            url,
            headers: _getAuthHeaders(),
            body: json.encode(<String, dynamic>{
              'oldPassword': oldPassword,
              'newPassword': newPassword,
            }),
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      _setLoading(false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthActionResult(
          success: true,
          message: _extractResponseMessage(
            response,
            fallback: 'Mot de passe modifie avec succes',
          ),
          statusCode: response.statusCode,
        );
      }

      final message = _extractResponseMessage(
        response,
        fallback: 'Erreur lors de la modification du mot de passe',
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthActionResult(
          success: false,
          message: '$message (session non autorisee)',
          statusCode: response.statusCode,
        );
      }

      return AuthActionResult(
        success: false,
        message: message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<AuthActionResult> updateProfile({
    required String nom,
    required String prenom,
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await ready();
      if (_token == null || _token!.trim().isEmpty) {
        _setLoading(false);
        return const AuthActionResult(
          success: false,
          message: 'Session invalide. Veuillez vous reconnecter.',
        );
      }

      final normalizedNom = nom.trim();
      final normalizedPrenom = prenom.trim();
      final normalizedEmail = email.trim().toLowerCase();

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.updateProfileEndpoint}',
      );

      final response = await http
          .put(
            url,
            headers: _getAuthHeaders(),
            body: json.encode(<String, dynamic>{
              'nom': normalizedNom,
              'prenom': normalizedPrenom,
              'email': normalizedEmail,
            }),
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      final message = _extractResponseMessage(
        response,
        fallback: response.statusCode >= 200 && response.statusCode < 300
            ? 'Profil mis a jour avec succes'
            : 'Erreur lors de la mise a jour du profil (${response.statusCode})',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final refreshed = await fetchCurrentUser();

        if (!refreshed && _currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            email: normalizedEmail,
            nom: normalizedNom,
            prenom: normalizedPrenom,
            role: _currentUser!.role,
            active: _currentUser!.active,
          );
          await _saveUserData(true);
          notifyListeners();
        }

        _setLoading(false);
        return AuthActionResult(
          success: true,
          message: message,
          statusCode: response.statusCode,
        );
      }

      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<AuthActionResult> forgotPassword(String email) async {
    _setLoading(true);

    try {
      final normalizedEmail = email.trim().toLowerCase();

      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}',
      ).replace(queryParameters: {'email': normalizedEmail});

      final response = await http
          .post(
            url,
            headers: await _getPublicHeaders(), // NO AUTH
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      _setLoading(false);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthActionResult(
          success: true,
          message: _extractResponseMessage(
            response,
            fallback: 'Code de reinitialisation envoye',
          ),
          statusCode: response.statusCode,
        );
      }

      final message = _extractResponseMessage(
        response,
        fallback: 'Erreur lors de l\'envoi de l\'email',
      );

      if (response.statusCode == 403) {
        // ignore: avoid_print
        print('FORGOT 403 body: ${response.body}');
        return AuthActionResult(
          success: false,
          message: '$message (403 - acces refuse par le serveur)',
          statusCode: response.statusCode,
        );
      }

      return AuthActionResult(
        success: false,
        message: message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// âœ… FIXED:
  /// - NEVER sends Authorization header (no optional token attempts)
  /// - Cleans code spaces/newlines
  /// - Tries payload variants to match backend without changing backend
  Future<AuthActionResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      final normalizedEmail = email.trim().toLowerCase();
      final cleanedCode = code.replaceAll(RegExp(r'\s+'), '');
      final result = await _postPasswordNoAuth(
        endpoint: ApiConfig.resetPasswordEndpoint,
        payload: {
          'email': normalizedEmail,
          'code': cleanedCode,
          'newPassword': newPassword,
        },
        successFallback: 'Mot de passe modifie avec succes',
        errorFallback: 'Erreur de reinitialisation',
      );

      _setLoading(false);
      return result;
    } catch (e) {
      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<AuthActionResult> _postPasswordNoAuth({
    required String endpoint,
    required Map<String, dynamic> payload,
    required String successFallback,
    required String errorFallback,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    final response = await http
        .post(
          url,
          headers: await _getPublicHeaders(), // âœ… ALWAYS NO AUTH
          body: json.encode(payload),
        )
        .timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
          onTimeout: () => throw Exception('Delai de connexion depasse'),
        );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthActionResult(
        success: true,
        message: _extractResponseMessage(response, fallback: successFallback),
        statusCode: response.statusCode,
      );
    }

    final message = _extractResponseMessage(response, fallback: errorFallback);

    if (response.statusCode == 403) {
      // ignore: avoid_print
      print(
        'PASSWORD 403 endpoint=$endpoint payload=$payload body=${response.body}',
      );
      return AuthActionResult(
        success: false,
        message:
            '$message (403 - acces refuse par le serveur. Verifiez email et code)',
        statusCode: response.statusCode,
      );
    }

    return AuthActionResult(
      success: false,
      message: message,
      statusCode: response.statusCode,
    );
  }

  String _extractResponseMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded.trim();
      }
    } catch (_) {
      final raw = response.body.trim();
      if (raw.isNotEmpty && !raw.startsWith('<!DOCTYPE')) {
        return raw;
      }
    }

    return fallback;
  }

  /// âœ… Public headers: NO Authorization here, ever.
  Future<Map<String, String>> _getPublicHeaders() async {
    return <String, String>{
      'Content-Type': ApiConfig.contentType,
      'Accept': 'application/json',
    };
  }

  Map<String, String> _getAuthHeaders() {
    return {
      'Content-Type': ApiConfig.contentType,
      'Accept': 'application/json',
      ApiConfig.authHeader: '${ApiConfig.bearerPrefix}$_token',
    };
  }

  String _formatExceptionMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final normalized = message.toLowerCase();

    if (normalized.contains('failed to fetch') ||
        normalized.contains('xmlhttprequest error')) {
      return 'Impossible de joindre le serveur (${ApiConfig.baseUrl}). '
          'Verifiez que le backend est demarre et que l\'URL API est correcte.';
    }

    if (normalized.contains('connection refused')) {
      return 'Connexion refusee par le serveur (${ApiConfig.baseUrl}). '
          'Verifiez que le backend ecoute bien sur ce port.';
    }

    return message;
  }

  Future<void> _saveUserData(bool remember) async {
    if (_token == null) return;

    final prefs = await SharedPreferences.getInstance();
    // Token must always be persisted because ClientService reads it from prefs
    // for authenticated API calls.
    await prefs.setString('token', _token!);

    if (remember && _currentUser != null) {
      await prefs.setString('user', json.encode(_currentUser!.toJson()));
    } else {
      await prefs.remove('user');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
