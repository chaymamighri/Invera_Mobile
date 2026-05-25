import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:invera_mobile/config/routes.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/client.dart';
import 'package:invera_mobile/models/commande.dart';
import 'package:invera_mobile/models/utilisateur.dart';
import 'package:invera_mobile/services/authentification.dart';
import 'package:invera_mobile/services/clients.dart';
import 'package:invera_mobile/services/commandes.dart';
import 'package:invera_mobile/views/dashboard/commercial/clients.dart';
import 'package:invera_mobile/views/dashboard/commercial/commandes.dart';
import 'package:invera_mobile/views/dashboard/commercial/factures.dart';
import 'package:invera_mobile/views/dashboard/commercial/factures_generees.dart';
import 'package:invera_mobile/views/dashboard/commercial/produits.dart';
import 'package:invera_mobile/widgets/commercial/sidebar.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _ventePrimary = Color(0xFF2553D4);
const Color _venteTeal = Color(0xFF14B8A6);
const Color _venteInk = Color(0xFF10203A);
const Color _venteMuted = Color(0xFF607089);

/// Methode utilitaire pour le montant compact.
String _compactAmount(double value, {bool withUnit = false}) {
  final abs = value.abs();
  late String formatted;

  if (abs >= 1000000) {
    formatted =
        '${(value / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
  } else if (abs >= 1000) {
    formatted = '${(value / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
  } else if (abs >= 100) {
    formatted = value.toStringAsFixed(0);
  } else {
    formatted = value.toStringAsFixed(1);
  }

  if (formatted.endsWith('.0')) {
    formatted = formatted.substring(0, formatted.length - 2);
  }

  return withUnit ? '$formatted DT' : formatted;
}

/// Methode utilitaire pour la valeur maximale harmonieuse de l'axe.
double _niceAxisMax(double value) {
  if (value <= 0) return 1;

  final exponent = math
      .pow(10, (math.log(value) / math.ln10).floor())
      .toDouble();
  final fraction = value / exponent;
  final niceFraction = fraction <= 1
      ? 1.0
      : fraction <= 2
      ? 2.0
      : fraction <= 5
      ? 5.0
      : 10.0;

  return niceFraction * exponent;
}

/// Retourne un facteur d'echelle progressif pour telephone.
double _phoneScale(BuildContext context, {double min = 0.84}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) return 1;

  final normalizedWidth = width.clamp(320.0, 600.0).toDouble();
  final progress = (normalizedWidth - 320.0) / 280.0;
  return min + ((1 - min) * progress);
}

/// Reduit une valeur numerique sur les petits ecrans.
double _scaledValue(BuildContext context, double value, {double min = 0.84}) {
  return value * _phoneScale(context, min: min);
}

/// Widget qui affiche le tableau de bord commercial.
class CommercialDashboard extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final User user;
  final String appTitle;
  final String appSubtitle;
  final String analyticsTitle;
  final String analyticsSubtitle;
  final String initialPage;
  final List<CommercialSidebarSection>? sidebarSections;

  const CommercialDashboard({
    super.key,
    required this.user,
    this.appTitle = 'Commercial',
    this.appSubtitle = 'Gestion des ventes',
    this.analyticsTitle = 'Performance commerciale',
    this.analyticsSubtitle =
        'Suivi en temps reel de vos clients, ventes et commandes.',
    this.initialPage = 'dashboard',
    this.sidebarSections,
  });

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<CommercialDashboard> createState() => _CommercialDashboardState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour le tableau de bord commercial.
class _CommercialDashboardState extends State<CommercialDashboard> {
  // Configuration, dependances et etat local de l'interface.
  bool _sidebarCollapsed = false;
  late String _activePage;

  @override
  void initState() {
    super.initState();
    _activePage = widget.initialPage;
  }

