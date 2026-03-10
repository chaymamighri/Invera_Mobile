import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:invera_mobile/config/app_routes.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_clients_section.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_commandes_section.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/commercial_factures_section.dart';

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

  Widget _buildPageContent() {
    if (_activePage == 'dashboard') {
      return const _CommercialAnalyticsDashboard();
    }

    if (_activePage == 'clients') {
      return const CommercialClientsSection();
    }
    if (_activePage == 'commandes') {
      return const CommercialCommandesSection();
    }
    if (_activePage == 'factures') {
      return const CommercialFacturesSection();
    }

    return _buildModulePlaceholder(
      title: _pageTitle(),
      icon: Icons.grid_view_rounded,
    );
  }

  Widget _buildModulePlaceholder({
    required String title,
    required IconData icon,
  }) {
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
                title,
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
                style: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyArea() {
    if (_activePage == 'dashboard' || _activePage == 'factures') {
      return _buildPageContent();
    }

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
          const Text(
            'Commercial',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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
            _openProfile();
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
                  style: TextStyle(color: Colors.blueGrey[600], fontSize: 13),
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
                  Expanded(child: _buildBodyArea()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommercialAnalyticsDashboard extends StatefulWidget {
  const _CommercialAnalyticsDashboard();

  @override
  State<_CommercialAnalyticsDashboard> createState() =>
      _CommercialAnalyticsDashboardState();
}

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

  String _shortDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mn';
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
    final map = <String, int>{};

    for (final client in _clients) {
      final raw = (client.typeClient ?? '').trim().toUpperCase();
      final key = raw.isEmpty ? 'NON DEFINI' : raw;
      map[key] = (map[key] ?? 0) + 1;
    }

    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map((e) => _LabeledIntValue(label: e.key, value: e.value))
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D47C8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2D47C8), size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF607089),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
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
    final isWide = MediaQuery.sizeOf(context).width > 1240;

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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D47C8), Color(0xFF2037A7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332D47C8),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Performance Commerciale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Suivi en temps reel de vos clients, ventes et commandes.',
                            style: TextStyle(color: Color(0xFFD9E4FF)),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _refreshing
                          ? null
                          : () => _loadDashboard(showLoader: false),
                      icon: _refreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniChip(
                      icon: Icons.people_alt_outlined,
                      label: 'Clients actifs',
                      value: '$_activeClientCount',
                    ),
                    _MiniChip(
                      icon: Icons.check_circle_outline,
                      label: 'Taux conversion',
                      value: '${_conversionRate.toStringAsFixed(1)}%',
                    ),
                    _MiniChip(
                      icon: Icons.schedule_outlined,
                      label: 'Derniere sync',
                      value: _lastSync == null ? '-' : _shortDate(_lastSync!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiTile(
                label: 'Clients',
                value: '$_clientsCount',
                delta: 'Portefeuille total',
                icon: Icons.people_outline,
                color: const Color(0xFF0284C7),
              ),
              _KpiTile(
                label: 'Commandes',
                value: '$_ordersCount',
                delta: 'Dossiers suivis',
                icon: Icons.shopping_cart_outlined,
                color: const Color(0xFFEA580C),
              ),
              _KpiTile(
                label: 'CA confirme',
                value: _money(_revenue),
                delta: 'Ventes confirmees',
                icon: Icons.payments_outlined,
                color: const Color(0xFF16A34A),
              ),
              _KpiTile(
                label: 'Panier moyen',
                value: _money(_avgTicket),
                delta: 'Par commande confirmee',
                icon: Icons.trending_up_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _panelCard(
                    title: 'Evolution des ventes',
                    subtitle: '6 derniers mois (commandes confirmees)',
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
                    subtitle: 'Distribution actuelle',
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
              subtitle: '6 derniers mois (commandes confirmees)',
              icon: Icons.show_chart_rounded,
              child: _SalesTrendChart(
                values: salesValues,
                labels: monthlySales.map((m) => _monthLabel(m.month)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _panelCard(
              title: 'Statut des commandes',
              subtitle: 'Distribution actuelle',
              icon: Icons.donut_small_rounded,
              child: _StatusDonutCard(
                segments: statusSegments,
                total: _ordersCount,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _panelCard(
                    title: 'Repartition des clients',
                    subtitle: 'Par type de client',
                    icon: Icons.pie_chart_outline,
                    child: _TypeDistributionBars(data: typeData),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _panelCard(
                    title: 'Top clients',
                    subtitle: 'Classement par chiffre d affaires',
                    icon: Icons.workspace_premium_outlined,
                    child: _TopClientsList(data: topClients, money: _money),
                  ),
                ),
              ],
            )
          else ...[
            _panelCard(
              title: 'Repartition des clients',
              subtitle: 'Par type de client',
              icon: Icons.pie_chart_outline,
              child: _TypeDistributionBars(data: typeData),
            ),
            const SizedBox(height: 12),
            _panelCard(
              title: 'Top clients',
              subtitle: 'Classement par chiffre d affaires',
              icon: Icons.workspace_premium_outlined,
              child: _TopClientsList(data: topClients, money: _money),
            ),
          ],
          const SizedBox(height: 12),
          _panelCard(
            title: 'Commandes recentes',
            subtitle: 'Derniers mouvements sur votre portefeuille',
            icon: Icons.history_toggle_off_rounded,
            child: _RecentOrdersList(
              orders: recentOrders,
              statusColor: _statusColor,
              money: _money,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlySalesPoint {
  final DateTime month;
  final double value;

  const _MonthlySalesPoint({required this.month, required this.value});
}

class _LabeledIntValue {
  final String label;
  final int value;

  const _LabeledIntValue({required this.label, required this.value});
}

class _ClientRevenuePoint {
  final String label;
  final double value;
  final int orders;

  const _ClientRevenuePoint({
    required this.label,
    required this.value,
    required this.orders,
  });
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 240;
        return Container(
          width: compact ? double.infinity : 280,
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF607089),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delta,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const _SalesTrendChart({required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v > 0);
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _SalesTrendPainter(values: values),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hasData
                        ? const Color(0xFF607089)
                        : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  final List<double> values;

  _SalesTrendPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE6EAF2)
      ..strokeWidth = 1;

    const topPadding = 10.0;
    const bottomPadding = 20.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final baseY = topPadding + chartHeight;

    for (var i = 0; i <= 4; i++) {
      final y = topPadding + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) return;

    final maxValue = values.fold<double>(0, math.max);
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

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}

class _DonutSegment {
  final String label;
  final double value;
  final Color color;

  const _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatusDonutCard extends StatelessWidget {
  final List<_DonutSegment> segments;
  final int total;

  const _StatusDonutCard({required this.segments, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(190, 190),
                painter: _DonutPainter(segments: segments),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(color: Color(0xFF607089), fontSize: 12),
                  ),
                  Text(
                    '$total',
                    style: const TextStyle(
                      color: Color(0xFF1F2A44),
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.label,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  s.value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  _DonutPainter({required this.segments});

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

class _TypeDistributionBars extends StatelessWidget {
  final List<_LabeledIntValue> data;

  const _TypeDistributionBars({required this.data});

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

class _TopClientsList extends StatelessWidget {
  final List<_ClientRevenuePoint> data;
  final String Function(double value) money;

  const _TopClientsList({required this.data, required this.money});

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

class _RecentOrdersList extends StatelessWidget {
  final List<CommandeModel> orders;
  final Color Function(String status) statusColor;
  final String Function(double value) money;

  const _RecentOrdersList({
    required this.orders,
    required this.statusColor,
    required this.money,
  });

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
          Row(
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
                      '${orders[i].client?.fullName ?? 'Client inconnu'} • ${orders[i].dateCommandeFormatted}',
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
              Container(
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
              ),
              const SizedBox(width: 10),
              Text(
                money(orders[i].total),
                style: const TextStyle(
                  color: Color(0xFF1F2A44),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (i != orders.length - 1)
            const Divider(height: 18, color: Color(0xFFE6EAF2)),
        ],
      ],
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
