import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/mise_en_page.dart';

/// Palette de couleurs partagee utilisee par l'interface d'authentification.
class AuthPalette {
  const AuthPalette._();

  // Configuration, dependances et etat local de l'interface.
  static const Color primary = Color(0xFF0B4EA2);
  static const Color primaryDark = Color(0xFF0B3D82);
  static const Color accent = Color(0xFF1D75D6);
  static const Color ink = Color(0xFF1F2937);
  static const Color muted = Color(0xFF64748B);
  static const Color sidebarStart = Color(0xFF0B2F6B);
  static const Color sidebarEnd = Color(0xFF1A5FC4);

  static const Color backgroundTop = Color(0xFFF0F4FA);
  static const Color backgroundMiddle = Color(0xFFF8FAFC);
  static const Color backgroundBottom = Color(0xFFEEF2F8);

  static const Color surface = Colors.white;
  static const Color surfaceSoft = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFE2E8F0);
  static const Color hint = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
  static const Color warning = Color(0xFFD97706);
}

/// Widget qui affiche la structure d'authentification.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
  });

  // Configuration, dependances et etat local de l'interface.
  final String? eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton && Navigator.of(context).canPop();
    final horizontalPadding = AdaptiveLayout.horizontalPadding(
      context,
      phone: 16,
      tablet: 24,
      desktop: 28,
    );
    final cardPadding = MediaQuery.sizeOf(context).width < 380 ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: AuthPalette.backgroundTop,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AuthPalette.backgroundTop,
                  AuthPalette.backgroundMiddle,
                  AuthPalette.backgroundBottom,
                ],
              ),
            ),
          ),
          const Positioned.fill(child: _AuthBackgroundDecor()),
          if (canGoBack)
            Positioned(
              top: 14,
              left: 14,
              child: SafeArea(
                child: _AuthBackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  canGoBack ? 76 : 24,
                  horizontalPadding,
                  24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AuthPalette.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x1F0F172A),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                eyebrow!,
                                style: const TextStyle(
                                  color: AuthPalette.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            title,
                            style: const TextStyle(
                              color: AuthPalette.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AuthPalette.muted,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          child,
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
    );
  }
}

/// Widget qui affiche le champ de texte d'authentification.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.readOnly = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  // Configuration, dependances et etat local de l'interface.
  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final bool enableSuggestions;
  final bool autocorrect;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AuthPalette.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          autofocus: autofocus,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          enableSuggestions: enableSuggestions,
          autocorrect: autocorrect,
          style: const TextStyle(
            color: AuthPalette.ink,
            fontWeight: FontWeight.w600,
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AuthPalette.hint),
            prefixIcon: Icon(icon, color: AuthPalette.hint, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AuthPalette.surfaceSoft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AuthPalette.border,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AuthPalette.primary,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AuthPalette.error,
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AuthPalette.error,
                width: 1.6,
              ),
            ),
            errorStyle: const TextStyle(height: 1.2),
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche le bouton principal d'authentification.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Configuration, dependances et etat local de l'interface.
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? const [Color(0xFF93A7C6), Color(0xFF93A7C6)]
                : const [AuthPalette.primaryDark, AuthPalette.accent],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330B4EA2),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

/// Valeurs possibles de tonalite de la banniere d'authentification utilisees dans ce fichier.
enum AuthBannerTone { info, success, warning, error }

