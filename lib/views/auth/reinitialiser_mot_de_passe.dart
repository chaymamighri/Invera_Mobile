import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../services/authentification.dart';
import 'structure.dart';

/// Widget qui affiche l'ecran de reinitialisation du mot de passe.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  // Configuration, dependances et etat local de l'interface.
  final String email;

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour l'ecran de reinitialisation du mot de passe.
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Configuration, dependances et etat local de l'interface.
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _feedbackMessage;
  bool _isError = false;

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.email.trim().toLowerCase(),
    );
    _passwordController.addListener(_onPasswordChange);
  }

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChange);
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Actions utilisateur et traitements asynchrones.

  /// Reagit lorsque le mot de passe change.
  void _onPasswordChange() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Soumet les donnees actuelles du formulaire.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
      _isError = false;
    });

    final result = await _authService.resetPassword(
      email: _emailController.text.trim().toLowerCase(),
      code: _codeController.text.replaceAll(RegExp(r'\s+'), ''),
      newPassword: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _feedbackMessage = result.message;
      _isError = !result.success;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifie avec succes.'),
          backgroundColor: AuthPalette.success,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
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
    final password = _passwordController.text;
    final hasSixChars = password.length >= 6;
    final hasNumber = RegExp(r'\d').hasMatch(password);

    return AuthScaffold(
      eyebrow: 'Reinitialisation',
      title: 'Reinitialiser le mot de passe',
      subtitle:
          'Entrez le code recu par email puis definissez un nouveau mot de passe.',
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
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Code de verification',
              controller: _codeController,
              hintText: 'Collez le code recu par email',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Code requis';
                }
                return null;
              },
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Nouveau mot de passe',
              controller: _passwordController,
              hintText: 'Creez un nouveau mot de passe',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureNewPassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AuthPalette.muted,
                ),
              ),
              validator: (value) {
                final currentPassword = value ?? '';
                if (currentPassword.isEmpty) {
                  return 'Mot de passe requis';
                }
                if (currentPassword.length < 6) {
                  return 'Minimum 6 caracteres';
                }
                if (!RegExp(r'\d').hasMatch(currentPassword)) {
                  return 'Ajoutez au moins 1 chiffre';
                }
                return null;
              },
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 14),
            AuthRuleChecklist(
              title: 'Votre mot de passe doit contenir :',
              rules: [
                AuthRule(
                  label: 'Au moins 6 caracteres',
                  isSatisfied: hasSixChars,
                ),
                AuthRule(label: 'Au moins 1 chiffre', isSatisfied: hasNumber),
              ],
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Confirmer le mot de passe',
              controller: _confirmPasswordController,
              hintText: 'Retapez le nouveau mot de passe',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AuthPalette.muted,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'Confirmation requise';
                }
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: 'Reinitialiser',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.forgotPassword,
                          arguments: {
                            'email': _emailController.text.trim().toLowerCase(),
                          },
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.primaryDark,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Renvoyer le code'),
              ),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 16),
              AuthBanner(
                title: _isError
                    ? 'Reinitialisation impossible'
                    : 'Mot de passe mis a jour',
                message: _feedbackMessage!,
                tone: _isError ? AuthBannerTone.error : AuthBannerTone.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
