import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_routes.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_orders_section.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_overview_section.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_products_section.dart';

class ApprovisionnementDashboard extends StatefulWidget {
  final User user;

  const ApprovisionnementDashboard({super.key, required this.user});

  @override
  State<ApprovisionnementDashboard> createState() =>
      _ApprovisionnementDashboardState();
}

class _ApprovisionnementDashboardState
    extends State<ApprovisionnementDashboard> {
  bool _sidebarCollapsed = false;
  String _activePage = 'stats';

  final List<_SidebarSection> _sections = const [
    _SidebarSection(
      title: 'Tableau de bord',
      items: [
        _SidebarItem(
          id: 'stats',
          label: 'Statistiques',
          icon: Icons.insights_outlined,
        ),
      ],
    ),
    _SidebarSection(
      title: 'Produits',
      items: [
        _SidebarItem(
          id: 'produits',
          label: 'Catalogue produits',
          icon: Icons.inventory_2_outlined,
        ),
      ],
    ),
    _SidebarSection(
      title: 'Approvisionnement',
      items: [
        _SidebarItem(
          id: 'commandes',
          label: 'Bons de commande',
          icon: Icons.shopping_cart_outlined,
        ),
        _SidebarItem(
          id: 'receptions',
          label: 'Receptions',
          icon: Icons.local_shipping_outlined,
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
      case 'commandes':
        return 'Bons de commande fournisseurs';
      case 'receptions':
        return 'Receptions de marchandises';
      default:
        return 'Statistiques achats';
    }
  }

  String _pageSubtitle() {
    switch (_activePage) {
      case 'produits':
        return 'Catalogue, niveaux de stock et activation des articles';
      case 'commandes':
        return 'Creation, validation, envoi, archivage et suivi des commandes';
      case 'receptions':
        return 'Suivi des commandes envoyees et cloture des receptions';
      default:
        return 'Vue globale du module responsable achat';
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

  Widget _buildPageContent() {
    switch (_activePage) {
      case 'produits':
        return const ProcurementProductsSection();
      case 'commandes':
        return ProcurementOrdersSection(
          key: const ValueKey('orders'),
          receptionMode: false,
          onSwitchToReceptions: () => _setActivePage('receptions'),
        );
      case 'receptions':
        return const ProcurementOrdersSection(
          key: ValueKey('receptions'),
          receptionMode: true,
        );
      default:
        return const ProcurementOverviewSection();
    }
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F2A44),
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 4),
          Image.asset(
            'assets/images/logo.png',
            width: 26,
            height: 26,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.business),
          ),
          const SizedBox(width: 8),
          const Text(
            'Approvisionnement',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: _buildTopActions(),
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(bottom: BorderSide(color: Color(0xFFE6EAF2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pageTitle(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2A44),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _pageSubtitle(),
                  style: const TextStyle(
                    color: Color(0xFF607089),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ..._buildTopActions(),
        ],
      ),
    );
  }

  Widget _buildSidebar({required bool collapsed, required bool mobile}) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 12, 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE6EAF2))),
            ),
            child: Row(
              children: [
                if (!collapsed) ...[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approvisionnement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D47C8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Produits, commandes et receptions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF607089),
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
                          color: Color(0xFF8A98AD),
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
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6EAF2)),
            ),
            child: collapsed
                ? Column(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF2D47C8),
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
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      GestureDetector(
                        onTap: _openProfile,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF2D47C8),
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
                                color: Color(0xFF1F2A44),
                              ),
                            ),
                            Text(
                              _roleLabel(widget.user.role),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF607089),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Deconnexion',
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required _SidebarItem item,
    required bool collapsed,
  }) {
    final isActive = _activePage == item.id;

    final itemWidget = Material(
      color: isActive ? const Color(0xFFEFF4FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _setActivePage(item.id),
        child: Container(
          height: 46,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFFBFD1FF) : Colors.transparent,
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
                color: isActive
                    ? const Color(0xFF2D47C8)
                    : const Color(0xFF607089),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF2D47C8)
                          : const Color(0xFF334155),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: _buildMobileAppBar(),
        drawer: Drawer(
          width: AdaptiveLayout.drawerWidth(context, max: 304, ratio: 0.88),
          child: _buildSidebar(collapsed: false, mobile: true),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AdaptiveLayout.horizontalPadding(context)),
          child: _buildPageContent(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: _sidebarCollapsed ? 92 : 284,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFE6EAF2))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 12,
                    offset: Offset(1, 0),
                  ),
                ],
              ),
              child: _buildSidebar(collapsed: _sidebarCollapsed, mobile: false),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildPageContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarSection {
  final String title;
  final List<_SidebarItem> items;

  const _SidebarSection({required this.title, required this.items});
}

class _SidebarItem {
  final String id;
  final String label;
  final IconData icon;

  const _SidebarItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
