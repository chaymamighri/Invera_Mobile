import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/services/auth_service.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';

const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _border = Color(0xFFE6EAF2);
const Color _success = Color(0xFF16A34A);
const Color _danger = Color(0xFFDC2626);

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ClientService _clientService = ClientService();
  final CommandeService _commandeService = CommandeService();

  late User _user;
  bool _loading = true;
  bool _refreshing = false;
  String? _warning;
  DateTime? _lastSync;

  int _clientCount = 0;
  int _clientTypeCount = 0;
  List<CommandeModel> _commandes = <CommandeModel>[];

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _reload(showLoader: true);
  }

  Future<T> _safe<T>(Future<T> request, T fallback) async {
    try {
      return await request;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _reload({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _warning = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      await _authService.ready();
      final refreshed = await _authService.fetchCurrentUser();
      if (refreshed && _authService.currentUser != null) {
        _user = _authService.currentUser!;
      }

      if (_user.role == UserRole.COMMERCIAL) {
        final clients = await _safe(
          _clientService.getClients(),
          <ClientModel>[],
        );
        final clientTypes = await _safe(
          _clientService.getClientTypes(),
          <String>[],
        );
        final commandes = await _safe(
          _commandeService.getCommandes(),
          <CommandeModel>[],
        );
        _clientCount = clients.length;
        _clientTypeCount = clientTypes.where((e) => e.trim().isNotEmpty).length;
        _commandes = commandes;
      } else {
        _clientCount = 0;
        _clientTypeCount = 0;
        _commandes = <CommandeModel>[];
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _warning = null;
        _lastSync = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _warning = e.toString().replaceFirst('Exception: ', '');
      });
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
    final full = '${_user.prenom} ${_user.nom}'.trim();
    if (full.isEmpty) return 'US';
    final parts = full.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  int _countStatus(Set<String> statuses) {
    return _commandes
        .where((c) => statuses.contains(c.statut.trim().toUpperCase()))
        .length;
  }

  double get _revenue => _commandes.fold<double>(0, (sum, c) => sum + c.total);
  double get _avgOrder => _commandes.isEmpty ? 0 : _revenue / _commandes.length;
  List<CommandeModel> get _recent {
    final list = List<CommandeModel>.from(_commandes)
      ..sort((a, b) => b.idCommandeClient.compareTo(a.idCommandeClient));
    return list.take(5).toList();
  }

  Color _statusColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'EN_ATTENTE') return const Color(0xFFD97706);
    if (s == 'VALIDEE' || s == 'CONFIRMEE') return _success;
    if (s == 'ANNULEE' || s == 'REJETEE') return _danger;
    return _primary;
  }

  String _money(double v) => '${v.toStringAsFixed(2)} DT';
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: _user.email));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copie'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _passwordInput({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool oldObscure = true;
    bool newObscure = true;
    bool confirmObscure = true;
    bool submitting = false;
    String? serverError;

    await showDialog<void>(
      context: context,
      barrierDismissible: !submitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              setDialogState(() {
                submitting = true;
                serverError = null;
              });

              final result = await _authService.changePassword(
                oldPassword: oldCtrl.text,
                newPassword: newCtrl.text,
              );

              if (!mounted || !dialogContext.mounted) return;
              if (result.success) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: _success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setDialogState(() {
                submitting = false;
                serverError = result.message;
              });
            }

            return AlertDialog(
              title: const Text('Modifier le mot de passe'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _passwordInput(
                        controller: oldCtrl,
                        label: 'Mot de passe actuel',
                        obscure: oldObscure,
                        onToggle: () =>
                            setDialogState(() => oldObscure = !oldObscure),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Mot de passe actuel requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordInput(
                        controller: newCtrl,
                        label: 'Nouveau mot de passe',
                        obscure: newObscure,
                        onToggle: () =>
                            setDialogState(() => newObscure = !newObscure),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) {
                            return 'Nouveau mot de passe requis';
                          }
                          if (value.length < 8) {
                            return 'Minimum 8 caracteres';
                          }
                          if (value == oldCtrl.text) {
                            return 'Doit etre different de l ancien';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordInput(
                        controller: confirmCtrl,
                        label: 'Confirmer le nouveau mot de passe',
                        obscure: confirmObscure,
                        onToggle: () => setDialogState(
                          () => confirmObscure = !confirmObscure,
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return 'Confirmation requise';
                          }
                          if (v != newCtrl.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      if (serverError != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _danger.withValues(alpha: 0.08),
                            border: Border.all(
                              color: _danger.withValues(alpha: 0.22),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            serverError!,
                            style: const TextStyle(
                              color: _danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: submitting ? null : submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: const Text('Mettre a jour'),
                ),
              ],
            );
          },
        );
      },
    );

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  List<Map<String, dynamic>> _capabilities() {
    switch (_user.role) {
      case UserRole.ADMIN:
        return const [
          {
            'icon': Icons.admin_panel_settings_outlined,
            'title': 'Administration globale',
          },
          {'icon': Icons.query_stats_outlined, 'title': 'Pilotage transverse'},
          {
            'icon': Icons.settings_suggest_outlined,
            'title': 'Parametrage avance',
          },
        ];
      case UserRole.RESPONSABLE_ACHAT:
        return const [
          {
            'icon': Icons.inventory_2_outlined,
            'title': 'Pilotage approvisionnement',
          },
          {
            'icon': Icons.fact_check_outlined,
            'title': 'Validation des demandes',
          },
          {'icon': Icons.handshake_outlined, 'title': 'Collaboration metier'},
        ];
      case UserRole.COMMERCIAL:
        return const [
          {
            'icon': Icons.people_alt_outlined,
            'title': 'Gestion portefeuille clients',
          },
          {
            'icon': Icons.shopping_cart_outlined,
            'title': 'Suivi cycle commandes',
          },
          {
            'icon': Icons.insights_outlined,
            'title': 'Analyse performance commerciale',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final metrics = <Map<String, dynamic>>[
      {
        'icon': Icons.badge_outlined,
        'label': 'ID',
        'value': '#${_user.id}',
        'color': _primary,
      },
      {
        'icon': Icons.work_outline,
        'label': 'Role',
        'value': _roleLabel(_user.role),
        'color': const Color(0xFF0EA5E9),
      },
      {
        'icon': _user.active ? Icons.verified_outlined : Icons.block_outlined,
        'label': 'Compte',
        'value': _user.active ? 'Actif' : 'Inactif',
        'color': _user.active ? _success : _danger,
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Derniere sync',
        'value': _lastSync == null ? '-' : _date(_lastSync!),
        'color': const Color(0xFF7C3AED),
      },
      if (_user.role == UserRole.COMMERCIAL) ...[
        {
          'icon': Icons.people_alt_outlined,
          'label': 'Clients',
          'value': '$_clientCount',
          'color': const Color(0xFF0284C7),
        },
        {
          'icon': Icons.category_outlined,
          'label': 'Types',
          'value': '$_clientTypeCount',
          'color': const Color(0xFF9333EA),
        },
        {
          'icon': Icons.shopping_cart_outlined,
          'label': 'Commandes',
          'value': '${_commandes.length}',
          'color': const Color(0xFFEA580C),
        },
        {
          'icon': Icons.hourglass_top_outlined,
          'label': 'En attente',
          'value': '${_countStatus({'EN_ATTENTE'})}',
          'color': const Color(0xFFD97706),
        },
        {
          'icon': Icons.payments_outlined,
          'label': 'CA',
          'value': _money(_revenue),
          'color': _success,
        },
        {
          'icon': Icons.multiline_chart_outlined,
          'label': 'Panier moyen',
          'value': _money(_avgOrder),
          'color': const Color(0xFFDB2777),
        },
      ],
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Profil professionnel',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Modifier mot de passe',
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_reset_outlined),
          ),
          IconButton(
            tooltip: 'Copier email',
            onPressed: _copyEmail,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshing ? null : _reload,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_warning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _danger.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Avertissement: $_warning',
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          _initials(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_user.prenom} ${_user.nom}'.trim().isEmpty
                                  ? _user.email
                                  : '${_user.prenom} ${_user.nom}'.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user.email,
                              style: const TextStyle(color: Color(0xFFE8EDFF)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _heroChip(
                                  Icons.work_outline,
                                  _roleLabel(_user.role),
                                ),
                                _heroChip(
                                  _user.active
                                      ? Icons.verified_user_outlined
                                      : Icons.block_outlined,
                                  _user.active
                                      ? 'Compte actif'
                                      : 'Compte inactif',
                                  color: _user.active ? _success : _danger,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final cardWidth = w >= 1200
                        ? (w - 36) / 4
                        : w >= 900
                        ? (w - 24) / 3
                        : w >= 600
                        ? (w - 12) / 2
                        : w;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: metrics.map((m) {
                        return SizedBox(width: cardWidth, child: _metric(m));
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final mobile = constraints.maxWidth < 960;
                    final left = Column(
                      children: [
                        _panel(
                          'Informations compte',
                          Icons.person_pin_outlined,
                          Column(
                            children: [
                              _infoRow(
                                Icons.badge_outlined,
                                'Identifiant',
                                _user.id.toString(),
                              ),
                              _sep(),
                              _infoRow(
                                Icons.person_outline,
                                'Prenom',
                                _user.prenom,
                              ),
                              _sep(),
                              _infoRow(Icons.person_outline, 'Nom', _user.nom),
                              _sep(),
                              _infoRow(
                                Icons.email_outlined,
                                'Email',
                                _user.email,
                              ),
                              _sep(),
                              _infoRow(
                                Icons.work_outline,
                                'Role',
                                _roleLabel(_user.role),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _panel(
                          'Securite',
                          Icons.security_outlined,
                          Column(
                            children: [
                              _securityRow(
                                'Session',
                                (_authService.token ?? '').trim().isNotEmpty
                                    ? 'Active'
                                    : 'Inactive',
                                (_authService.token ?? '').trim().isNotEmpty
                                    ? _success
                                    : _danger,
                              ),
                              const SizedBox(height: 8),
                              _securityRow(
                                'Derniere sync',
                                _lastSync == null
                                    ? 'Jamais'
                                    : _date(_lastSync!),
                                _primary,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(Icons.lock_reset_outlined),
                                  label: const Text('Modifier mot de passe'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    final right = Column(
                      children: [
                        _panel(
                          'Capacites de role',
                          Icons.workspace_premium_outlined,
                          Column(
                            children: _capabilities().asMap().entries.map((
                              entry,
                            ) {
                              final item = entry.value;
                              final row = Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: _primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              if (entry.key == _capabilities().length - 1) {
                                return row;
                              }
                              return Column(children: [row, _sep()]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _panel(
                          'Activite recente',
                          Icons.timeline_outlined,
                          _user.role != UserRole.COMMERCIAL
                              ? const Text(
                                  'Aucune activite disponible pour ce role',
                                  style: TextStyle(color: _textSecondary),
                                )
                              : (_recent.isEmpty
                                    ? const Text(
                                        'Aucune commande disponible',
                                        style: TextStyle(color: _textSecondary),
                                      )
                                    : Column(
                                        children: _recent.asMap().entries.map((
                                          entry,
                                        ) {
                                          final c = entry.value;
                                          final color = _statusColor(c.statut);
                                          final row = Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.receipt_long_outlined,
                                                color: color,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c.referenceCommandeClient,
                                                      style: const TextStyle(
                                                        color: _textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${c.client?.fullName ?? 'Client'} | ${c.dateCommandeFormatted}',
                                                      style: const TextStyle(
                                                        color: _textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                        alpha: 0.12,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      c.statutDisplay,
                                                      style: TextStyle(
                                                        color: color,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    _money(c.total),
                                                    style: const TextStyle(
                                                      color: _textPrimary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                          if (entry.key == _recent.length - 1) {
                                            return row;
                                          }
                                          return Column(
                                            children: [row, _sep()],
                                          );
                                        }).toList(),
                                      )),
                        ),
                      ],
                    );
                    if (mobile) {
                      return Column(
                        children: [left, const SizedBox(height: 12), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 12),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String text, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(Map<String, dynamic> m) {
    final icon = m['icon'] as IconData;
    final label = m['label'] as String;
    final value = m['value'] as String;
    final color = m['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: _textSecondary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _securityRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: _textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sep() => const Divider(height: 16, color: _border);
}
