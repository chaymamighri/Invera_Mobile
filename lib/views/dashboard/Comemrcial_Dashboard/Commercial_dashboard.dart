import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_routes.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_clients_section.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_commandes_section.dart';

class CommercialDashboard extends StatefulWidget {
  final User user;

  const CommercialDashboard({super.key, required this.user});

  @override
  State<CommercialDashboard> createState() => _CommercialDashboardState();
}

class _CommercialDashboardState extends State<CommercialDashboard> {
  bool _sidebarCollapsed = false;
  String _activePage = 'dashboard';

  final List<_SidebarSection> _sections = const [
    _SidebarSection(
      title: 'Tableau de bord',
      items: [
        _SidebarItem(id: 'dashboard', label: 'Dashboard', icon: Icons.grid_view_rounded),
      ],
    ),
    _SidebarSection(
      title: 'Gestion commerciale',
      items: [
        _SidebarItem(id: 'clients', label: 'Clients', icon: Icons.people_alt_outlined),
        _SidebarItem(id: 'commandes', label: 'Commandes', icon: Icons.shopping_cart_outlined),
        _SidebarItem(id: 'factures', label: 'Factures', icon: Icons.receipt_long_outlined),
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
      case 'clients':
        return 'Clients';
      case 'commandes':
        return 'Commandes';
      case 'factures':
        return 'Factures';
      default:
        return 'Dashboard';
    }
  }

  String _pageSubtitle() {
    switch (_activePage) {
      case 'clients':
        return 'Gerer votre portefeuille client';
      case 'commandes':
        return 'Suivre les commandes et statuts';
      case 'factures':
        return 'Consulter les factures et paiements';
      default:
        return 'Vue globale de votre activite commerciale';
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrateur';
      case UserRole.RESPONSABLE_ACHAT:
        return 'Responsable achat';
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
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
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

  void _showProfilePlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Page profil non developpee pour le moment.'),
      ),
    );
  }

  Widget _buildPageContent() {
    if (_activePage == 'clients') {
      return const CommercialClientsSection();
    }
    if (_activePage == 'commandes') {
      return const CommercialCommandesSection();
    }

    final icon = switch (_activePage) {
      'commandes' => Icons.shopping_cart_outlined,
      'factures' => Icons.receipt_long_outlined,
      _ => Icons.grid_view_rounded,
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 46, color: const Color(0xFF2D47C8)),
              const SizedBox(height: 14),
              Text(
                _pageTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Module en cours de developpement',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyArea() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _buildPageContent(),
    );
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
          const Text('Commercial', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      actions: _buildTopActions(),
    );
  }

  List<Widget> _buildTopActions() {
    return [
      IconButton(
        tooltip: 'Notifications',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications non disponibles.')),
          );
        },
        icon: const Icon(Icons.notifications_outlined),
      ),
      PopupMenuButton<String>(
        tooltip: 'Menu utilisateur',
        onSelected: (value) {
          if (value == 'profile') {
            _showProfilePlaceholder();
          }
          if (value == 'logout') {
            _confirmLogout();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Text('${widget.user.prenom} ${widget.user.nom}'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text('Deconnexion', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(width: 8),
    ];
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
                  style: TextStyle(
                    color: Colors.blueGrey[600],
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
              border: Border(
                bottom: BorderSide(color: Color(0xFFE6EAF2)),
              ),
            ),
            child: Row(
              children: [
                if (!collapsed) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Commercial',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D47C8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Gestion des ventes',
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
                  onPressed: mobile ? () => Navigator.pop(context) : _toggleSidebar,
                  icon: Icon(mobile ? Icons.close : (collapsed ? Icons.chevron_right : Icons.chevron_left)),
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
                      CircleAvatar(
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
                        onTap: _showProfilePlaceholder,
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

  Widget _buildSidebarItem({required _SidebarItem item, required bool collapsed}) {
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
            mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 20,
                color: isActive ? const Color(0xFF2D47C8) : const Color(0xFF607089),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? const Color(0xFF2D47C8) : const Color(0xFF334155),
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
          width: 300,
          child: _buildSidebar(collapsed: false, mobile: true),
        ),
        body: _buildBodyArea(),
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
                    child: _buildBodyArea(),
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

  const _SidebarItem({required this.id, required this.label, required this.icon});
}
