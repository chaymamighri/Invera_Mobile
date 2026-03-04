import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_routes.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';

class ApprovisionnementDashboard extends StatefulWidget {
  final User user;

  const ApprovisionnementDashboard({super.key, required this.user});

  @override
  State<ApprovisionnementDashboard> createState() => _ApprovisionnementDashboardState();
}

class _ApprovisionnementDashboardState extends State<ApprovisionnementDashboard> {
  bool _sidebarCollapsed = false;

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

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
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
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D47C8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Module en preparation',
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6EAF2)),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      collapsed ? '...' : 'Navigation vide pour le moment',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF607089)),
                    ),
                  ),
                ),
              ),
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
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF2D47C8),
                        child: Text(
                          _initials(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${widget.user.prenom} ${widget.user.nom}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2A44),
                          ),
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

  Widget _buildBodyCard() {
    return Container(
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
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 46, color: Color(0xFF2D47C8)),
          SizedBox(height: 14),
          Text(
            'Dashboard Approvisionnement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2A44),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Module en attente de developpement',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF607089), fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 960;

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2A44),
          title: const Text('Approvisionnement', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, color: Colors.red),
              tooltip: 'Deconnexion',
            ),
          ],
        ),
        drawer: Drawer(
          width: 300,
          child: _buildSidebar(collapsed: false, mobile: true),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBodyCard(),
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
                  Container(
                    height: 84,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      border: const Border(bottom: BorderSide(color: Color(0xFFE6EAF2))),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dashboard Approvisionnement',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2A44),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Configuration initiale en cours',
                                style: TextStyle(color: Color(0xFF607089), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          tooltip: 'Deconnexion',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildBodyCard(),
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
