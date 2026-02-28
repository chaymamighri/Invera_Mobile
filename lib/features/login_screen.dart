import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../achat/achat_home.dart';
import '../commercial/commerciale.dart';
import 'data/auth_api.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _tokenStorage = TokenStorage();
  late final Dio _dio;
  late final AuthApi _authApi;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dio = buildDio();
    _authApi = AuthApi(_dio);
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;

      // backend sends MessageResponse sometimes
      final msg = e.response?.data is Map<String, dynamic> ? e.response?.data['message'] : null;

      if (status == 403) return msg ?? "Compte désactivé. Contactez l’administrateur.";
      if (status == 401) return "Email ou mot de passe incorrect.";
      if (status == 400) return msg ?? "Requête invalide.";
      if (status != null) return msg ?? "Erreur serveur ($status).";
      return "Erreur réseau. Vérifiez votre connexion / URL backend.";
    }
    return "Erreur inattendue.";
  }

  Future<void> _handleLogin() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Veuillez saisir email et mot de passe.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final jwtRes = await _authApi.login(email: email, password: password);

      if (jwtRes.token.isEmpty) {
        setState(() => _error = "Token manquant dans la réponse.");
        return;
      }

      await _tokenStorage.saveToken(jwtRes.token);

      final fullName = "${jwtRes.nom} ${jwtRes.prenom}".trim();

      if (!mounted) return;

      // Redirect by role
      if (jwtRes.role.toUpperCase() == "COMMERCIAL") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => commercial(fullName: fullName.isEmpty ? jwtRes.email : fullName)),
        );
      } else if (jwtRes.role.toUpperCase() == "RESPONSABLE_ACHAT") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AchatHome(fullName: fullName.isEmpty ? jwtRes.email : fullName)),
        );
      } else {
        setState(() => _error = "Rôle non supporté: ${jwtRes.role}");
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  "Invera Mobile",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Connectez-vous pour continuer",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),

                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 14),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.25)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Se connecter"),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  "Backend: ${_dio.options.baseUrl}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}