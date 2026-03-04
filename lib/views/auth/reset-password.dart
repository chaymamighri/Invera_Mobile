import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _feedbackMessage;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email.trim().toLowerCase());
    _passwordController.addListener(_onPasswordChange);
  }

  void _onPasswordChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _feedbackMessage = null;
      _isError = false;
    });

    final result = await _authService.resetPassword(
      email: _emailController.text.trim().toLowerCase(),
      code: _codeController.text.replaceAll(RegExp(r'\s+'), ''), // ✅ remove spaces/newlines
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
        const SnackBar(content: Text('Mot de passe modifié avec succès.')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  Color _ruleColor(bool ok) {
    return ok
        ? const Color.fromARGB(255, 146, 255, 191)
        : Colors.white.withValues(alpha: 0.7);
  }

  Widget _passwordRules() {
    final password = _passwordController.text;
    final has6Chars = password.length >= 6;
    final hasNumber = RegExp(r'\d').hasMatch(password); // ✅ correct

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
            'Le mot de passe doit contenir:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                has6Chars ? Icons.check_circle : Icons.circle_outlined,
                size: 15,
                color: _ruleColor(has6Chars),
              ),
              const SizedBox(width: 8),
              Text('Au moins 6 caractères', style: TextStyle(color: _ruleColor(has6Chars))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                hasNumber ? Icons.check_circle : Icons.circle_outlined,
                size: 15,
                color: _ruleColor(hasNumber),
              ),
              const SizedBox(width: 8),
              Text('Au moins 1 chiffre', style: TextStyle(color: _ruleColor(hasNumber))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: 430,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Réinitialiser le mot de passe',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entrez le code reçu par email, puis choisissez un nouveau mot de passe.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.35,
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
                                final emailRegex =
                                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$'); // ✅ correct
                                if (!emailRegex.hasMatch(email)) return 'Email invalide';
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),
                            _buildLabel('Code de vérification'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _codeController,
                              keyboardType: TextInputType.text,
                              prefix: Icons.verified_outlined,
                              hintText: 'Collez le code reçu par email',
                              validator: (value) {
                                final code = (value ?? '').trim();
                                if (code.isEmpty) return 'Code requis';
                                return null;
                              },
                            ),

                            const SizedBox(height: 14),
                            _buildLabel('Nouveau mot de passe'),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _passwordController,
                              obscureText: _obscureNewPassword,
                              prefix: Icons.lock_outline,
                              hintText: '••••••••',
                              suffix: IconButton(
                                onPressed: () => setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                }),
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                              validator: (value) {
                                final password = value ?? '';
                                if (password.isEmpty) return 'Mot de passe requis';
                                if (password.length < 6) return 'Minimum 6 caractères';
                                if (!RegExp(r'\d').hasMatch(password)) return 'Ajoutez au moins 1 chiffre'; // ✅ correct
                                return null;
                              },
                            ),

                            _passwordRules(),

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
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                }),
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').isEmpty) return 'Confirmation requise';
                                if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
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
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Réinitialiser',
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
                                    : () => Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.forgotPassword,
                                          arguments: {'email': _emailController.text.trim().toLowerCase()},
                                        ),
                                child: const Text(
                                  'Renvoyer le code',
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
                                        color: (_isError ? Colors.red : const Color.fromARGB(255, 12, 174, 74))
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (_isError ? Colors.red : const Color.fromARGB(255, 42, 230, 189))
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        _feedbackMessage!,
                                        style: TextStyle(
                                          color: _isError ? Colors.red[200] : Colors.greenAccent[100],
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
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
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
    _passwordController.removeListener(_onPasswordChange);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}