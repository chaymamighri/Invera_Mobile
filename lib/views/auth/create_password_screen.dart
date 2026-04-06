import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_routes.dart';
import '../../services/auth_service.dart';
import 'auth_shell.dart';

/// Widget qui affiche create mot de passe ecran.
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, this.initialEmail, this.initialCode});

  // Configuration, dependances et etat local de l'interface.
  final String? initialEmail;
  final String? initialCode;

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour create mot de passe ecran.
class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  // Configuration, dependances et etat local de l'interface.
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _feedbackMessage;
  bool _isError = false;

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: (widget.initialEmail ?? '').trim().toLowerCase(),
    );
    _codeController = TextEditingController(
      text: (widget.initialCode ?? '').replaceAll(RegExp(r'\s+'), ''),
    );
    _passwordController.addListener(_onPasswordChanged);
  }

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Actions utilisateur et traitements asynchrones.

  /// Reagit lorsque le mot de passe change.
  void _onPasswordChanged() {
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

    final result = await _authService.createPassword(
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
          content: Text('Compte active avec succes.'),
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

  /// Verifie si la valeur a une longueur minimale.
  bool _hasMinLength(String password) => password.length >= 8;

  /// Verifie si la valeur contient une majuscule.
  bool _hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);

  /// Verifie si la valeur contient un chiffre.
  bool _hasDigit(String password) => RegExp(r'\d').hasMatch(password);

  /// Verifie si la valeur contient un caractere special.
  bool _hasSpecialCharacter(String password) {
    const specialCharacters = r'''!@#$%^&*()_-+=[]{};:'",.<>/?\|`~''';
    return password.split('').any(specialCharacters.contains);
  }

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

    return AuthScaffold(
      eyebrow: 'Activation',
      title: 'Activer le compte',
      subtitle:
          'Entrez votre email, le code recu par email et votre nouveau mot de passe.',
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
              label: 'Code d activation',
              controller: _codeController,
              hintText: '123456',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                final code = (value ?? '').replaceAll(RegExp(r'\s+'), '');
                if (code.isEmpty) {
                  return 'Code requis';
                }
                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                  return 'Le code doit contenir 6 chiffres';
                }
                return null;
              },
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Nouveau mot de passe',
              controller: _passwordController,
              hintText: 'Creez un mot de passe',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
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
                final currentPassword = value ?? '';
                if (currentPassword.isEmpty) {
                  return 'Mot de passe requis';
                }
                if (!_hasMinLength(currentPassword)) {
                  return 'Minimum 8 caracteres';
                }
                if (!_hasUppercase(currentPassword)) {
                  return 'Ajoutez 1 majuscule';
                }
                if (!_hasDigit(currentPassword)) {
                  return 'Ajoutez 1 chiffre';
                }
                if (!_hasSpecialCharacter(currentPassword)) {
                  return 'Ajoutez 1 caractere special';
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
                  label: 'Au moins 8 caracteres',
                  isSatisfied: _hasMinLength(password),
                ),
                AuthRule(
                  label: 'Au moins 1 lettre majuscule',
                  isSatisfied: _hasUppercase(password),
                ),
                AuthRule(
                  label: 'Au moins 1 chiffre',
                  isSatisfied: _hasDigit(password),
                ),
                AuthRule(
                  label: 'Au moins 1 caractere special',
                  isSatisfied: _hasSpecialCharacter(password),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AuthTextField(
              label: 'Confirmer le mot de passe',
              controller: _confirmPasswordController,
              hintText: 'Retapez le mot de passe',
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
              label: 'Activer mon compte',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AuthPalette.primaryDark,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                child: const Text('Retour a la connexion'),
              ),
            ),
            if (_feedbackMessage != null) ...[
              const SizedBox(height: 16),
              AuthBanner(
                title: _isError
                    ? 'Activation impossible'
                    : 'Activation terminee',
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
