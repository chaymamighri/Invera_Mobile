import 'package:flutter/material.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/models/facture_model.dart';
import 'package:invera_mobile/services/commande_service.dart';
import 'package:invera_mobile/services/facture_service.dart';

enum _FacturePeriod { day, week, month, year }

const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _accent = Color(0xFF0CAE4A);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _borderLight = Color(0xFFE6EAF2);
const Color _success = Color(0xFF0CAE4A);
const Color _error = Color(0xFFB42318);
const double _baseUnit = 8.0;

class CommercialFacturesSection extends StatefulWidget {
  const CommercialFacturesSection({super.key});

  @override
  State<CommercialFacturesSection> createState() =>
      _CommercialFacturesSectionState();
}

class _CommercialFacturesSectionState extends State<CommercialFacturesSection> {
  static const Set<String> _confirmedStatuses = {'CONFIRMEE', 'VALIDEE'};

  final CommandeService _commandeService = CommandeService();
  final FactureService _factureService = FactureService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _refreshing = false;
  bool _generating = false;
  bool _showOnlyPending = true;
  String? _error;

  List<CommandeModel> _confirmedCommandes = <CommandeModel>[];
  final Map<int, FactureModel> _facturesByCommandeId = <int, FactureModel>{};
  final Set<int> _selectedCommandeIds = <int>{};
  _FacturePeriod _period = _FacturePeriod.month;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData(showLoader: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({required bool showLoader}) async {
    setState(() {
      if (showLoader) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
    });

    try {
      final commandes = await _commandeService.getCommandes();
      final confirmed = _sortCommandesByCreation(
        commandes.where((cmd) {
          return _confirmedStatuses.contains(cmd.statut.trim().toUpperCase());
        }).toList(),
      );

      final facturesByCommande = <int, FactureModel>{};
      try {
        final factures = await _factureService.getAllFactures();
        for (final facture in factures) {
          final cmdId = facture.commandeId;
          if (cmdId != null) {
            facturesByCommande[cmdId] = facture;
          }
        }
      } catch (_) {
        if (mounted) {
          _showMessage(
            'Factures API warning: impossible de charger les factures existantes. Les commandes restent chargees.',
            isError: true,
          );
        }
      }

      if (!mounted) return;

      final availableIds = confirmed.map((e) => e.idCommandeClient).toSet();

      setState(() {
        _confirmedCommandes = confirmed;
        _facturesByCommandeId
          ..clear()
          ..addAll(facturesByCommande);
        _selectedCommandeIds.removeWhere((id) => !availableIds.contains(id));
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<CommandeModel> _sortCommandesByCreation(List<CommandeModel> commandes) {
    final sorted = List<CommandeModel>.from(commandes);
    sorted.sort((a, b) {
      final ad = _parseCommandeCreationDate(a);
      final bd = _parseCommandeCreationDate(b);

      if (ad != null && bd != null) {
        final cmp = bd.compareTo(ad);
        if (cmp != 0) return cmp;
      } else if (ad == null && bd != null) {
        return 1;
      } else if (ad != null && bd == null) {
        return -1;
      }

      return b.idCommandeClient.compareTo(a.idCommandeClient);
    });
    return sorted;
  }

  DateTime? _parseCommandeCreationDate(CommandeModel cmd) {
    final raw = cmd.dateCommande.trim();
    if (raw.isNotEmpty) {
      final parsedRaw = DateTime.tryParse(raw);
      if (parsedRaw != null) return parsedRaw;
    }

    final formatted = cmd.dateCommandeFormatted.trim();
    if (formatted.isEmpty || formatted == '-') return null;

    final parsedFormatted = DateTime.tryParse(formatted);
    if (parsedFormatted != null) return parsedFormatted;

    final normalized = formatted.replaceFirst(' ', 'T');
    final parsedNormalized = DateTime.tryParse(normalized);
    if (parsedNormalized != null) return parsedNormalized;

    final match = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(formatted);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day, hour, minute, second);
  }

  DateTime? _parseCommandeDate(CommandeModel cmd) {
    final parsed = _parseCommandeCreationDate(cmd);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  bool _belongsToPeriod(CommandeModel cmd, _FacturePeriod period) {
    final date = _parseCommandeDate(cmd);
    if (date == null) return false;

    final today = _dayOnly(DateTime.now());
    final order = _dayOnly(date);

    switch (period) {
      case _FacturePeriod.day:
        return order == today;
      case _FacturePeriod.week:
        final weekStart = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        return !order.isBefore(weekStart) && !order.isAfter(weekEnd);
      case _FacturePeriod.month:
        return order.year == today.year && order.month == today.month;
      case _FacturePeriod.year:
        return order.year == today.year;
    }
  }

  bool _isInvoiced(int commandeId) {
    return _facturesByCommandeId.containsKey(commandeId);
  }

  List<CommandeModel> get _pendingCommandes {
    return _confirmedCommandes
        .where((cmd) => !_isInvoiced(cmd.idCommandeClient))
        .toList();
  }

  List<CommandeModel> get _visibleCommandes {
    final query = _searchQuery.trim().toLowerCase();
    final base = _showOnlyPending ? _pendingCommandes : _confirmedCommandes;
    if (query.isEmpty) return base;

    return base.where((cmd) {
      final ref = cmd.referenceCommandeClient.toLowerCase();
      final client = (cmd.client?.fullName ?? '').toLowerCase();
      final date = cmd.dateCommandeFormatted.toLowerCase();
      return ref.contains(query) ||
          client.contains(query) ||
          date.contains(query);
    }).toList();
  }

  List<CommandeModel> get _selectedCommandes {
    return _confirmedCommandes
        .where((cmd) => _selectedCommandeIds.contains(cmd.idCommandeClient))
        .toList();
  }

  List<CommandeModel> get _periodCandidates {
    return _pendingCommandes
        .where((cmd) => _belongsToPeriod(cmd, _period))
        .toList();
  }

  String _periodLabel(_FacturePeriod value) {
    switch (value) {
      case _FacturePeriod.day:
        return 'Jour';
      case _FacturePeriod.week:
        return 'Semaine';
      case _FacturePeriod.month:
        return 'Mois';
      case _FacturePeriod.year:
        return 'Annee';
    }
  }

  double _sumTotal(List<CommandeModel> items) {
    return items.fold<double>(0, (sum, e) => sum + e.total);
  }

  String _formatAmount(double value) => '${value.toStringAsFixed(2)} DT';

  String _displayStatus(String raw) {
    final norm = raw.trim().toUpperCase();
    if (norm == 'EN_ATTENTE') return 'En attente';
    if (norm == 'CONFIRMEE' || norm == 'VALIDEE') return 'Confirmee';
    if (norm == 'ANNULEE' || norm == 'REJETEE') return 'Annulee';
    return raw;
  }

  String _buildProductsPreview(CommandeModel cmd) {
    if (cmd.produits.isEmpty) return 'Aucun produit';
    final names = cmd.produits.map((p) => p.libelle).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names[0]} + ${names[1]} + ${names.length - 2} autres';
  }

  String _buildCommandeSubtotal(CommandeModel cmd) {
    final subtotal = cmd.produits.fold<double>(
      0,
      (sum, p) => sum + p.sousTotal,
    );
    return '${subtotal.toStringAsFixed(2)} DT';
  }

  void _toggleSelectAllVisible(bool selected, List<CommandeModel> visible) {
    setState(() {
      final allowed = visible.where((e) => !_isInvoiced(e.idCommandeClient));
      if (selected) {
        _selectedCommandeIds.addAll(allowed.map((e) => e.idCommandeClient));
      } else {
        for (final cmd in allowed) {
          _selectedCommandeIds.remove(cmd.idCommandeClient);
        }
      }
    });
  }

  Future<void> _generateSelected() async {
    final targets = _selectedCommandes
        .where((cmd) => !_isInvoiced(cmd.idCommandeClient))
        .toList();

    if (targets.isEmpty) {
      _showMessage(
        'Selectionnez au moins une commande non facturee.',
        isError: true,
      );
      return;
    }

    await _generateMany(targets, title: 'Facturation de la selection');
  }

  Future<void> _generateFromPeriod() async {
    final targets = _periodCandidates;
    if (targets.isEmpty) {
      _showMessage(
        'Aucune commande confirmee pour ${_periodLabel(_period).toLowerCase()}.',
        isError: true,
      );
      return;
    }

    await _generateMany(
      targets,
      title: 'Period generation (${_periodLabel(_period).toLowerCase()})',
    );
  }

  Future<void> _generateMany(
    List<CommandeModel> commandes, {
    required String title,
  }) async {
    setState(() => _generating = true);

    final created = <FactureModel>[];
    final failed = <_GenerationFailure>[];

    for (final cmd in commandes) {
      try {
        final existing = await _factureService.getFactureByCommandeId(
          cmd.idCommandeClient,
        );
        if (existing != null) {
          created.add(existing);
          continue;
        }
      } catch (e) {
        if (_isAuthError(e.toString())) {
          failed.add(
            _GenerationFailure(
              referenceCommande: cmd.referenceCommandeClient,
              message: e.toString(),
            ),
          );
          continue;
        }
      }

      try {
        final facture = await _factureService.generateFromCommande(
          cmd.idCommandeClient,
        );
        created.add(facture);
      } catch (e) {
        failed.add(
          _GenerationFailure(
            referenceCommande: cmd.referenceCommandeClient,
            message: e.toString(),
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      for (final facture in created) {
        final cmdId = facture.commandeId;
        if (cmdId != null) {
          _facturesByCommandeId[cmdId] = facture;
          _selectedCommandeIds.remove(cmdId);
        }
      }
      _generating = false;
    });

    await _showGenerationResult(title: title, created: created, failed: failed);
  }

  bool _isAuthError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('acces refuse') ||
        normalized.contains('access denied');
  }

  Future<void> _showGenerationResult({
    required String title,
    required List<FactureModel> created,
    required List<_GenerationFailure> failed,
  }) async {
    final createdTotal = created.fold<double>(
      0,
      (sum, e) => sum + e.montantTotal,
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Created: ${created.length}'),
                  Text('Failed: ${failed.length}'),
                  const SizedBox(height: 6),
                  Text('Saved total: ${_formatAmount(createdTotal)}'),
                  if (created.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Saved invoices',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    ...created
                        .take(8)
                        .map(
                          (f) => Text(
                            '- ${f.referenceFactureClient} (${_formatAmount(f.montantTotal)})',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                  ],
                  if (failed.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Errors',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...failed
                        .take(5)
                        .map(
                          (f) => Text(
                            '- ${f.referenceCommande}: ${f.message}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    if (created.isEmpty &&
                        failed.any((f) => _isAuthError(f.message))) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Backend rejected invoice generation (401/403). Check backend role/permissions for /api/factures/generer/{commandeId}.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showCommandeDetails(CommandeModel cmd) {
    final facture = _facturesByCommandeId[cmd.idCommandeClient];
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final client = cmd.client;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 1000,
            constraints: const BoxConstraints(maxHeight: 760),
            padding: EdgeInsets.all(_baseUnit * 3),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: _baseUnit * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details de la commande',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cmd.referenceCommandeClient,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(cmd.statut),
                    const SizedBox(width: _baseUnit),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: _baseUnit * 2),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 860;

                      final leftPanel = SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailsSection(
                              title: 'Informations generales',
                              child: Wrap(
                                spacing: _baseUnit,
                                runSpacing: _baseUnit,
                                children: [
                                  _buildDetailInfoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Date',
                                    value: cmd.dateCommandeFormatted,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Client',
                                    value: client?.fullName ?? '-',
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.local_offer_outlined,
                                    label: 'Reference',
                                    value: cmd.referenceCommandeClient,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.percent_outlined,
                                    label: 'Remise',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Coordonnees client',
                              child: Column(
                                children: [
                                  _buildCommandeDetailRow(
                                    icon: Icons.person_outline,
                                    label: 'Nom complet',
                                    value: client?.fullName ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Telephone',
                                    value: client?.telephone ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: client?.email ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Adresse',
                                    value: client?.adresse ?? '-',
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Produits commandes',
                              child: Column(
                                children: [
                                  if (cmd.produits.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(_baseUnit * 2),
                                      decoration: BoxDecoration(
                                        color: _background,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _borderLight),
                                      ),
                                      child: const Text(
                                        'Aucun produit dans cette commande.',
                                        style: TextStyle(color: _textSecondary),
                                      ),
                                    )
                                  else
                                    ...cmd.produits.asMap().entries.map((
                                      entry,
                                    ) {
                                      return _buildProduitDetailCard(
                                        index: entry.key + 1,
                                        produit: entry.value,
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      final rightPanel = SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailsSection(
                              title: 'Resume financier',
                              child: Column(
                                children: [
                                  _buildSummaryTile(
                                    label: 'Nombre de lignes',
                                    value: '${cmd.produits.length}',
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Statut',
                                    value: _displayStatus(cmd.statut),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Remise appliquee',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  const Divider(color: _borderLight),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  _buildAmountRow(
                                    'Sous-total estime',
                                    _buildCommandeSubtotal(cmd),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildAmountRow(
                                    'Total final',
                                    '${cmd.total.toStringAsFixed(2)} DT',
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ),
                            if (facture != null) ...[
                              const SizedBox(height: _baseUnit * 2),
                              _buildDetailsSection(
                                title: 'Facture enregistree',
                                child: Column(
                                  children: [
                                    _buildSummaryTile(
                                      label: 'Reference',
                                      value: facture.referenceFactureClient,
                                    ),
                                    const SizedBox(height: _baseUnit),
                                    _buildSummaryTile(
                                      label: 'Statut facture',
                                      value: facture.statut,
                                    ),
                                    const SizedBox(height: _baseUnit),
                                    _buildSummaryTile(
                                      label: 'Montant',
                                      value: _formatAmount(
                                        facture.montantTotal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            Expanded(child: leftPanel),
                            const SizedBox(height: _baseUnit * 2),
                            Expanded(child: rightPanel),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: leftPanel),
                          const SizedBox(width: _baseUnit * 2),
                          Expanded(flex: 2, child: rightPanel),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: _baseUnit * 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!_isInvoiced(cmd.idCommandeClient))
                      ElevatedButton.icon(
                        onPressed: _generating
                            ? null
                            : () {
                                Navigator.of(ctx, rootNavigator: true).pop();
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;
                                  _generateMany(
                                    <CommandeModel>[cmd],
                                    title:
                                        'Commande ${cmd.referenceCommandeClient}',
                                  );
                                });
                              },
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Generer facture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (!_isInvoiced(cmd.idCommandeClient))
                      const SizedBox(width: _baseUnit),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    final normalized = status.trim().toUpperCase();
    late Color bg;
    late Color fg;

    if (normalized == 'CONFIRMEE' || normalized == 'VALIDEE') {
      bg = const Color(0xFFE9F8EF);
      fg = const Color(0xFF11853F);
    } else if (normalized == 'ANNULEE' || normalized == 'REJETEE') {
      bg = const Color(0xFFFFE8E8);
      fg = const Color(0xFFB42318);
    } else {
      bg = const Color(0xFFEFF4FF);
      fg = _primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.25,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: _baseUnit * 1.5),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: EdgeInsets.all(_baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderLight),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          const SizedBox(width: _baseUnit),
          Flexible(
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
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandeDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : _baseUnit),
      padding: EdgeInsets.all(_baseUnit * 1.25),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: _baseUnit),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduitDetailCard({
    required int index,
    required CommandeProduitDetail produit,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _baseUnit * 1.25),
      padding: EdgeInsets.all(_baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderLight),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(width: _baseUnit),
              Expanded(
                child: Text(
                  produit.libelle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                '${produit.sousTotal.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  color: _primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: _baseUnit * 1.25),
          Wrap(
            spacing: _baseUnit,
            runSpacing: _baseUnit,
            children: [
              _buildBadge(
                'Quantite: ${produit.quantite}',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
              _buildBadge(
                'Prix: ${produit.prixUnitaire.toStringAsFixed(2)} DT',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
              _buildBadge(
                'Sous-total: ${produit.sousTotal.toStringAsFixed(2)} DT',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit * 1.3,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isPrimary = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? _textPrimary : _textSecondary,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              fontSize: isPrimary ? 15 : 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? _accent : _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: isPrimary ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF607089),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  Widget _buildBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCountPill(int count, {bool onDark = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.28)
              : _primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$count commandes',
        style: TextStyle(
          color: onDark ? Colors.white : _primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildHeader({
    required List<CommandeModel> visible,
    required List<CommandeModel> selected,
    required int pending,
  }) {
    final selectableVisible = visible
        .where((e) => !_isInvoiced(e.idCommandeClient))
        .toList();
    final allSelected =
        selectableVisible.isNotEmpty &&
        selectableVisible.every(
          (e) => _selectedCommandeIds.contains(e.idCommandeClient),
        );

    final selectAllToggle = Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit,
        vertical: _baseUnit / 2,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: allSelected,
            visualDensity: VisualDensity.compact,
            onChanged: selectableVisible.isEmpty
                ? null
                : (v) => _toggleSelectAllVisible(v ?? false, visible),
          ),
          Text(
            'Tout selectionner (${selectableVisible.length})',
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    final periodChips = Wrap(
      spacing: _baseUnit,
      runSpacing: _baseUnit,
      children: _FacturePeriod.values.map((p) {
        final selectedPeriod = _period == p;
        return ChoiceChip(
          label: Text(_periodLabel(p)),
          selected: selectedPeriod,
          selectedColor: _primary.withValues(alpha: 0.16),
          backgroundColor: _surface,
          side: BorderSide(color: selectedPeriod ? _primary : _borderLight),
          labelStyle: TextStyle(
            color: selectedPeriod ? _primaryDark : _textPrimary,
            fontWeight: selectedPeriod ? FontWeight.w700 : FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _period = p),
        );
      }).toList(),
    );

    final scopeChips = Wrap(
      spacing: _baseUnit,
      runSpacing: _baseUnit,
      children: [
        ChoiceChip(
          label: const Text('Non facturees'),
          selected: _showOnlyPending,
          selectedColor: _primary.withValues(alpha: 0.16),
          backgroundColor: _surface,
          side: BorderSide(color: _showOnlyPending ? _primary : _borderLight),
          labelStyle: TextStyle(
            color: _showOnlyPending ? _primaryDark : _textPrimary,
            fontWeight: _showOnlyPending ? FontWeight.w700 : FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _showOnlyPending = true),
        ),
        ChoiceChip(
          label: const Text('Toutes confirmees'),
          selected: !_showOnlyPending,
          selectedColor: _primary.withValues(alpha: 0.16),
          backgroundColor: _surface,
          side: BorderSide(color: !_showOnlyPending ? _primary : _borderLight),
          labelStyle: TextStyle(
            color: !_showOnlyPending ? _primaryDark : _textPrimary,
            fontWeight: !_showOnlyPending ? FontWeight.w700 : FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _showOnlyPending = false),
        ),
      ],
    );

    final refreshButton = OutlinedButton.icon(
      onPressed: _refreshing ? null : () => _loadData(showLoader: false),
      icon: _refreshing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
      label: const Text('Actualiser'),
    );

    final generatePeriodButton = OutlinedButton.icon(
      onPressed: _generating ? null : _generateFromPeriod,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text(
        'Generer ${_periodLabel(_period).toLowerCase()} (${_periodCandidates.length})',
      ),
    );

    final generateSelectionButton = ElevatedButton.icon(
      onPressed: _generating || selected.isEmpty ? null : _generateSelected,
      icon: _generating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.description_outlined),
      label: const Text('Generer la selection'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(_baseUnit * 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3A2D47C8),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commandes pour facturation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Commandes confirmees pretes a etre facturees dans une interface unifiee.',
                    style: TextStyle(color: Color(0xFFE3EBFF), fontSize: 13),
                  ),
                  const SizedBox(height: _baseUnit * 1.5),
                  Wrap(
                    spacing: _baseUnit,
                    runSpacing: _baseUnit,
                    children: [
                      _buildBadge(
                        '$pending non facturees',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                      _buildBadge(
                        '${selected.length} selectionnees',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                      _buildBadge(
                        'Total: ${_formatAmount(_sumTotal(selected))}',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
                ],
              );

              final counter = _buildCountPill(
                _confirmedCommandes.length,
                onDark: true,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: _baseUnit * 1.5),
                    counter,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: _baseUnit * 2),
                  counter,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: _baseUnit * 1.5),
        Container(
          padding: EdgeInsets.all(_baseUnit * 2),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 920;
              final searchField = TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Rechercher ref / client / date',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: _background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtres & Actions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: _baseUnit),
                    searchField,
                    const SizedBox(height: _baseUnit),
                    scopeChips,
                    const SizedBox(height: _baseUnit),
                    periodChips,
                    const SizedBox(height: _baseUnit),
                    selectAllToggle,
                    const SizedBox(height: _baseUnit * 1.5),
                    Wrap(
                      spacing: _baseUnit,
                      runSpacing: _baseUnit,
                      children: [
                        refreshButton,
                        generatePeriodButton,
                        generateSelectionButton,
                      ],
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filtres & Actions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      refreshButton,
                      const SizedBox(width: _baseUnit),
                      generatePeriodButton,
                      const SizedBox(width: _baseUnit),
                      generateSelectionButton,
                    ],
                  ),
                  const SizedBox(height: _baseUnit * 1.5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: _baseUnit),
                      selectAllToggle,
                    ],
                  ),
                  const SizedBox(height: _baseUnit),
                  scopeChips,
                  const SizedBox(height: _baseUnit),
                  periodChips,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersPanel(List<CommandeModel> visible) {
    if (visible.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: const Center(
          child: Text('Aucune commande ne correspond aux filtres actifs.'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCommandeCard(visible[index]),
      ),
    );
  }

  Widget _buildCommandeCard(CommandeModel cmd) {
    final invoiced = _isInvoiced(cmd.idCommandeClient);
    final facture = _facturesByCommandeId[cmd.idCommandeClient];
    final selected = _selectedCommandeIds.contains(cmd.idCommandeClient);

    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF4F7FF) : _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? const Color(0xFFBBC9FF) : _borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCommandeDetails(cmd),
          child: Padding(
            padding: EdgeInsets.all(_baseUnit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: selected,
                      onChanged: invoiced
                          ? null
                          : (v) {
                              setState(() {
                                if (v ?? false) {
                                  _selectedCommandeIds.add(
                                    cmd.idCommandeClient,
                                  );
                                } else {
                                  _selectedCommandeIds.remove(
                                    cmd.idCommandeClient,
                                  );
                                }
                              });
                            },
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: _baseUnit * 1.25),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cmd.referenceCommandeClient,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cmd.dateCommandeFormatted,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: _baseUnit),
                    _buildStatusChip(cmd.statut),
                  ],
                ),
                const SizedBox(height: _baseUnit * 1.5),
                Wrap(
                  spacing: _baseUnit,
                  runSpacing: _baseUnit,
                  children: [
                    _buildMetaTile(
                      icon: Icons.person_outline,
                      label: 'Client',
                      value: cmd.client?.fullName ?? '-',
                    ),
                    _buildMetaTile(
                      icon: Icons.payments_outlined,
                      label: 'Total',
                      value: _formatAmount(cmd.total),
                    ),
                    _buildMetaTile(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Lignes',
                      value: '${cmd.produits.length}',
                    ),
                  ],
                ),
                const SizedBox(height: _baseUnit * 1.5),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: _baseUnit * 1.25,
                    vertical: _baseUnit,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildProductsPreview(cmd),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _baseUnit * 1.5),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: _baseUnit,
                  runSpacing: _baseUnit,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showCommandeDetails(cmd),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Details'),
                    ),
                    if (invoiced)
                      OutlinedButton.icon(
                        onPressed: () => _showCommandeDetails(cmd),
                        icon: const Icon(Icons.description_outlined),
                        label: Text(
                          'Facture: ${facture?.referenceFactureClient ?? 'OK'}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryDark,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _generating
                            ? null
                            : () => _generateMany(
                                <CommandeModel>[cmd],
                                title:
                                    'Commande ${cmd.referenceCommandeClient}',
                              ),
                        icon: _generating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.description_outlined),
                        label: const Text('Generer facture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewPanel(List<CommandeModel> selected) {
    final total = _sumTotal(selected);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apercu du brouillon facture',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2A44),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le backend enregistre actuellement une facture par commande.',
              style: TextStyle(color: Color(0xFF607089), fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Commandes selectionnees', '${selected.length}'),
            _buildDetailRow('Total brouillon', _formatAmount(total)),
            _buildDetailRow(
              'Candidats periode',
              '${_periodCandidates.length} (${_periodLabel(_period).toLowerCase()})',
            ),
            const SizedBox(height: 10),
            const Text(
              'References selectionnees',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: selected.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune commande selectionnee.',
                        style: TextStyle(color: Color(0xFF607089)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: selected.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final cmd = selected[index];
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6EAF2)),
                          ),
                          child: Text(
                            '${cmd.referenceCommandeClient} - ${_formatAmount(cmd.total)}',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadData(showLoader: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final visible = _visibleCommandes;
    final selected = _selectedCommandes;
    final pending = _pendingCommandes.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1120;

        return Padding(
          padding: EdgeInsets.all(compact ? 12 : 18),
          child: Column(
            children: [
              _buildHeader(
                visible: visible,
                selected: selected,
                pending: pending,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: compact
                    ? Column(
                        children: [
                          SizedBox(
                            height: 230,
                            child: _buildPreviewPanel(selected),
                          ),
                          const SizedBox(height: 12),
                          Expanded(child: _buildOrdersPanel(visible)),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildOrdersPanel(visible)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 380,
                            child: _buildPreviewPanel(selected),
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

class _GenerationFailure {
  final String referenceCommande;
  final String message;

  _GenerationFailure({required this.referenceCommande, required this.message});
}