  List<CommercialSidebarSection> get _sections =>
      widget.sidebarSections ??
      [
        const CommercialSidebarSection(
          title: 'TABLEAU DE BORD',
          items: [
            CommercialSidebarItem(
              id: 'dashboard',
              label: 'Statistiques',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        const CommercialSidebarSection(
          title: 'CATALOGUE',
          items: [
            CommercialSidebarItem(
              id: 'produits',
              label: 'Produits',
              icon: Icons.inventory_2_outlined,
            ),
            CommercialSidebarItem(
              id: 'clients',
              label: 'Clients',
              icon: Icons.people_alt_outlined,
            ),
          ],
        ),
        const CommercialSidebarSection(
          title: 'VENTES',
          items: [
            CommercialSidebarItem(
              id: 'commandes',
              label: 'Commandes',
              icon: Icons.shopping_cart_outlined,
            ),
            CommercialSidebarItem(
              id: 'ventes',
              label: 'Ventes',
              icon: Icons.paid_outlined,
            ),
            CommercialSidebarItem(
              id: 'factures_generees',
              label: 'Facturation',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
      ];

  // Actions utilisateur et traitements asynchrones.
  /// Bascule l'etat de la barre laterale.
  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  /// Met a jour la page active.
  void _setActivePage(String pageId) {
    setState(() {
      _activePage = pageId;
    });
  }

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour le titre de la page.
  String _pageTitle() {
    switch (_activePage) {
      case 'dashboard':
        return widget.analyticsTitle;
      case 'clients':
        return 'Gestion des clients';
      case 'produits':
        return 'Catalogue produits';
      case 'commandes':
        return 'Commandes commerciales';
      case 'ventes':
        return 'Ventes';
      case 'factures_generees':
        return 'Factures';
      case 'factures':
        return 'Facturation vente';
      default:
        return widget.analyticsTitle;
    }
  }

  /// Methode utilitaire pour le sous-titre de la page.
  String _pageSubtitle() {
    switch (_activePage) {
      case 'dashboard':
        return widget.analyticsSubtitle;
      case 'clients':
        return 'Prospection, suivi du portefeuille et operations client';
      case 'produits':
        return 'Consultation du catalogue, des prix et des disponibilites produits';
      case 'commandes':
        return 'Creation, suivi des statuts et pilotage des commandes de vente';
      case 'ventes':
        return 'Commandes validees, pretes pour le suivi vente et la facturation';
      case 'factures_generees':
        return 'Liste des factures generees a partir des ventes';
      case 'factures':
        return 'Generation, recherche et controle des factures commerciales';
      default:
        return widget.analyticsSubtitle;
    }
  }

  /// Retourne le libelle affiche pour le role actuel de l'utilisateur.
  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrateur';
      case UserRole.RESPONSABLE_ACHAT:
        return 'Responsable achat';
      case UserRole.RESPONSABLE_VENTE:
        return 'Responsable vente';
      case UserRole.COMMERCIAL:
        return 'Commercial';
    }
  }

  /// Methode utilitaire pour la deconnexion.
  Future<void> _logout() async {
    final authService = AuthService();
    await authService.logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  // Actions utilisateur et traitements asynchrones.

  /// Methode utilitaire pour la confirmation de deconnexion.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Deconnexion'),
          content: const Text('Voulez-vous vraiment vous deconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Deconnecter'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _logout();
    }
  }

  /// Ouvre le profil.
  void _openProfile() {
    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'user': widget.user},
    );
  }

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour le theme du module.
  ThemeData _moduleTheme(BuildContext context) {
    final base = Theme.of(context);
    final scale = _phoneScale(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: _ventePrimary,
      primary: _ventePrimary,
      secondary: _venteTeal,
      surface: Colors.white,
    );

    double size(double value, {double min = 0.84}) =>
        _scaledValue(context, value, min: min);

    OutlineInputBorder border(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(size(16)),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final compactButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: _ventePrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: size(14), vertical: size(12)),
      minimumSize: Size(0, size(40)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size(14)),
      ),
      textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: size(13)),
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _venteInk,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _venteInk,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size(13),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: EdgeInsets.symmetric(
          horizontal: size(14),
          vertical: size(12),
        ),
        labelStyle: TextStyle(color: _venteMuted, fontSize: size(13)),
        hintStyle: TextStyle(
          color: const Color(0xFF91A0B5),
          fontSize: size(12.5),
        ),
        border: border(const Color(0xFFDCE5F3)),
        enabledBorder: border(const Color(0xFFDCE5F3)),
        focusedBorder: border(_ventePrimary, width: 1.6),
        errorBorder: border(const Color(0xFFDC2626)),
        focusedErrorBorder: border(const Color(0xFFDC2626), width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(style: compactButtonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: compactButtonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _venteInk,
          padding: EdgeInsets.symmetric(
            horizontal: size(14),
            vertical: size(12),
          ),
          minimumSize: Size(0, size(40)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Color(0xFFD8E2F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size(14)),
          ),
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: size(13)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _ventePrimary,
          padding: EdgeInsets.symmetric(
            horizontal: size(12),
            vertical: size(10),
          ),
          minimumSize: Size(0, size(36)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: size(13)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _venteInk,
          padding: EdgeInsets.all(size(8, min: 0.88)),
          minimumSize: Size(size(36), size(36)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          iconSize: size(20),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        selectedColor: _ventePrimary.withValues(alpha: 0.12),
        secondarySelectedColor: _ventePrimary.withValues(alpha: 0.12),
        side: const BorderSide(color: Color(0xFFD8E2F2)),
        padding: EdgeInsets.symmetric(
          horizontal: size(8, min: 0.9),
          vertical: size(1, min: 0.9),
        ),
        labelStyle: TextStyle(
          fontSize: size(12),
          fontWeight: FontWeight.w600,
          color: _venteInk,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999 * scale),
        ),
      ),
    );
  }

  // Construction de l'interface.

  /// Construit le bouton d'action du mode bureau.
  Widget _buildDesktopActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
    Color background = const Color(0x24FFFFFF),
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x30FFFFFF)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  /// Construit la toile de fond de l'enveloppe.
  Widget _buildShellBackdrop({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F7FB), Color(0xFFEAF1FF), Color(0xFFF8FBFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _ventePrimary.withValues(alpha: 0.16),
                    _ventePrimary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -140,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _venteTeal.withValues(alpha: 0.14),
                    _venteTeal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: 120,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// Construit le contenu de page anime.
  Widget _buildAnimatedPageContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.02, 0.03),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(_activePage),
        child: _buildPageContent(),
      ),
    );
  }

  /// Construit le contenu de la page.
  Widget _buildPageContent() {
    switch (_activePage) {
      case 'dashboard':
        return _CommercialAnalyticsDashboard(
          title: widget.analyticsTitle,
          subtitle: widget.analyticsSubtitle,
        );
      case 'clients':
        return const CommercialClientsSection();
      case 'produits':
        return const CommercialProductsSection();
      case 'commandes':
        return const CommercialCommandesSection();
      case 'ventes':
        return const CommercialFacturesSection(
          title: 'Ventes',
          subtitle:
              'Commandes client validees. Consultez les ventes et generez les factures.',
        );
      case 'factures_generees':
        return const CommercialFacturesGenereesSection();
      case 'factures':
        return const CommercialFacturesSection();
      default:
        return _CommercialAnalyticsDashboard(
          title: widget.analyticsTitle,
          subtitle: widget.analyticsSubtitle,
        );
    }
  }

  /// Construit la barre d'application mobile.
  PreferredSizeWidget _buildMobileAppBar() {
    final currentPageTitle = _pageTitle();
    final scale = _phoneScale(context, min: 0.86);
    return AppBar(
      toolbarHeight: 64 * scale,
      backgroundColor: Colors.white.withValues(alpha: 0.72),
      foregroundColor: _venteInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(width: 4 * scale),
          Container(
            width: 32 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _ventePrimary.withValues(alpha: 0.14),
                  _venteTeal.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(11 * scale),
            ),
            padding: EdgeInsets.all(5.5 * scale),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.business),
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5 * scale,
                  ),
                ),
                Text(
                  currentPageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11 * scale, color: _venteMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: _buildTopActions(),
    );
  }

  /// Construit les actions principales.
  List<Widget> _buildTopActions() {
    final scale = _phoneScale(context, min: 0.86);
    return [
      IconButton(
        tooltip: 'Profil',
        onPressed: _openProfile,
        icon: Icon(Icons.person_outline, size: 19 * scale),
      ),
      IconButton(
        tooltip: 'Deconnexion',
        onPressed: _confirmLogout,
        icon: Icon(Icons.logout, color: Colors.red, size: 19 * scale),
      ),
      SizedBox(width: 4 * scale),
    ];
  }

  /// Construit la barre superieure du mode bureau.
  Widget _buildDesktopTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(28, 24, 24, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C1934), Color(0xFF163985), Color(0xFF177A99)],
          ),
          borderRadius: BorderRadius.all(Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x220F172A),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -34,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: 120,
              bottom: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        child: const Text(
                          'Flux ventes | design studio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _pageTitle(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pageSubtitle(),
                        style: const TextStyle(
                          color: Color(0xD7F8FAFC),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.user.prenom} ${widget.user.nom}'.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _roleLabel(widget.user.role),
                        style: const TextStyle(
                          color: Color(0xD7E2E8F0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildDesktopActionButton(
                  tooltip: 'Profil',
                  icon: Icons.person_outline,
                  onPressed: _openProfile,
                ),
                const SizedBox(width: 10),
                _buildDesktopActionButton(
                  tooltip: 'Deconnexion',
                  icon: Icons.logout,
                  onPressed: _confirmLogout,
                  iconColor: const Color(0xFFFFD6D6),
                  background: const Color(0x26FF6B6B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({required bool collapsed, required bool mobile}) {
    return CommercialSidebar(
      user: widget.user,
      appTitle: widget.appTitle,
      appSubtitle: widget.appSubtitle,
      activePage: _activePage,
      sections: _sections,
      collapsed: collapsed,
      mobile: mobile,
      onToggleCollapsed: _toggleSidebar,
      onSelectPage: _setActivePage,
      onOpenProfile: _openProfile,
      onConfirmLogout: _confirmLogout,
    );
  }

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;
    final isPhone = AdaptiveLayout.isPhone(context);
    final phoneScale = _phoneScale(context, min: 0.84);

    final themedChild = isMobile
        ? Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildMobileAppBar(),
            drawer: Drawer(
              backgroundColor: Colors.transparent,
              width: AdaptiveLayout.drawerWidth(
                context,
                max: isPhone ? 280 : 304,
                ratio: isPhone ? 0.80 : 0.88,
              ),
              child: _buildSidebar(collapsed: false, mobile: true),
            ),
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AdaptiveLayout.horizontalPadding(
                    context,
                    phone: 10.5 * phoneScale,
                    tablet: 16,
                    desktop: 24,
                  ),
                  isPhone ? 10 * phoneScale : 16,
                  AdaptiveLayout.horizontalPadding(
                    context,
                    phone: 10.5 * phoneScale,
                    tablet: 16,
                    desktop: 24,
                  ),
                  isPhone ? 10 * phoneScale : 16,
                ),
                child: Column(
                  children: [Expanded(child: _buildAnimatedPageContent())],
                ),
              ),
            ),
          )
        : Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: _sidebarCollapsed ? 92 : 284,
                    margin: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x160F172A),
                          blurRadius: 24,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: _buildSidebar(
                      collapsed: _sidebarCollapsed,
                      mobile: false,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDesktopTopBar(),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: _buildAnimatedPageContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

    return Theme(
      data: _moduleTheme(context),
      child: _buildShellBackdrop(child: themedChild),
    );
  }
}

