import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'auth_shell.dart';

/// Widget qui affiche l'ecran de connexion.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour l'ecran de connexion.
class _LoginScreenState extends State<LoginScreen> {
  // Configuration, dependances et etat local de l'interface.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Cycle de vie du widget.

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Actions utilisateur et traitements asynchrones.

  /// Gere la connexion.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bienvenue ${_authService.currentUser?.fullName ?? ''}'.trim(),
          ),
          backgroundColor: AuthPalette.success,
        ),
      );

      final userRole = _authService.currentUser?.role;

      switch (userRole) {
        case UserRole.COMMERCIAL:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.commercialDashboard,
            arguments: {'user': _authService.currentUser},
          );
          break;
        case UserRole.RESPONSABLE_VENTE:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.responsableVenteDashboard,
            arguments: {'user': _authService.currentUser},
          );
          break;
        case UserRole.RESPONSABLE_ACHAT:
        case UserRole.ADMIN:
        default:
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.approvisionnementDashboard,
            arguments: {'user': _authService.currentUser},
          );
      }
      return;
    }

    setState(() {
      _errorMessage = _authService.error ?? 'Email ou mot de passe incorrect';
    });
  }

  // Valeurs calculees et methodes utilitaires.

  /// Valide l'adresse e-mail.
  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Email requis';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Email invalide';
    }

    return null;
  }

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      foregroundColor: AuthPalette.primaryDark,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    );

    return AuthScaffold(
      showBackButton: false,
      eyebrow: 'InVera ERP',
      title: 'Connexion',
      subtitle: 'Entrez vos identifiants pour acceder a votre espace.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthTextField(
              label: 'Email',
              controller: _emailController,
              hintText: 'exemple@invera.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: _validateEmail,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 18),
            AuthTextField(
              label: 'Mot de passe',
              controller: _passwordController,
              hintText: 'Entrez votre mot de passe',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enableSuggestions: false,
              autocorrect: false,
              onFieldSubmitted: (_) => _handleLogin(),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AuthPalette.muted,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Mot de passe requis';
                }
                if ((value ?? '').length < 6) {
                  return 'Minimum 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.createPassword,
                              arguments: {
                                'email': _emailController.text
                                    .trim()
                                    .toLowerCase(),
                              },
                            );
                          },
                    style: linkStyle,
                    child: const Text('Activer mon compte'),
                  ),
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.forgotPassword,
                              arguments: {
                                'email': _emailController.text
                                    .trim()
                                    .toLowerCase(),
                              },
                            );
                          },
                    style: linkStyle,
                    child: const Text('Mot de passe oublie ?'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              label: 'Se connecter',
              onPressed: _isLoading ? null : _handleLogin,
              isLoading: _isLoading,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AuthBanner(
                title: 'Connexion impossible',
                message: _errorMessage!,
                tone: AuthBannerTone.error,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