/// Widget qui affiche la banniere d'authentification.
class AuthBanner extends StatelessWidget {
  const AuthBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = AuthBannerTone.info,
    this.action,
  });

  // Configuration, dependances et etat local de l'interface.
  final String message;
  final String? title;
  final AuthBannerTone tone;
  final Widget? action;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final Color accent = switch (tone) {
      AuthBannerTone.info => AuthPalette.info,
      AuthBannerTone.success => AuthPalette.success,
      AuthBannerTone.warning => AuthPalette.warning,
      AuthBannerTone.error => AuthPalette.error,
    };

    final Color background = switch (tone) {
      AuthBannerTone.warning => const Color(0xFFFFFBEB),
      AuthBannerTone.error => const Color(0xFFFEF2F2),
      AuthBannerTone.success => const Color(0xFFF0FDF4),
      AuthBannerTone.info => const Color(0xFFEFF6FF),
    };

    final IconData icon = switch (tone) {
      AuthBannerTone.info => Icons.info_outline_rounded,
      AuthBannerTone.success => Icons.check_circle_outline_rounded,
      AuthBannerTone.warning => Icons.warning_amber_rounded,
      AuthBannerTone.error => Icons.error_outline_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      message,
                      style: const TextStyle(
                        color: AuthPalette.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

/// Petit modele utilitaire qui stocke les donnees de la regle d'authentification.
class AuthRule {
  const AuthRule({required this.label, required this.isSatisfied});

  // Configuration, dependances et etat local de l'interface.
  final String label;
  final bool isSatisfied;
}

/// Widget qui affiche la liste de verification des regles d'authentification.
class AuthRuleChecklist extends StatelessWidget {
  const AuthRuleChecklist({
    super.key,
    required this.title,
    required this.rules,
  });

  // Configuration, dependances et etat local de l'interface.
  final String title;
  final List<AuthRule> rules;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AuthPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AuthPalette.ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < rules.length; index++) ...[
            _AuthRuleTile(rule: rules[index]),
            if (index != rules.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Widget qui affiche la tuile de regle d'authentification.
class _AuthRuleTile extends StatelessWidget {
  const _AuthRuleTile({required this.rule});

  // Configuration, dependances et etat local de l'interface.
  final AuthRule rule;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final iconColor = rule.isSatisfied
        ? AuthPalette.success
        : AuthPalette.muted;

    return Row(
      children: [
        Icon(
          rule.isSatisfied
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            rule.label,
            style: TextStyle(
              color: rule.isSatisfied ? AuthPalette.ink : AuthPalette.muted,
              fontWeight: rule.isSatisfied ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche le bouton retour d'authentification.
class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.onPressed});

  // Configuration, dependances et etat local de l'interface.
  final VoidCallback onPressed;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AuthPalette.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0x110F172A),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AuthPalette.ink,
        ),
      ),
    );
  }
}

/// Widget qui affiche le decor d'arriere-plan d'authentification.
class _AuthBackgroundDecor extends StatelessWidget {
  const _AuthBackgroundDecor();

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final smallScreen = size.width < 420;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -size.width * 0.28,
            right: -size.width * 0.18,
            child: _GlowOrb(
              size: math.max(220, size.width * 0.72),
              colors: [
                AuthPalette.primary.withValues(alpha: 0.05),
                AuthPalette.primary.withValues(alpha: 0.01),
              ],
            ),
          ),
          Positioned(
            top: size.height * 0.14,
            left: -110,
            child: Transform.rotate(
              angle: -0.48,
              child: Container(
                width: smallScreen ? 190 : 250,
                height: smallScreen ? 260 : 320,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AuthPalette.sidebarStart.withValues(alpha: 0.08),
                      AuthPalette.sidebarEnd.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(120),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -40,
            child: _GlowOrb(
              size: math.max(220, size.width * 0.7),
              colors: [
                AuthPalette.accent.withValues(alpha: 0.05),
                AuthPalette.accent.withValues(alpha: 0.01),
              ],
            ),
          ),
          Positioned(
            bottom: size.height * 0.16,
            left: -40,
            child: Transform.rotate(
              angle: 0.36,
              child: Container(
                width: smallScreen ? 150 : 210,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AuthPalette.primary.withValues(alpha: 0.08),
                      AuthPalette.accent.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(80),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche l'orbe lumineuse.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  // Configuration, dependances et etat local de l'interface.
  final double size;
  final List<Color> colors;

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: colors),
        shape: BoxShape.circle,
      ),
    );
  }
}