/// Widget qui affiche le tableau de bord analytique commercial.
class _CommercialAnalyticsDashboard extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final String subtitle;

  const _CommercialAnalyticsDashboard({
    required this.title,
    required this.subtitle,
  });

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<_CommercialAnalyticsDashboard> createState() =>
      _CommercialAnalyticsDashboardState();
}

/// Classe utilitaire pour l'etat du tableau de bord analytique commercial.
class _CommercialAnalyticsDashboardState
    extends State<_CommercialAnalyticsDashboard> {
  final ClientService _clientService = ClientService();
  final CommandeService _commandeService = CommandeService();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<ClientModel> _clients = <ClientModel>[];
  List<CommandeModel> _commandes = <CommandeModel>[];
  DateTime? _lastSync;

  static const Set<String> _confirmedStatuses = {'CONFIRMEE', 'VALIDEE'};
  static const Set<String> _pendingStatuses = {'EN_ATTENTE'};
  static const Set<String> _canceledStatuses = {'ANNULEE', 'REJETEE'};

  @override
  void initState() {
    super.initState();
    _loadDashboard(showLoader: true);
  }

  Future<void> _loadDashboard({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      final results = await Future.wait([
        _clientService.getClients(),
        _commandeService.getCommandes(),
      ]);

      if (!mounted) return;
      setState(() {
        _clients = (results[0] as List<ClientModel>);
        _commandes = (results[1] as List<CommandeModel>);
        _lastSync = DateTime.now();
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get _clientsCount => _clients.length;
  int get _ordersCount => _commandes.length;

  List<CommandeModel> get _confirmedOrders => _commandes
      .where((c) => _confirmedStatuses.contains(c.statut.trim().toUpperCase()))
      .toList();

  int get _confirmedCount => _confirmedOrders.length;
  int get _pendingCount => _commandes
      .where((c) => _pendingStatuses.contains(c.statut.trim().toUpperCase()))
      .length;
  int get _canceledCount => _commandes
      .where((c) => _canceledStatuses.contains(c.statut.trim().toUpperCase()))
      .length;

  double get _revenue =>
      _confirmedOrders.fold<double>(0, (sum, c) => sum + c.total);
  double get _avgTicket =>
      _confirmedCount == 0 ? 0 : _revenue / _confirmedCount;

  int get _activeClientCount {
    final ids = _confirmedOrders
        .map((c) => c.client?.idClient)
        .whereType<int>()
        .toSet();
    return ids.length;
  }

  double get _conversionRate {
    if (_ordersCount == 0) return 0;
    return (_confirmedCount / _ordersCount) * 100;
  }

  String _money(double value) => '${value.toStringAsFixed(2)} DT';

  String _syncStamp(DateTime? value) {
    if (value == null) return '-';
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mn = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mn';
  }

  DateTime? _parseCommandeDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == '-') return null;

    final normalized = value.replaceFirst('T', ' ');
    final direct = DateTime.tryParse(normalized);
    if (direct != null) return direct;

    final dmyPattern = RegExp(
      r'^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$',
    );
    final ymdPattern = RegExp(
      r'^(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?$',
    );

    final dmy = dmyPattern.firstMatch(value);
    if (dmy != null) {
      return DateTime(
        int.parse(dmy.group(3)!),
        int.parse(dmy.group(2)!),
        int.parse(dmy.group(1)!),
        int.parse(dmy.group(4) ?? '0'),
        int.parse(dmy.group(5) ?? '0'),
        int.parse(dmy.group(6) ?? '0'),
      );
    }

    final ymd = ymdPattern.firstMatch(value);
    if (ymd != null) {
      return DateTime(
        int.parse(ymd.group(1)!),
        int.parse(ymd.group(2)!),
        int.parse(ymd.group(3)!),
        int.parse(ymd.group(4) ?? '0'),
        int.parse(ymd.group(5) ?? '0'),
        int.parse(ymd.group(6) ?? '0'),
      );
    }

    return null;
  }

  List<_MonthlySalesPoint> _monthlySales() {
    final now = DateTime.now();
    final months = List<_MonthlySalesPoint>.generate(6, (index) {
      final d = DateTime(now.year, now.month - (5 - index), 1);
      return _MonthlySalesPoint(month: d, value: 0);
    });

    final totals = <String, double>{
      for (final m in months) '${m.month.year}-${m.month.month}': 0,
    };

    for (final order in _confirmedOrders) {
      final date = _parseCommandeDate(order.dateCommandeFormatted);
      if (date == null) continue;
      final key = '${date.year}-${date.month}';
      if (totals.containsKey(key)) {
        totals[key] = (totals[key] ?? 0) + order.total;
      }
    }

    return months
        .map(
          (m) => _MonthlySalesPoint(
            month: m.month,
            value: totals['${m.month.year}-${m.month.month}'] ?? 0,
          ),
        )
        .toList();
  }

  String _monthLabel(DateTime month) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aou',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month.month - 1];
  }

  List<_LabeledIntValue> _clientsByType() {
    if (_clients.isEmpty) {
      return const <_LabeledIntValue>[];
    }

    final counts = <String, int>{
      for (final type in ClientType.allowedValues) type: 0,
    };

    for (final client in _clients) {
      final type = ClientType.normalize(
        client.typeClient,
        fallbackToDefault: true,
      );
      counts[type] = (counts[type] ?? 0) + 1;
    }

    return ClientType.allowedValues
        .map(
          (type) => _LabeledIntValue(
            label: ClientType.label(type),
            value: counts[type] ?? 0,
          ),
        )
        .toList();
  }

  List<_ClientRevenuePoint> _topClients() {
    final revenueByClient = <String, double>{};
    final ordersByClient = <String, int>{};

    for (final order in _confirmedOrders) {
      final client = order.client;
      final label = client == null
          ? 'Client inconnu'
          : '${client.idClient} | ${client.fullName}';
      revenueByClient[label] = (revenueByClient[label] ?? 0) + order.total;
      ordersByClient[label] = (ordersByClient[label] ?? 0) + 1;
    }

    final ranked = revenueByClient.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ranked.take(5).map((entry) {
      final pipeIndex = entry.key.indexOf('|');
      final displayName = pipeIndex < 0
          ? entry.key
          : entry.key.substring(pipeIndex + 1).trim();
      return _ClientRevenuePoint(
        label: displayName,
        value: entry.value,
        orders: ordersByClient[entry.key] ?? 0,
      );
    }).toList();
  }

  List<CommandeModel> _recentOrders() {
    final copy = List<CommandeModel>.from(_commandes);
    copy.sort((a, b) {
      final ad = _parseCommandeDate(a.dateCommandeFormatted);
      final bd = _parseCommandeDate(b.dateCommandeFormatted);
      if (ad != null && bd != null) {
        return bd.compareTo(ad);
      }
      return b.idCommandeClient.compareTo(a.idCommandeClient);
    });
    return copy.take(6).toList();
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toUpperCase();
    if (_pendingStatuses.contains(normalized)) return const Color(0xFFD97706);
    if (_confirmedStatuses.contains(normalized)) return const Color(0xFF16A34A);
    if (_canceledStatuses.contains(normalized)) return const Color(0xFFDC2626);
    return const Color(0xFF2D47C8);
  }

  Widget _panelCard({
    required String title,
    required String subtitle,
    required Widget child,
    required IconData icon,
    Widget? trailing,
  }) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final scale = compact ? _phoneScale(context, min: 0.84) : 1.0;

    return Container(
      padding: EdgeInsets.all(compact ? 12 * scale : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((compact ? 14 : 16) * scale),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: (compact ? 28 : 30) * scale,
                height: (compact ? 28 : 30) * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D47C8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2D47C8),
                  size: (compact ? 15.5 : 17) * scale,
                ),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: (compact ? 13.2 : 14) * scale,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Color(0xFF607089),
                        fontSize: (compact ? 10.8 : 11.5) * scale,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          SizedBox(height: 11 * scale),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _clients.isEmpty && _commandes.isEmpty) {
      final phoneScale = _phoneScale(context, min: 0.84);
      final isPhone = MediaQuery.sizeOf(context).width < 560;
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: EdgeInsets.all(isPhone ? 18 * phoneScale : 24),
          margin: EdgeInsets.all(isPhone ? 14 * phoneScale : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isPhone ? 14 : 16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: isPhone ? 34 * phoneScale : 40,
              ),
              SizedBox(height: 12 * phoneScale),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFB42318),
                  fontSize: isPhone ? 12.5 : 13,
                ),
              ),
              SizedBox(height: 14 * phoneScale),
              ElevatedButton.icon(
                onPressed: () => _loadDashboard(showLoader: true),
                icon: Icon(Icons.refresh, size: isPhone ? 17 : 18),
                label: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final monthlySales = _monthlySales();
    final salesValues = monthlySales.map((m) => m.value).toList();
    final typeData = _clientsByType();
    final topClients = _topClients();
    final recentOrders = _recentOrders();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth > 1240;
    final isPhone = screenWidth < 560;
    final phoneScale = _phoneScale(context, min: 0.84);
    final showTypeDistribution = screenWidth >= 600;
    final horizontalPadding = screenWidth < 390
        ? 10.0 * phoneScale
        : (screenWidth < 760 ? 14.0 : 24.0);
    final verticalPadding = screenWidth < 760 ? (isPhone ? 12.0 : 16.0) : 20.0;
    final kpiColumns = screenWidth < 1100 ? 2 : 4;
    final kpiAspectRatio = screenWidth < 390
        ? 1.34
        : (screenWidth < 700 ? 1.55 : (screenWidth < 1100 ? 2.0 : 2.2));
    final cardPadding = isPhone ? 12.0 * phoneScale : 14.0;
    final inlineGap = isPhone ? 8.0 * phoneScale : 10.0;
    final gridGap = isPhone ? 8.0 * phoneScale : 10.0;
    final topClientsPreview = (isPhone ? topClients.take(4) : topClients)
        .toList();
    final recentOrdersPreview =
        (screenWidth < 640 ? recentOrders.take(3) : recentOrders).toList();

    final statusSegments = <_DonutSegment>[
      _DonutSegment(
        label: 'Confirmees',
        value: _confirmedCount.toDouble(),
        color: const Color(0xFF16A34A),
      ),
      _DonutSegment(
        label: 'En attente',
        value: _pendingCount.toDouble(),
        color: const Color(0xFFD97706),
      ),
      _DonutSegment(
        label: 'Annulees',
        value: _canceledCount.toDouble(),
        color: const Color(0xFFDC2626),
      ),
    ];

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          isPhone ? 18 : 24,
        ),
        children: [
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(isPhone ? 14 : 16),
              border: Border.all(color: const Color(0xFFE6EAF2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compactHeader = constraints.maxWidth < 520;
                    final titleBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: const Color(0xFF1F2A44),
                            fontWeight: FontWeight.w800,
                            fontSize: compactHeader
                                ? (isPhone ? 15 : 16)
                                : (isPhone ? 17 : 18),
                          ),
                        ),
                        SizedBox(height: 2 * phoneScale),
                        Text(
                          'Vue compacte des indicateurs essentiels.',
                          style: TextStyle(
                            color: Color(0xFF607089),
                            fontSize: isPhone ? 11.2 : 12,
                          ),
                        ),
                      ],
                    );

                    final refreshButton = OutlinedButton.icon(
                      onPressed: _refreshing
                          ? null
                          : () => _loadDashboard(showLoader: false),
                      icon: _refreshing
                          ? SizedBox(
                              width: isPhone ? 12 : 14,
                              height: isPhone ? 12 : 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, size: isPhone ? 17 : 18),
                      label: const Text('Actualiser'),
                    );

                    if (compactHeader) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleBlock,
                          SizedBox(height: inlineGap),
                          refreshButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: titleBlock),
                        refreshButton,
                      ],
                    );
                  },
                ),
                SizedBox(height: inlineGap),
                Wrap(
                  spacing: isPhone ? 6 * phoneScale : 8,
                  runSpacing: isPhone ? 6 * phoneScale : 8,
                  children: [
                    _HeaderStatPill(
                      icon: Icons.people_alt_outlined,
                      label: 'Actifs',
                      value: '$_activeClientCount',
                    ),
                    _HeaderStatPill(
                      icon: Icons.check_circle_outline,
                      label: 'Conversion',
                      value: '${_conversionRate.toStringAsFixed(1)}%',
                    ),
                    _HeaderStatPill(
                      icon: Icons.schedule_outlined,
                      label: 'Sync',
                      value: _syncStamp(_lastSync),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: inlineGap),
            Container(
              padding: EdgeInsets.all(isPhone ? 10 * phoneScale : 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(isPhone ? 10 : 12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB42318),
                    size: isPhone ? 19 : 22,
                  ),
                  SizedBox(width: isPhone ? 8 * phoneScale : 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: const Color(0xFFB42318),
                        fontSize: isPhone ? 12.2 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: inlineGap),
          GridView.count(
            crossAxisCount: kpiColumns,
            crossAxisSpacing: gridGap,
            mainAxisSpacing: gridGap,
            childAspectRatio: kpiAspectRatio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _KpiTile(
                label: 'Clients',
                value: '$_clientsCount',
                icon: Icons.people_outline,
                color: const Color(0xFF0284C7),
              ),
              _KpiTile(
                label: 'Commandes',
                value: '$_ordersCount',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFFEA580C),
              ),
              _KpiTile(
                label: 'CA confirme',
                value: _money(_revenue),
                icon: Icons.payments_outlined,
                color: const Color(0xFF16A34A),
              ),
              _KpiTile(
                label: 'Panier moyen',
                value: _money(_avgTicket),
                icon: Icons.trending_up_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          SizedBox(height: isPhone ? 10 * phoneScale : 12),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _panelCard(
                    title: 'Evolution des ventes',
                    subtitle: '6 derniers mois confirmes',
                    icon: Icons.show_chart_rounded,
                    child: _SalesTrendChart(
                      values: salesValues,
                      labels: monthlySales
                          .map((m) => _monthLabel(m.month))
                          .toList(),
                    ),
                  ),
                ),
                SizedBox(width: isPhone ? 10 * phoneScale : 12),
                Expanded(
                  child: _panelCard(
                    title: 'Statut des commandes',
                    subtitle: 'Repartition actuelle',
                    icon: Icons.donut_small_rounded,
                    child: _StatusDonutCard(
                      segments: statusSegments,
                      total: _ordersCount,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _panelCard(
              title: 'Evolution des ventes',
              subtitle: '6 derniers mois confirmes',
              icon: Icons.show_chart_rounded,
              child: _SalesTrendChart(
                values: salesValues,
                labels: monthlySales.map((m) => _monthLabel(m.month)).toList(),
              ),
            ),
            SizedBox(height: inlineGap),
            _panelCard(
              title: 'Statut des commandes',
              subtitle: 'Repartition actuelle',
              icon: Icons.donut_small_rounded,
              child: _StatusDonutCard(
                segments: statusSegments,
                total: _ordersCount,
              ),
            ),
          ],
          SizedBox(height: inlineGap),
          if (isWide && showTypeDistribution)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _panelCard(
                    title: 'Repartition des clients',
                    subtitle: 'Types de client',
                    icon: Icons.pie_chart_outline,
                    child: _TypeDistributionBars(data: typeData),
                  ),
                ),
                SizedBox(width: isPhone ? 10 * phoneScale : 12),
                Expanded(
                  child: _panelCard(
                    title: 'Top clients',
                    subtitle: 'Classement CA confirme',
                    icon: Icons.workspace_premium_outlined,
                    child: _TopClientsList(
                      data: topClientsPreview,
                      money: _money,
                    ),
                  ),
                ),
              ],
            )
          else if (showTypeDistribution) ...[
            _panelCard(
              title: 'Repartition des clients',
              subtitle: 'Types de client',
              icon: Icons.pie_chart_outline,
              child: _TypeDistributionBars(data: typeData),
            ),
            SizedBox(height: inlineGap),
            _panelCard(
              title: 'Top clients',
              subtitle: 'Classement CA confirme',
              icon: Icons.workspace_premium_outlined,
              child: _TopClientsList(data: topClientsPreview, money: _money),
            ),
          ] else ...[
            _panelCard(
              title: 'Top clients',
              subtitle: 'Classement CA confirme',
              icon: Icons.workspace_premium_outlined,
              child: _TopClientsList(data: topClientsPreview, money: _money),
            ),
          ],
          SizedBox(height: inlineGap),
          _panelCard(
            title: 'Commandes recentes',
            subtitle: isPhone
                ? 'Derniers dossiers prioritaires'
                : 'Derniers mouvements du portefeuille',
            icon: Icons.history_toggle_off_rounded,
            child: _RecentOrdersList(
              orders: recentOrdersPreview,
              statusColor: _statusColor,
              money: _money,
            ),
          ),
        ],
      ),
    );
  }
}

