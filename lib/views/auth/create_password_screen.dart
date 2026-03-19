import 'package:flutter/material.dart';

import '../../config/app_routes.dart';
import '../../core/ui/adaptive_layout.dart';
import '../../services/auth_service.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, this.initialEmail, this.initialCode});

  final String? initialEmail;
  final String? initialCode;

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _feedbackMessage;
  bool _isError = false;

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

  void _onPasswordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _feedbackMessage = result.message;
      _isError = !result.success;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte active avec succes.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  bool _hasMinLength(String password) => password.length >= 8;
  bool _hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  bool _hasDigit(String password) => RegExp(r'\d').hasMatch(password);
  bool _hasSpecialCharacter(String password) {
    const specialCharacters = r'''!@#$%^&*()_-+=[]{};:'",.<>/?\|`~''';
    return password.split('').any(specialCharacters.contains);
  }

  Color _ruleColor(bool ok) {
    return ok
        ? const Color.fromARGB(255, 146, 255, 191)
        : Colors.white.withValues(alpha: 0.72);
  }

  Widget _buildPasswordRules() {
    final password = _passwordController.text;
    final rules = <Map<String, dynamic>>[
      {'ok': _hasMinLength(password), 'label': 'Au moins 8 caracteres'},
      {'ok': _hasUppercase(password), 'label': 'Au moins 1 lettre majuscule'},
      {'ok': _hasDigit(password), 'label': 'Au moins 1 chiffre'},
      {
        'ok': _hasSpecialCharacter(password),
        'label': 'Au moins 1 caractere special',
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Le mot de passe doit contenir :',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          for (final rule in rules) ...[
            Row(
              children: [
                Icon(
                  rule['ok'] == true
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  size: 15,
                  color: _ruleColor(rule['ok'] == true),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rule['label'] as String,
                    style: TextStyle(color: _ruleColor(rule['ok'] == true)),
                  ),
                ),
              ],
            ),
            if (rule != rules.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isVeryCompact = screenWidth < 370;
    final cardWidth = AdaptiveLayout.cardWidth(
      context,
      max: 450,
      sideMargin: isVeryCompact ? 12 : 20,
    );
    final cardPadding = isVeryCompact ? 20.0 : 28.0;
    final titleSize = isVeryCompact ? 22.0 : 26.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 45, 71, 200),
              Color.fromARGB(255, 36, 55, 170),
              Color.fromARGB(255, 28, 44, 150),
              Color.fromARGB(255, 18, 30, 120),
              Color.fromARGB(255, 9, 15, 87),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryCompact ? 12 : 20,
                    vertical: 20,
                  ),
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Activer votre compte',
                              style: TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saisissez votre email, le code recu par email, puis choisissez un mot de passe securise.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Text(
                                'Le code d activation est valable 24 heures.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildLabel('Email'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefix: Icons.email_outlined,
                              hintText: 'exemple@email.com',
                              validator: (value) {
                                final email = (value ?? '').trim();
                                if (email.isEmpty) return 'Email requis';
                                final emailRegex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );
                                if (!emailRegex.hasMatch(email)) {
                                  return 'Email invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Code d activation'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _codeController,
                              keyboardType: TextInputType.number,
                              prefix: Icons.verified_user_outlined,
                              hintText: '123456',
                              validator: (value) {
                                final code = (value ?? '').replaceAll(
                                  RegExp(r'\s+'),
                                  '',
                                );
                                if (code.isEmpty) return 'Code requis';
                                if (!RegExp(r'^\d{6}$').hasMatch(code)) {
                                  return 'Le code doit contenir 6 chiffres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            _buildLabel('Nouveau mot de passe'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              prefix: Icons.lock_outline,
                              hintText: '••••••••',
                              suffix: IconButton(
                                onPressed: () => setState(() {
                                  _obscurePassword = !_obscurePassword;
                                }),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) {
                                  return 'Mot de passe requis';
                                }
                                if (!_hasMinLength(password)) {
                                  return 'Minimum 8 caracteres';
                                }
                                if (!_hasUppercase(password)) {
                                  return 'Ajoutez 1 majuscule';
                                }
                                if (!_hasDigit(password)) {
                                  return 'Ajoutez 1 chiffre';
                                }
                                if (!_hasSpecialCharacter(password)) {
                                  return 'Ajoutez 1 caractere special';
                                }
                                return null;
                              },
                            ),
                            _buildPasswordRules(),
                            const SizedBox(height: 14),
                            _buildLabel('Confirmer le mot de passe'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              prefix: Icons.lock_reset_outlined,
                              hintText: '••••••••',
                              suffix: IconButton(
                                onPressed: () => setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                }),
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
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
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 7, 58, 31),
                                    Color.fromARGB(255, 12, 174, 74),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(23),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Activer mon compte',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.login,
                                        (route) => false,
                                      ),
                                child: const Text(
                                  'Retour a la connexion',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 42, 230, 189),
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _feedbackMessage == null
                                  ? const SizedBox.shrink()
                                  : Container(
                                      key: ValueKey<String>(_feedbackMessage!),
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            (_isError
                                                    ? Colors.red
                                                    : const Color.fromARGB(
                                                        255,
                                                        12,
                                                        174,
                                                        74,
                                                      ))
                                                .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              (_isError
                                                      ? Colors.red
                                                      : const Color.fromARGB(
                                                          255,
                                                          42,
                                                          230,
                                                          189,
                                                        ))
                                                  .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        _feedbackMessage!,
                                        style: TextStyle(
                                          color: _isError
                                              ? Colors.red[200]
                                              : Colors.greenAccent[100],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(prefix, color: const Color.fromARGB(255, 12, 174, 74)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 42, 230, 189),
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
