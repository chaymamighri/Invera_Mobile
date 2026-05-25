import 'package:flutter/material.dart';
import 'package:invera_mobile/config/routes.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/utilisateur.dart';
import 'package:invera_mobile/services/authentification.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/categories.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commandes.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/produits.dart';
import 'package:invera_mobile/widgets/approvisionnement/sidebar.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _achatPrimary = Color(0xFF2553D4);
const Color _achatTeal = Color(0xFF14B8A6);
const Color _achatInk = Color(0xFF10203A);
const Color _achatMuted = Color(0xFF607089);

/// Widget qui affiche le tableau de bord d'approvisionnement.
class ApprovisionnementDashboard extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final User user;

  const ApprovisionnementDashboard({super.key, required this.user});

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ApprovisionnementDashboard> createState() =>
      _ApprovisionnementDashboardState();
}

/// Classe utilitaire pour l'etat du tableau de bord d'approvisionnement.
class _ApprovisionnementDashboardState
    extends State<ApprovisionnementDashboard> {
  bool _sidebarCollapsed = false;
  String _activePage = 'produits';

  final List<ApprovisionnementSidebarSection> _sections = const [
    ApprovisionnementSidebarSection(
      title: 'Produits',
      items: [
        ApprovisionnementSidebarItem(
          id: 'produits',
          label: 'Catalogue produits',
          icon: Icons.inventory_2_outlined,
        ),
        ApprovisionnementSidebarItem(
          id: 'categories',
          label: 'Categories produits',
          icon: Icons.category_outlined,
        ),
      ],
    ),
    ApprovisionnementSidebarSection(
      title: 'Approvisionnement',
      items: [
        ApprovisionnementSidebarItem(
          id: 'commandes',
          label: 'Bons de commande',
          icon: Icons.shopping_cart_outlined,
        ),
      ],
    ),
  ];

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  void _setActivePage(String pageId) {
    setState(() {
      _activePage = pageId;
    });
  }

  String _pageTitle() {
    switch (_activePage) {
      case 'produits':
        return 'Gestion des produits';
      case 'categories':
        return 'Gestion des categories';
      case 'commandes':
        return 'Bons de commande fournisseurs';
      default:
        return 'Gestion des produits';
    }
  }

  String _pageSubtitle() {
    switch (_activePage) {
      case 'produits':
        return 'Catalogue, niveaux de stock et activation des articles';
      case 'categories':
        return 'Interface dediee aux categories et a leur TVA';
      case 'commandes':
        return 'Creation, validation, envoi, archivage et suivi des commandes';
      default:
        return 'Catalogue, niveaux de stock et activation des articles';
    }
  }

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

  void _openProfile() {
    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'user': widget.user},
    );
  }

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
    ];
  }

  ThemeData _moduleTheme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: _achatPrimary,
      primary: _achatPrimary,
      secondary: _achatTeal,
      surface: Colors.white,
    );

    OutlineInputBorder border(Color color, {double width = 1.2}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _achatInk,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _achatInk,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: _achatMuted),
        hintStyle: const TextStyle(color: Color(0xFF91A0B5)),
        border: border(const Color(0xFFDCE5F3)),
        enabledBorder: border(const Color(0xFFDCE5F3)),
        focusedBorder: border(_achatPrimary, width: 1.6),
        errorBorder: border(const Color(0xFFDC2626)),
        focusedErrorBorder: border(const Color(0xFFDC2626), width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _achatPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _achatInk,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          side: const BorderSide(color: Color(0xFFD8E2F2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _achatPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

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
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x30FFFFFF)),
            ),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

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
                    _achatPrimary.withValues(alpha: 0.16),
                    _achatPrimary.withValues(alpha: 0),
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
                    _achatTeal.withValues(alpha: 0.14),
                    _achatTeal.withValues(alpha: 0),
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

  Widget _buildPageContent() {
    switch (_activePage) {
      case 'produits':
        return const ProcurementProductsSection();
      case 'categories':
        return const ProcurementCategoriesSection();
      case 'commandes':
        return const ProcurementOrdersSection(key: ValueKey('orders'));
      default:
        return const ProcurementProductsSection();
    }
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.72),
      foregroundColor: _achatInk,
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
                  _achatPrimary.withValues(alpha: 0.14),
                  _achatTeal.withValues(alpha: 0.10),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Approvisionnement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              Text(
                'Dashboard achat',
                style: TextStyle(fontSize: 11.5, color: _achatMuted),
              ),
            ],
          ),
        ],
      ),
      actions: _buildTopActions(),
    );
  }

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
                          'Flux achats | design studio',
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

  Widget _buildCompactPageIntro() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C1934), Color(0xFF163985), Color(0xFF177A99)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Experience achat premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _pageTitle(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pageSubtitle(),
            style: const TextStyle(
              color: Color(0xD7F8FAFC),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool collapsed, required bool mobile}) {
    return ApprovisionnementSidebar(
      user: widget.user,
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  AdaptiveLayout.horizontalPadding(context),
                ),
                child: Column(
                  children: [
                    _buildCompactPageIntro(),
                    _buildAnimatedPageContent(),
                  ],
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
                          child: SingleChildScrollView(
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