/// Classe utilitaire pour le point de ventes mensuelles.
class _MonthlySalesPoint {
  // Configuration, dependances et etat local de l'interface.
  final DateTime month;
  final double value;

  const _MonthlySalesPoint({required this.month, required this.value});
}

/// Classe utilitaire pour labeled int valeur.
class _LabeledIntValue {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final int value;

  const _LabeledIntValue({required this.label, required this.value});
}

/// Classe utilitaire pour le point de chiffre d'affaires client.
class _ClientRevenuePoint {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final double value;
  final int orders;

  const _ClientRevenuePoint({
    required this.label,
    required this.value,
    required this.orders,
  });
}

/// Widget qui affiche la pastille statistique d'en-tete.
class _HeaderStatPill extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final scale = _phoneScale(context, min: 0.84);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(11 * scale),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.5 * scale, color: const Color(0xFF2D47C8)),
          SizedBox(width: 6 * scale),
          Text(
            '$label: ',
            style: TextStyle(
              color: Color(0xFF607089),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF1F2A44),
              fontSize: 11 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la tuile d'indicateur cle.
class _KpiTile extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final phoneCompact = MediaQuery.sizeOf(context).width < 600;
        final compact = phoneCompact || constraints.maxWidth < 170;
        final scale = phoneCompact ? _phoneScale(context, min: 0.84) : 1.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all((compact ? 11.5 : 13) * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular((compact ? 13 : 14) * scale),
            border: Border.all(color: const Color(0xFFE6EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: (compact ? 34 : 40) * scale,
                    height: (compact ? 34 : 40) * scale,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: (compact ? 17 : 20) * scale,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: (compact ? 7 : 8) * scale,
                    height: (compact ? 7 : 8) * scale,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              SizedBox(height: (compact ? 9 : 12) * scale),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF607089),
                  fontSize: (compact ? 11 : 12.5) * scale,
                ),
              ),
              SizedBox(height: 4 * scale),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1F2A44),
                  fontWeight: FontWeight.w800,
                  fontSize: (compact ? 14.4 : 17) * scale,
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget qui affiche le graphique de tendance des ventes.
class _SalesTrendChart extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final List<double> values;
  final List<String> labels;

  const _SalesTrendChart({required this.values, required this.labels});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v > 0);
    final maxValue = values.fold<double>(0, math.max);
    final axisMax = _niceAxisMax(maxValue);
    final axisTicks = List<double>.generate(
      5,
      (index) => (axisMax / 4) * (4 - index),
    );
    final peakValue = hasData ? values.reduce(math.max) : 0.0;
    final peakIndex = hasData ? values.indexOf(peakValue) : -1;
    final helperText = hasData
        ? 'Montants en DT. Pic ${labels[peakIndex]}: ${_compactAmount(peakValue, withUnit: true)}'
        : 'Montants en DT. Aucune vente confirmee sur la periode.';

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _phoneScale(context, min: 0.84);
        final compact = constraints.maxWidth < 360;
        final chartHeight = compact ? 186.0 * scale : 220.0;
        final axisWidth = compact ? 34.0 * scale : 42.0;
        final axisFont = compact ? 9.6 * scale : 10.5;
        final labelFont = compact ? 10.0 * scale : 11.0;
        final valueFont = compact ? 8.7 * scale : 9.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              helperText,
              style: TextStyle(
                color: const Color(0xFF607089),
                fontSize: (compact ? 10.6 : 11.5) * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 9 * scale),
            SizedBox(
              height: chartHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: axisWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final tick in axisTicks)
                          Text(
                            _compactAmount(tick),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: hasData
                                  ? const Color(0xFF607089)
                                  : const Color(0xFF94A3B8),
                              fontSize: axisFont,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: CustomPaint(
                      painter: _SalesTrendPainter(
                        values: values,
                        maxValue: axisMax,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hasData
                                ? const Color(0xFF607089)
                                : const Color(0xFF94A3B8),
                            fontSize: labelFont,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          _compactAmount(values[i]),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: valueFont,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Classe utilitaire pour le peintre de tendance des ventes.
class _SalesTrendPainter extends CustomPainter {
  // Configuration, dependances et etat local de l'interface.
  final List<double> values;
  final double maxValue;

  _SalesTrendPainter({required this.values, required this.maxValue});

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour le dessin.
  @override
  void paint(Canvas canvas, Size size) {
    final lineStroke = size.height < 200 ? 2.4 : 3.0;
    final dotRadius = size.height < 200 ? 3.2 : 4.0;
    final dotStrokeWidth = size.height < 200 ? 1.6 : 2.0;
    final gridPaint = Paint()
      ..color = const Color(0xFFE6EAF2)
      ..strokeWidth = 1;

    const topPadding = 6.0;
    const bottomPadding = 16.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final baseY = topPadding + chartHeight;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    final stepX = values.length <= 1
        ? size.width
        : size.width / (values.length - 1);

    final line = Path();
    final area = Path();

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / safeMax).clamp(0, 1);
      final y = baseY - (chartHeight * normalized);

      if (i == 0) {
        line.moveTo(x, y);
        area.moveTo(x, baseY);
        area.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        area.lineTo(x, y);
      }
    }

    area
      ..lineTo((values.length - 1) * stepX, baseY)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x662D47C8), Color(0x002D47C8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));
    canvas.drawPath(area, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF2D47C8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = lineStroke;
    canvas.drawPath(line, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF2D47C8);
    final dotStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = dotStrokeWidth;
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / safeMax).clamp(0, 1);
      final y = baseY - (chartHeight * normalized);
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);
      canvas.drawCircle(Offset(x, y), dotRadius, dotStroke);
    }
  }

  /// Methode utilitaire pour la necessite de repeindre.
  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.maxValue != maxValue) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

