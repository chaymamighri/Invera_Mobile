import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:invera_mobile/config/app_routes.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_clients_section.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_commandes_section.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_factures_section.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _ventePrimary = Color(0xFF2553D4);
const Color _venteTeal = Color(0xFF14B8A6);
const Color _venteInk = Color(0xFF10203A);
const Color _venteMuted = Color(0xFF607089);
const Color _venteSidebarStart = Color(0xFF0B1730);
const Color _venteSidebarEnd = Color(0xFF15367A);

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

/// Widget qui affiche le tableau de bord commercial.
class CommercialDashboard extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final User user;
  final String appTitle;
  final String appSubtitle;
  final String analyticsTitle;
  final String analyticsSubtitle;

  const CommercialDashboard({
    super.key,
    required this.user,
    this.appTitle = 'Commercial',
    this.appSubtitle = 'Gestion des ventes',
    this.analyticsTitle = 'Performance commerciale',
    this.analyticsSubtitle =
        'Suivi en temps reel de vos clients, ventes et commandes.',
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
  String _activePage = 'dashboard';

  final List<_SidebarSection> _sections = const [
    _SidebarSection(
      title: 'Tableau de bord',
      items: [
        _SidebarItem(
          id: 'dashboard',
          label: 'Dashboard',
          icon: Icons.grid_view_rounded,
        ),
      ],
    ),
    _SidebarSection(
      title: 'Gestion commerciale',
      items: [
        _SidebarItem(
          id: 'clients',
          label: 'Clients',
          icon: Icons.people_alt_outlined,
        ),
        _SidebarItem(
          id: 'commandes',
          label: 'Commandes',
          icon: Icons.shopping_cart_outlined,
        ),
        _SidebarItem(
          id: 'factures',
          label: 'Factures',
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
      case 'commandes':
        return 'Commandes commerciales';
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
      case 'commandes':
        return 'Creation, suivi des statuts et pilotage des commandes de vente';
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

  /// Construit les initiales affichees dans l'avatar.
  String _initials() {
    final name = '${widget.user.prenom} ${widget.user.nom}'.trim();
    if (name.isEmpty) return 'US';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'US';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
    final scheme = ColorScheme.fromSeed(
      seedColor: _ventePrimary,
      primary: _ventePrimary,
      secondary: _venteTeal,
      surface: Colors.white,
    );

    OutlineInputBorder border(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final compactButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: _ventePrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _venteInk,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        labelStyle: const TextStyle(color: _venteMuted, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF91A0B5), fontSize: 12.5),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Color(0xFFD8E2F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _ventePrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: _venteInk,
          padding: const EdgeInsets.all(8),
          minimumSize: const Size(36, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          iconSize: 20,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        selectedColor: _ventePrimary.withValues(alpha: 0.12),
        secondarySelectedColor: _ventePrimary.withValues(alpha: 0.12),
        side: const BorderSide(color: Color(0xFFD8E2F2)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _venteInk,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
      case 'commandes':
        return const CommercialCommandesSection();
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
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.72),
      foregroundColor: _venteInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 4),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _ventePrimary.withValues(alpha: 0.14),
                  _venteTeal.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.business),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.appTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const Text(
                'Dashboard vente',
                style: TextStyle(fontSize: 11.5, color: _venteMuted),
              ),
            ],
          ),
        ],
      ),
      actions: _buildTopActions(),
    );
  }

  /// Construit les actions principales.
  List<Widget> _buildTopActions() {
    return [
      IconButton(
        tooltip: 'Profil',
        onPressed: _openProfile,
        icon: const Icon(Icons.person_outline),
      ),
      IconButton(
        tooltip: 'Deconnexion',
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, color: Colors.red),
      ),
      const SizedBox(width: 8),
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

  /// Construit la barre laterale.
  Widget _buildSidebar({required bool collapsed, required bool mobile}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_venteSidebarStart, _venteSidebarEnd],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 12, 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              children: [
                if (!collapsed) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.18),
                                _venteTeal.withValues(alpha: 0.16),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.business, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.appTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.appSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFD3DDEB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Spacer(),
                IconButton(
                  onPressed: mobile
                      ? () => Navigator.pop(context)
                      : _toggleSidebar,
                  icon: Icon(
                    mobile
                        ? Icons.close
                        : (collapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final section in _sections) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFAFC0D9),
                        ),
                      ),
                    ),
                  for (final item in section.items) ...[
                    _buildSidebarItem(item: item, collapsed: collapsed),
                    const SizedBox(height: 6),
                  ],
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            padding: EdgeInsets.all(collapsed ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: collapsed
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: _confirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFFFC0C0),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.user.prenom} ${widget.user.nom}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _roleLabel(widget.user.role),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD3DDEB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: _confirmLogout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFFFC0C0),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Construit l'element de barre laterale.
  Widget _buildSidebarItem({
    required _SidebarItem item,
    required bool collapsed,
  }) {
    final isActive = _activePage == item.id;

    final itemWidget = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _setActivePage(item.id),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.20),
                      _venteTeal.withValues(alpha: 0.16),
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive ? Colors.white : const Color(0xFFD7E1EF),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFFE2EAF5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!collapsed) return itemWidget;

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 300),
      child: itemWidget,
    );
  }

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;

    final themedChild = isMobile
        ? Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildMobileAppBar(),
            drawer: Drawer(
              backgroundColor: Colors.transparent,
              width: AdaptiveLayout.drawerWidth(context, max: 304, ratio: 0.88),
              child: _buildSidebar(collapsed: false, mobile: true),
            ),
            body: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AdaptiveLayout.horizontalPadding(context),
                  16,
                  AdaptiveLayout.horizontalPadding(context),
                  16,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D47C8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: const Color(0xFF2D47C8), size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF607089),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
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
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => _loadDashboard(showLoader: true),
                icon: const Icon(Icons.refresh),
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
    final showTypeDistribution = screenWidth >= 600;
    final horizontalPadding = screenWidth < 390
        ? 12.0
        : (screenWidth < 760 ? 16.0 : 24.0);
    final verticalPadding = screenWidth < 760 ? 16.0 : 20.0;
    final kpiColumns = screenWidth < 1100 ? 2 : 4;
    final kpiAspectRatio = screenWidth < 390
        ? 1.34
        : (screenWidth < 700 ? 1.55 : (screenWidth < 1100 ? 2.0 : 2.2));
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
          24,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                            fontSize: compactHeader ? 16 : 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Vue compacte des indicateurs essentiels.',
                          style: TextStyle(
                            color: Color(0xFF607089),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );

                    final refreshButton = OutlinedButton.icon(
                      onPressed: _refreshing
                          ? null
                          : () => _loadDashboard(showLoader: false),
                      icon: _refreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    );

                    if (compactHeader) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleBlock,
                          const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB42318),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: kpiColumns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
          const SizedBox(height: 12),
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
                const SizedBox(width: 12),
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
            const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2D47C8)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF607089),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2A44),
              fontSize: 11.5,
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
        final compact = constraints.maxWidth < 170;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: color, size: compact ? 18 : 20),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF607089),
                  fontSize: compact ? 11.5 : 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF1F2A44),
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 15.5 : 17,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          helperText,
          style: const TextStyle(
            color: Color(0xFF607089),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 42,
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
        const SizedBox(height: 8),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _compactAmount(values[i]),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
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
      ..strokeWidth = 3;
    canvas.drawPath(line, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF2D47C8);
    final dotStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] / safeMax).clamp(0, 1);
      final y = baseY - (chartHeight * normalized);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
      canvas.drawCircle(Offset(x, y), 4, dotStroke);
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
        final chartSize = math.min(
          172.0,
          math.max(140.0, constraints.maxWidth - 24),
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
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: Color(0xFF607089),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(
                          color: Color(0xFF1F2A44),
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final s in segments)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      '${s.value.toStringAsFixed(0)} (${total == 0 ? 0 : ((s.value / total) * 100).round()}%)',
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
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
    final radius = math.min(size.width, size.height) / 2 - 10;
    const stroke = 20.0;

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

    return Column(
      children: [
        for (var i = 0; i < data.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D47C8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Color(0xFF2D47C8),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${data[i].orders} commande(s)',
                      style: const TextStyle(
                        color: Color(0xFF607089),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                money(data[i].value),
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (i != data.length - 1)
            const Divider(height: 18, color: Color(0xFFE6EAF2)),
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
              final statusPill = Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor(orders[i].statut).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  orders[i].statutDisplay,
                  style: TextStyle(
                    color: statusColor(orders[i].statut),
                    fontSize: 11.5,
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
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${orders[i].client?.fullName ?? 'Client inconnu'} - ${orders[i].dateCommandeFormatted}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF607089),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        statusPill,
                        const Spacer(),
                        Text(
                          money(orders[i].total),
                          style: const TextStyle(
                            color: Color(0xFF1F2A44),
                            fontWeight: FontWeight.w800,
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
                          style: const TextStyle(
                            color: Color(0xFF1F2A44),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${orders[i].client?.fullName ?? 'Client inconnu'} - ${orders[i].dateCommandeFormatted}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF607089),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  statusPill,
                  const SizedBox(width: 10),
                  Text(
                    money(orders[i].total),
                    style: const TextStyle(
                      color: Color(0xFF1F2A44),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
          if (i != orders.length - 1)
            const Divider(height: 18, color: Color(0xFFE6EAF2)),
        ],
      ],
    );
  }
}

/// Petit modele utilitaire qui stocke les donnees de la section de barre laterale.
class _SidebarSection {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final List<_SidebarItem> items;

  const _SidebarSection({required this.title, required this.items});
}

/// Petit modele utilitaire qui stocke les donnees de l'element de barre laterale.
class _SidebarItem {
  // Configuration, dependances et etat local de l'interface.
  final String id;
  final String label;
  final IconData icon;

  const _SidebarItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
