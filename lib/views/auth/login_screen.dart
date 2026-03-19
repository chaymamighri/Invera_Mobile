// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../config/app_routes.dart';
import '../../core/ui/adaptive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bienvenue ${_authService.currentUser?.fullName ?? ''}',
            ),
            backgroundColor: const Color.fromARGB(255, 12, 174, 74),
          ),
        );

        // Redirection basée sur le rôle
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
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.approvisionnementDashboard,
              arguments: {'user': _authService.currentUser},
            );
            break;

          case UserRole.ADMIN:
            // Gérer le cas ADMIN si nécessaire
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.approvisionnementDashboard,
              arguments: {'user': _authService.currentUser},
            );
            break;

          default:
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.approvisionnementDashboard,
              arguments: {'user': _authService.currentUser},
            );
        }
      } else {
        setState(() {
          _errorMessage =
              _authService.error ?? 'Email ou mot de passe incorrect';
        });
      }
    }
  }

  // ✅ LA MÉTHODE build() DOIT ÊTRE PRÉSENTE
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isVeryCompact = screenWidth < 370;
    final cardWidth = AdaptiveLayout.cardWidth(
      context,
      max: 420,
      sideMargin: isVeryCompact ? 12 : 20,
    );
    final cardPadding = isVeryCompact ? 20.0 : 30.0;
    final titleSize = isVeryCompact ? 26.0 : 30.0;

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
              // Flèche de retour
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),

              // Contenu centré
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVeryCompact ? 12 : 20,
                    vertical: 20,
                  ),
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Titre
                              Center(
                                child: Text(
                                  'Connexion',
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 12, 174, 74),
                                        Color.fromARGB(255, 42, 230, 189),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 25),

                              // Email
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'exemple@email.com',
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                        color: Color.fromARGB(255, 12, 174, 74),
                                        size: 20,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            42,
                                            230,
                                            189,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.08),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Email requis';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Email invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Mot de passe
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mot de passe',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: Color.fromARGB(255, 12, 174, 74),
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.15),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                            255,
                                            42,
                                            230,
                                            189,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.08),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Mot de passe requis';
                                      }
                                      if (value.length < 6) {
                                        return 'Minimum 6 caractères';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              // Options
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compactOptions =
                                      constraints.maxWidth < 340;

                                  final rememberMe = Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(
                                            () => _rememberMe = value ?? false,
                                          );
                                        },
                                        activeColor: const Color.fromARGB(
                                          255,
                                          12,
                                          174,
                                          74,
                                        ),
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const Flexible(
                                        child: Text(
                                          'Se souvenir de moi',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );

                                  final forgotButton = TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgotPassword,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color.fromARGB(
                                          255,
                                          42,
                                          230,
                                          189,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );

                                  final activationButton = TextButton(
                                    onPressed: () {
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
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Activer mon compte',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color.fromARGB(
                                          255,
                                          42,
                                          230,
                                          189,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );

                                  if (compactOptions) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        rememberMe,
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: activationButton,
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: forgotButton,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: rememberMe),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          activationButton,
                                          const SizedBox(width: 12),
                                          forgotButton,
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Bouton de connexion
                              Container(
                                width: double.infinity,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 7, 58, 31),
                                      Color.fromARGB(255, 12, 174, 74),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(
                                        255,
                                        42,
                                        230,
                                        189,
                                      ).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Se connecter',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              // Message d'erreur
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[300],
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red[300],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
