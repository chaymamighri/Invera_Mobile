import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import 'auth_shell.dart';

/// Widget qui affiche l'ecran de connexion.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour l'ecran de connexion.
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  String? _errorMessage;
  List<String> _validationAlerts = const [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final validationAlerts = _collectValidationAlerts();

    setState(() {
      _submitted = true;
      _emailTouched = true;
      _passwordTouched = true;
      _errorMessage = null;
      _validationAlerts = validationAlerts;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
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

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (!_submitted && (!_emailTouched || _emailFocused)) {
      return null;
    }

    if (email.isEmpty) {
      return 'Email requis';
    }

    if (!email.contains('@')) {
      return 'Ajoutez @ dans votre email';
    }

    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return 'Email incomplet';
    }

    if (!parts[1].contains('.')) {
      return 'Ajoutez le domaine, exemple: gmail.com';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Format email invalide';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (!_submitted && (!_passwordTouched || _passwordFocused)) {
      return null;
    }

    if (password.isEmpty) {
      return 'Mot de passe requis';
    }

    if (password.length < 8) {
      return 'Minimum 8 caracteres';
    }

    return null;
  }

  List<String> _collectValidationAlerts() {
    final alerts = <String>[];
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      alerts.add('Email requis');
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      alerts.add('Veuillez saisir un email valide, exemple@domaine.com');
    }

    if (password.isEmpty) {
      alerts.add('Mot de passe requis');
    } else if (password.length < 8) {
      alerts.add('Le mot de passe doit contenir au moins 8 caracteres');
    }

    return alerts;
  }

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
            if (_validationAlerts.isNotEmpty) ...[
              AuthBanner(
                title: 'Verifiez vos identifiants',
                message: _validationAlerts
                    .map((alert) => '- $alert')
                    .join('\n'),
                tone: AuthBannerTone.warning,
              ),
              const SizedBox(height: 18),
            ],
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _emailFocused = hasFocus;
                  if (!hasFocus) {
                    _emailTouched = true;
                  }
                });

                if (!hasFocus) {
                  _formKey.currentState?.validate();
                }
              },
              child: AuthTextField(
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
            ),
            const SizedBox(height: 18),
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _passwordFocused = hasFocus;
                  if (!hasFocus) {
                    _passwordTouched = true;
                  }
                });

                if (!hasFocus) {
                  _formKey.currentState?.validate();
                }
              },
              child: AuthTextField(
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
                validator: _validatePassword,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                          arguments: {
                            'email': _emailController.text.trim().toLowerCase(),
                          },
                        );
                      },
                style: linkStyle,
                child: const Text('Mot de passe oublie ?'),
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