/// Classe utilitaire pour le segment de diagramme en anneau.
class _DonutSegment {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final double value;
  final Color color;

  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Widget qui affiche la carte en anneau des statuts.
class _StatusDonutCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final List<_DonutSegment> segments;
  final int total;

  const _StatusDonutCard({required this.segments, required this.total});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = _phoneScale(context, min: 0.84);
        final compact = constraints.maxWidth < 320;
        final chartSize = math.min(
          compact ? 154.0 * scale : 172.0,
          math.max(compact ? 128.0 * scale : 140.0, constraints.maxWidth - 24),
        );

        return Column(
          children: [
            SizedBox(
              width: chartSize,
              height: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(chartSize, chartSize),
                    painter: _DonutPainter(segments: segments),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: Color(0xFF607089),
                          fontSize: (compact ? 11.0 : 12.0) * scale,
                        ),
                      ),
                      Text(
                        '$total',
                        style: TextStyle(
                          color: Color(0xFF1F2A44),
                          fontWeight: FontWeight.w800,
                          fontSize: (compact ? 19.5 : 23.0) * scale,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),
            for (final s in segments)
              Padding(
                padding: EdgeInsets.only(bottom: 6 * scale),
                child: Row(
                  children: [
                    Container(
                      width: 8.5 * scale,
                      height: 8.5 * scale,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3 * scale),
                      ),
                    ),
                    SizedBox(width: 6 * scale),
                    Expanded(
                      child: Text(
                        s.label,
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: (compact ? 11.5 : 12.5) * scale,
                        ),
                      ),
                    ),
                    Text(
                      '${s.value.toStringAsFixed(0)} (${total == 0 ? 0 : ((s.value / total) * 100).round()}%)',
                      style: TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                        fontSize: (compact ? 11.5 : 12.5) * scale,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Classe utilitaire pour le peintre de diagramme en anneau.
class _DonutPainter extends CustomPainter {
  // Configuration, dependances et etat local de l'interface.
  final List<_DonutSegment> segments;

  _DonutPainter({required this.segments});

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour le dessin.
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = (size.shortestSide * 0.12).clamp(16.0, 20.0).toDouble();
    final radius = math.min(size.width, size.height) / 2 - (stroke / 2) - 1;

    final basePaint = Paint()
      ..color = const Color(0xFFE8EDF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, basePaint);

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = (segment.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  /// Methode utilitaire pour la necessite de repeindre.
  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.segments.length != segments.length) return true;
    for (var i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].value != segments[i].value ||
          oldDelegate.segments[i].color != segments[i].color ||
          oldDelegate.segments[i].label != segments[i].label) {
        return true;
      }
    }
    return false;
  }
}

/// Widget qui affiche les barres de repartition par type.
class _TypeDistributionBars extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final List<_LabeledIntValue> data;

