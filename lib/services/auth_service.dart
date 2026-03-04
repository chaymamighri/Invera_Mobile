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

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;

  AuthService() {
    _loadStoredData();
  }

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

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
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
        final loginResponse = LoginResponse.fromJson(json.decode(response.body));

        _token = loginResponse.token;
        _currentUser = User(
          id: loginResponse.id,
          email: loginResponse.email,
          nom: loginResponse.nom,
          prenom: loginResponse.prenom,
          role: UserRole.values.firstWhere(
            (r) => r.name == loginResponse.role,
            orElse: () => UserRole.COMMERCIAL,
          ),
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
      _error = e.toString().replaceFirst('Exception: ', '');
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

  /// ✅ FIXED:
  /// - First attempt: POST with JSON body { email: ... } (most common Spring)
  /// - Fallback attempt: POST with query param (your old behavior)
  /// - NEVER sends Authorization header
  Future<AuthActionResult> forgotPassword(String email) async {
    _setLoading(true);

    try {
      final normalizedEmail = email.trim().toLowerCase();

      // Attempt 1 (recommended): JSON body
      final url1 = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}');
      final res1 = await http
          .post(
            url1,
            headers: await _getPublicHeaders(), // NO AUTH
            body: json.encode({'email': normalizedEmail}),
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      if (res1.statusCode >= 200 && res1.statusCode < 300) {
        _setLoading(false);
        return AuthActionResult(
          success: true,
          message: _extractResponseMessage(res1, fallback: 'Code de reinitialisation envoye'),
          statusCode: res1.statusCode,
        );
      }

      // Attempt 2 (fallback): query param, no body
      final url2 = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}')
          .replace(queryParameters: {'email': normalizedEmail});

      final res2 = await http
          .post(
            url2,
            headers: await _getPublicHeaders(), // NO AUTH
          )
          .timeout(
            const Duration(milliseconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw Exception('Delai de connexion depasse'),
          );

      _setLoading(false);

      if (res2.statusCode >= 200 && res2.statusCode < 300) {
        return AuthActionResult(
          success: true,
          message: _extractResponseMessage(res2, fallback: 'Code de reinitialisation envoye'),
          statusCode: res2.statusCode,
        );
      }

      final message = _extractResponseMessage(
        res2,
        fallback: 'Erreur lors de l\'envoi de l\'email',
      );

      if (res2.statusCode == 403) {
        // ignore: avoid_print
        print('FORGOT 403 body: ${res2.body}');
        return AuthActionResult(
          success: false,
          message: '$message (403 - acces refuse par le serveur)',
          statusCode: res2.statusCode,
        );
      }

      return AuthActionResult(
        success: false,
        message: message,
        statusCode: res2.statusCode,
      );
    } catch (e) {
      _setLoading(false);
      return AuthActionResult(
        success: false,
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// ✅ FIXED:
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

      // Payload variants (some backends use different keys)
      final payloads = <Map<String, dynamic>>[
        {
          'email': normalizedEmail,
          'code': cleanedCode,
          'newPassword': newPassword,
        },
        {
          // common variant
          'email': normalizedEmail,
          'verificationCode': cleanedCode,
          'newPassword': newPassword,
        },
        {
          // another common variant
          'email': normalizedEmail,
          'code': cleanedCode,
          'password': newPassword,
        },
      ];

      // Endpoints to try (you already have both)
      final endpoints = <_EndpointAttempt>[
        _EndpointAttempt(
          endpoint: ApiConfig.resetPasswordEndpoint,
          successFallback: 'Mot de passe modifie avec succes',
          errorFallback: 'Erreur de reinitialisation',
        ),
        _EndpointAttempt(
          endpoint: ApiConfig.createPasswordEndpoint,
          successFallback: 'Compte active et mot de passe cree avec succes',
          errorFallback: 'Erreur de creation de mot de passe',
        ),
      ];

      AuthActionResult lastResult = const AuthActionResult(
        success: false,
        message: 'Erreur de reinitialisation',
      );

      for (final ep in endpoints) {
        for (final payload in payloads) {
          final result = await _postPasswordNoAuth(
            endpoint: ep.endpoint,
            payload: payload,
            successFallback: ep.successFallback,
            errorFallback: ep.errorFallback,
          );

          if (result.success) {
            _setLoading(false);
            return result;
          }

          lastResult = result;
        }
      }

      _setLoading(false);
      return lastResult;
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
          headers: await _getPublicHeaders(), // ✅ ALWAYS NO AUTH
          body: json.encode(payload),
        )
        .timeout(
          const Duration(milliseconds: ApiConfig.connectionTimeout),
          onTimeout: () => throw Exception('Delai de connexion depasse'),
        );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthActionResult(
        success: true,
        message: _extractResponseMessage(
          response,
          fallback: successFallback,
        ),
        statusCode: response.statusCode,
      );
    }

    final message = _extractResponseMessage(response, fallback: errorFallback);

    if (response.statusCode == 403) {
      // ignore: avoid_print
      print('PASSWORD 403 endpoint=$endpoint payload=$payload body=${response.body}');
      return AuthActionResult(
        success: false,
        message:
            '$message (403 - acces refuse par le serveur. Verifiez email/code et activation du compte)',
        statusCode: response.statusCode,
      );
    }

    return AuthActionResult(
      success: false,
      message: message,
      statusCode: response.statusCode,
    );
  }

  String _extractResponseMessage(http.Response response, {required String fallback}) {
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

  /// ✅ Public headers: NO Authorization here, ever.
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

class _EndpointAttempt {
  final String endpoint;
  final String successFallback;
  final String errorFallback;

  _EndpointAttempt({
    required this.endpoint,
    required this.successFallback,
    required this.errorFallback,
  });
}
