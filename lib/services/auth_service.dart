import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _currentUser != null;
  
  // 👇 SUPPRIMÉ - getter isAdmin supprimé car pas de rôle ADMIN

  AuthService() {
    _loadStoredData();
  }

  // Charger les données stockées
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
      print('Erreur chargement données: $e');
    }
  }

  // Connexion
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
      
      final request = LoginRequest(email: email, password: password);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': ApiConfig.contentType,
        },
        body: json.encode(request.toJson()),
      ).timeout(
        const Duration(milliseconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw Exception('Délai de connexion dépassé'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      } else {
        try {
          final errorResponse = json.decode(response.body);
          _error = errorResponse['message'] ?? 'Erreur de connexion';
        } catch (_) {
          _error = 'Erreur de connexion (${response.statusCode})';
        }
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('Exception login: $e');
      _error = 'Impossible de se connecter au serveur';
      _setLoading(false);
      return false;
    }
  }

  // Récupérer les infos de l'utilisateur connecté
  Future<bool> fetchCurrentUser() async {
    if (_token == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meEndpoint}');
      
      final response = await http.get(
        url,
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(json.decode(response.body));
        await _saveUserData(true);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur fetch user: $e');
      return false;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _error = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    
    notifyListeners();
  }

  // Mot de passe oublié
  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.forgotPasswordEndpoint}?email=$email'
      );
      
      final response = await http.post(url).timeout(
        const Duration(milliseconds: ApiConfig.connectionTimeout),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        final message = MessageResponse.fromJson(json.decode(response.body));
        return message.message;
      } else {
        return 'Erreur lors de l\'envoi de l\'email';
      }
    } catch (e) {
      _setLoading(false);
      return 'Erreur de connexion';
    }
  }

  // Réinitialisation mot de passe
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _setLoading(true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.resetPasswordEndpoint}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': ApiConfig.contentType},
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      _setLoading(false);

      if (response.statusCode == 200) {
        final message = MessageResponse.fromJson(json.decode(response.body));
        return message.message;
      } else {
        try {
          final error = json.decode(response.body);
          return error['message'] ?? 'Erreur de réinitialisation';
        } catch (_) {
          return 'Erreur de réinitialisation';
        }
      }
    } catch (e) {
      _setLoading(false);
      return 'Erreur de connexion';
    }
  }

  // Headers avec token
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': ApiConfig.contentType,
      ApiConfig.authHeader: '${ApiConfig.bearerPrefix}$_token',
    };
  }

  // Sauvegarder les données utilisateur
  Future<void> _saveUserData(bool remember) async {
    if (!remember) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', json.encode(_currentUser!.toJson()));
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