  const _TypeDistributionBars({required this.data});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text(
        'Aucune donnee client disponible.',
        style: TextStyle(color: Color(0xFF607089)),
      );
    }

    final maxValue = data.fold<int>(
      1,
      (max, item) => math.max(max, item.value),
    );
    final palette = [
      const Color(0xFF2D47C8),
      const Color(0xFF0284C7),
      const Color(0xFF7C3AED),
      const Color(0xFFEA580C),
      const Color(0xFF16A34A),
      const Color(0xFFDB2777),
    ];

    return Column(
      children: [
        for (var i = 0; i < data.length && i < 6; i++) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  data[i].label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${data[i].value}',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: data[i].value / maxValue,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EDF7),
              valueColor: AlwaysStoppedAnimation<Color>(
                palette[i % palette.length],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Widget qui affiche la liste des meilleurs clients.
class _TopClientsList extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final List<_ClientRevenuePoint> data;
  final String Function(double value) money;

  const _TopClientsList({required this.data, required this.money});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text(
        'Aucune vente confirmee pour le moment.',
        style: TextStyle(color: Color(0xFF607089)),
      );
    }

    final scale = _phoneScale(context, min: 0.84);
    final compact = MediaQuery.sizeOf(context).width < 390;

    return Column(
      children: [
        for (var i = 0; i < data.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: (compact ? 22 : 24) * scale,
                height: (compact ? 22 : 24) * scale,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D47C8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: Color(0xFF2D47C8),
                    fontWeight: FontWeight.w800,
                    fontSize: (compact ? 10.8 : 12) * scale,
                  ),
                ),
              ),
              SizedBox(width: (compact ? 8 : 10) * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                        fontSize: (compact ? 12.2 : 13) * scale,
                      ),
                    ),
                    Text(
                      '${data[i].orders} commande(s)',
                      style: TextStyle(
                        color: Color(0xFF607089),
                        fontSize: (compact ? 11 : 12) * scale,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * scale),
              Text(
                money(data[i].value),
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                  fontSize: (compact ? 12.2 : 13) * scale,
                ),
              ),
            ],
          ),
          if (i != data.length - 1)
            Divider(height: 16 * scale, color: const Color(0xFFE6EAF2)),
        ],
      ],
    );
  }
}

