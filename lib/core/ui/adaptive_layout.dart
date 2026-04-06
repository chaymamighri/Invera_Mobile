import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Utilitaires reutilisables pour l'espacement adaptatif et les calculs de taille.
class AdaptiveLayout {
  const AdaptiveLayout._();

  // Valeurs calculees et methodes utilitaires.

  /// Verifie si la largeur actuelle de l'ecran correspond a une mise en page telephone.
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  /// Verifie si la largeur actuelle de l'ecran correspond a une mise en page tablette.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 600 && width < 1024;
  }

  /// Retourne l'espacement horizontal pour la taille actuelle de l'ecran.
  static double horizontalPadding(
    BuildContext context, {
    double phone = 14,
    double tablet = 20,
    double desktop = 24,
  }) {
    if (isPhone(context)) return phone;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Retourne la largeur de carte adaptee a l'ecran actuel.
  static double cardWidth(
    BuildContext context, {
    double max = 460,
    double sideMargin = 20,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeWidth = math.max(220.0, screenWidth - (sideMargin * 2));
    return math.min(max, safeWidth);
  }

  /// Retourne la largeur de dialogue adaptee a l'ecran actuel.
  static double dialogWidth(
    BuildContext context, {
    double max = 1000,
    double sideMargin = 16,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeWidth = math.max(240.0, screenWidth - (sideMargin * 2));
    return math.min(max, safeWidth);
  }

  /// Retourne la hauteur de dialogue adaptee a l'ecran actuel.
  static double dialogHeight(BuildContext context, {double ratio = 0.92}) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return math.max(320.0, screenHeight * ratio);
  }

  /// Retourne la largeur du tiroir adaptee a l'ecran actuel.
  static double drawerWidth(
    BuildContext context, {
    double max = 320,
    double ratio = 0.86,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return math.min(max, screenWidth * ratio);
  }
}
