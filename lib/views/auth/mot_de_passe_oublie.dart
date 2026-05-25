import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../services/authentification.dart';
import 'structure.dart';

/// Widget qui affiche l'ecran de recuperation du mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  // Configuration, dependances et etat local de l'interface.
  final String? initialEmail;

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour l'ecran de recuperation du mot de passe.
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Configuration, dependances et etat local de l'interface.
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  String? _feedbackMessage;
  bool _isError = false;

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Actions utilisateur et traitements asynchrones.

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

    final result = await _authService.forgotPassword(
      _emailController.text.trim().toLowerCase(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _feedbackMessage = result.message;
      _isError = !result.success;
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
    return AuthScaffold(
      eyebrow: 'Recuperation',
      title: 'Mot de passe oublie',
      subtitle: 'Saisissez votre email pour recevoir un code de verification.',
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
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: widget.initialEmail == null,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              label: 'Envoyer le code',
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
                title: _isError ? 'Envoi impossible' : 'Code envoye',
                message: _feedbackMessage!,
                tone: _isError ? AuthBannerTone.error : AuthBannerTone.success,
                action: _isError
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.resetPassword,
                              arguments: {
                                'email': _emailController.text
                                    .trim()
                                    .toLowerCase(),
                              },
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AuthPalette.primaryDark,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text(
                            'Continuer vers la reinitialisation',
                          ),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