/// Widget qui affiche la liste des commandes recentes.
class _RecentOrdersList extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final List<CommandeModel> orders;
  final Color Function(String status) statusColor;
  final String Function(double value) money;

  const _RecentOrdersList({
    required this.orders,
    required this.statusColor,
    required this.money,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Text(
        'Aucune commande recente.',
        style: TextStyle(color: Color(0xFF607089)),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < orders.length; i++) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final ultraCompact = constraints.maxWidth < 380;
              final scale = _phoneScale(context, min: 0.84);
              final statusPill = Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (ultraCompact ? 7 : 8) * scale,
                  vertical: (ultraCompact ? 3.5 : 4) * scale,
                ),
                decoration: BoxDecoration(
                  color: statusColor(orders[i].statut).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  orders[i].statutDisplay,
                  style: TextStyle(
                    color: statusColor(orders[i].statut),
                    fontSize: (ultraCompact ? 10.6 : 11.5) * scale,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orders[i].referenceCommandeClient,
                      style: TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                        fontSize: (ultraCompact ? 12.4 : 13) * scale,
                      ),
                    ),
                    SizedBox(height: 2 * scale),
                    Text(
                      '${orders[i].client?.fullName ?? 'Client inconnu'} - ${orders[i].dateCommandeFormatted}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF607089),
                        fontSize: (ultraCompact ? 11 : 12) * scale,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Row(
                      children: [
                        statusPill,
                        const Spacer(),
                        Text(
                          money(orders[i].total),
                          style: TextStyle(
                            color: Color(0xFF1F2A44),
                            fontWeight: FontWeight.w800,
                            fontSize: (ultraCompact ? 12.2 : 13) * scale,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orders[i].referenceCommandeClient,
                          style: TextStyle(
                            color: Color(0xFF1F2A44),
                            fontWeight: FontWeight.w700,
                            fontSize: 13 * scale,
                          ),
                        ),
                        SizedBox(height: 2 * scale),
                        Text(
                          '${orders[i].client?.fullName ?? 'Client inconnu'} - ${orders[i].dateCommandeFormatted}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF607089),
                            fontSize: 12 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  statusPill,
                  SizedBox(width: 10 * scale),
                  Text(
                    money(orders[i].total),
                    style: TextStyle(
                      color: Color(0xFF1F2A44),
                      fontWeight: FontWeight.w800,
                      fontSize: 13 * scale,
                    ),
                  ),
                ],
              );
            },
          ),
          if (i != orders.length - 1)
            Divider(
              height: 16 * _phoneScale(context),
              color: const Color(0xFFE6EAF2),
            ),
        ],
      ],
    );
  }
}

