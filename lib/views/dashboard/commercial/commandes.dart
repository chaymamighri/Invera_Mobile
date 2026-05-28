import 'package:flutter/material.dart';
import 'package:invera_mobile/config/globals.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/client.dart';
import 'package:invera_mobile/models/commande.dart';
import 'package:invera_mobile/services/clients.dart';
import 'package:invera_mobile/services/commandes.dart';

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

class _StatusChip extends StatelessWidget {
  final String status;
  final bool compact;

  const _StatusChip({required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    late Color bg;
    late Color fg;

    if (normalized == 'CONFIRMEE') {
      bg = const Color(0xFFE9F8EF);
      fg = const Color(0xFF11853F);
    } else if (normalized == 'ANNULEE') {
      bg = const Color(0xFFFFE8E8);
      fg = const Color(0xFFB42318);
    } else {
      bg = const Color(0xFFEFF4FF);
      fg = _primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? _baseUnit * 1.2 : _baseUnit * 1.5,
        vertical: compact ? _baseUnit * 0.7 : _baseUnit,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }

  String _displayStatus(String raw) {
    final norm = raw.trim().toUpperCase();
    if (norm == 'EN_ATTENTE') return 'En attente';
    if (norm == 'CONFIRMEE') return 'Confirmée';
    if (norm == 'ANNULEE') return 'Annulée';
    return raw;
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _InfoBadge({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? _baseUnit * 1.15 : _baseUnit * 1.5,
        vertical: compact ? _baseUnit * 0.8 : _baseUnit,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: _textSecondary,
              fontSize: compact ? 11 : 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class CommercialCommandesSection extends StatefulWidget {
  const CommercialCommandesSection({super.key});

  @override
  State<CommercialCommandesSection> createState() =>
      _CommercialCommandesSectionState();
}

class _CommercialCommandesSectionState extends State<CommercialCommandesSection>
    with TickerProviderStateMixin {
  static const Set<String> _factureStatuses = {'CONFIRMEE', 'VALIDEE'};
  static const List<String> _statuses = ['TOUS', 'EN_ATTENTE', 'ANNULEE'];

  final CommandeService _commandeService = CommandeService();
  final ClientService _clientService = ClientService();

  List<CommandeModel> _commandes = [];
  List<ClientModel> _clients = [];
  List<ProduitOption> _produits = [];

  bool _isLoading = true;
  bool _isBusy = false;
  bool _useGrid = false;
  String? _errorMessage;
  String _statusFilter = 'TOUS';
  int _draftLineSeed = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _commandeService.getCommandes(),
        _clientService.getClients(),
        _commandeService.getProduits(),
      ]);

      if (!mounted) return;

      setState(() {
        _commandes = _sortCommandesByCreation(
          _visibleCommandes(results[0] as List<CommandeModel>),
        );
        _clients = results[1] as List<ClientModel>;
        _produits = results[2] as List<ProduitOption>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reloadCommandes({bool showBusy = false}) async {
    if (showBusy && mounted) {
      setState(() => _isBusy = true);
    }

    try {
      final statut = _statusFilter == 'TOUS' ? null : _statusFilter;
      final data = await _commandeService.getCommandes(statut: statut);

      if (!mounted) return;

      setState(() {
        _commandes = _sortCommandesByCreation(_visibleCommandes(data));
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (showBusy && mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  List<CommandeModel> _visibleCommandes(List<CommandeModel> commandes) {
    return commandes.where((commande) {
      final status = commande.statut.trim().toUpperCase();
      return !_factureStatuses.contains(status);
    }).toList();
  }

  List<CommandeModel> _sortCommandesByCreation(List<CommandeModel> commandes) {
    final sorted = List<CommandeModel>.from(commandes);
    sorted.sort((a, b) {
      final aDate = _parseCommandeCreationDate(a);
      final bDate = _parseCommandeCreationDate(b);

      if (aDate != null && bDate != null) {
        final cmp = bDate.compareTo(aDate);
        if (cmp != 0) return cmp;
      } else if (aDate == null && bDate != null) {
        return 1;
      } else if (aDate != null && bDate == null) {
        return -1;
      }

      return b.idCommandeClient.compareTo(a.idCommandeClient);
    });
    return sorted;
  }

  DateTime? _parseCommandeCreationDate(CommandeModel commande) {
    final raw = commande.dateCommande.trim();
    if (raw.isNotEmpty) {
      final parsedRaw = DateTime.tryParse(raw);
      if (parsedRaw != null) return parsedRaw;
    }

    final formatted = commande.dateCommandeFormatted.trim();
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

  Future<void> _onCreate() async {
    final result = await _openCommandeForm();
    if (result == null) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.createCommande(
        CommandeCreatePayload(
          clientId: result.clientId,
          produits: result.produits,
          remiseTotale: result.remiseTotale,
        ),
      );
      if (!mounted) return;
      await _reloadCommandes();
      if (!mounted) return;
      _showMessage('Commande créée');
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onEdit(CommandeModel cmd) async {
    if (!cmd.canEdit) {
      _showMessage(
        'Seules les commandes en attente sont modifiables.',
        isError: true,
      );
      return;
    }

    final result = await _openCommandeForm(initialCommande: cmd);
    if (result == null) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.updateCommande(
        cmd.idCommandeClient,
        CommandeUpdatePayload(
          clientId: result.clientId,
          clientAdresse: result.clientAdresse,
          clientTelephone: result.clientTelephone,
          clientEmail: result.clientEmail,
          produits: result.produits,
        ),
      );
      if (!mounted) return;
      await _reloadCommandes();
      if (!mounted) return;
      _showMessage('Commande modifiée');
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onConfirm(CommandeModel cmd) async {
    final status = cmd.statut.trim().toUpperCase();

    if (status != 'EN_ATTENTE') {
      _showMessage(
        'Seules les commandes en attente peuvent être confirmées.',
        isError: true,
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer commande'),
        content: Text('Confirmer ${cmd.referenceCommandeClient} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _success),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.confirmerCommande(cmd.idCommandeClient);
      if (!mounted) return;
      await _reloadCommandes();
      if (!mounted) return;
      _showMessage('Commande confirmée. Retrouvez-la dans Factures.');
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onCancel(CommandeModel cmd) async {
    if (!cmd.canCancel) {
      _showMessage(
        'Seules les commandes en attente peuvent être annulées.',
        isError: true,
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler commande'),
        content: Text('Annuler ${cmd.referenceCommandeClient} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.rejeterCommande(cmd.idCommandeClient);
      if (!mounted) return;
      await _reloadCommandes();
      if (!mounted) return;
      _showMessage('Commande annulée');
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onDetails(CommandeModel cmd) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final client = cmd.client;
        final compactDialog = _isPhoneWidth(ctx, breakpoint: 700);

        return Dialog(
          insetPadding: EdgeInsets.all(compactDialog ? 6 : 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compactDialog ? 22 : 24),
          ),
          child: Container(
            width: AdaptiveLayout.dialogWidth(
              ctx,
              max: 1000,
              sideMargin: compactDialog ? 6 : 12,
            ),
            constraints: BoxConstraints(
              maxHeight: AdaptiveLayout.dialogHeight(
                ctx,
                ratio: compactDialog ? 0.965 : 0.9,
              ),
            ),
            padding: EdgeInsets.all(
              compactDialog ? _baseUnit * 1.5 : _baseUnit * 3,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compactDialog ? 42 : 52,
                      height: compactDialog ? 42 : 52,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
                        size: compactDialog ? 22 : 26,
                      ),
                    ),
                    SizedBox(
                      width: compactDialog ? _baseUnit : _baseUnit * 1.5,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails de la commande',
                            style: TextStyle(
                              fontSize: compactDialog ? 17 : 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cmd.referenceCommandeClient,
                            maxLines: compactDialog ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compactDialog ? 12 : 13,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(status: cmd.statut, compact: compactDialog),
                    SizedBox(width: compactDialog ? 4 : _baseUnit),
                    IconButton(
                      tooltip: 'Fermer',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(
                  height: compactDialog ? _baseUnit * 1.25 : _baseUnit * 2,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 860;

                      final leftPanel = SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailsSection(
                              title: 'Informations générales',
                              child: Wrap(
                                spacing: _baseUnit,
                                runSpacing: _baseUnit,
                                children: [
                                  _buildDetailInfoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Date',
                                    value: cmd.dateCommandeFormatted,
                                    compact: compact,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Client',
                                    value: client?.fullName ?? '-',
                                    compact: compact,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.local_offer_outlined,
                                    label: 'Référence',
                                    value: cmd.referenceCommandeClient,
                                    compact: compact,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.percent_outlined,
                                    label: 'Remise',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                    compact: compact,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Coordonnées client',
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.person_outline,
                                    label: 'Nom complet',
                                    value: client?.fullName ?? '-',
                                    compact: compact,
                                  ),
                                  _buildDetailRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Téléphone',
                                    value: client?.telephone ?? '-',
                                    compact: compact,
                                  ),
                                  _buildDetailRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: client?.email ?? '-',
                                    compact: compact,
                                  ),
                                  _buildDetailRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Adresse',
                                    value: client?.adresse ?? '-',
                                    isLast: true,
                                    compact: compact,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Produits commandés',
                              child: Column(
                                children: [
                                  if (cmd.produits.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                        _baseUnit * 2,
                                      ),
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
                                      final index = entry.key;
                                      final p = entry.value;
                                      return _buildProduitDetailCard(
                                        index: index + 1,
                                        produit: p,
                                        compact: compact,
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
                              title: 'Résumé financier',
                              child: Column(
                                children: [
                                  _buildSummaryTile(
                                    label: 'Nombre de lignes',
                                    value: '${cmd.produits.length}',
                                    compact: compact,
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Statut',
                                    value: _displayStatus(cmd.statut),
                                    compact: compact,
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Remise appliquée',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                    compact: compact,
                                  ),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  const Divider(color: _borderLight),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  _buildAmountRow(
                                    'Sous-total estimé',
                                    _buildCommandeSubtotal(cmd),
                                    compact: compact,
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildAmountRow(
                                    'Total final',
                                    '${cmd.total.toStringAsFixed(2)} DT',
                                    isPrimary: true,
                                    compact: compact,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Aperçu rapide',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Produits',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  if (cmd.produits.isEmpty)
                                    const Text(
                                      'Aucun produit',
                                      style: TextStyle(color: _textSecondary),
                                    )
                                  else
                                    ...cmd.produits.map((p) {
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: _baseUnit,
                                        ),
                                        padding: const EdgeInsets.all(
                                          _baseUnit * 1.25,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _background,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _borderLight,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${p.libelle} x${p.quantite}',
                                                style: const TextStyle(
                                                  color: _textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${p.sousTotal.toStringAsFixed(2)} DT',
                                              style: const TextStyle(
                                                color: _textSecondary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (compact) {
                        final compactSummarySection = _buildDetailsSection(
                          title: 'R\u00E9sum\u00E9 financier',
                          compact: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: _baseUnit * 0.75,
                                runSpacing: _baseUnit * 0.75,
                                children: [
                                  _buildDetailMetaPill(
                                    icon: Icons.shopping_bag_outlined,
                                    label: 'Lignes',
                                    value: '${cmd.produits.length}',
                                  ),
                                  _buildDetailMetaPill(
                                    icon: Icons.flag_outlined,
                                    label: 'Statut',
                                    value: _displayStatus(cmd.statut),
                                  ),
                                  _buildDetailMetaPill(
                                    icon: Icons.percent_outlined,
                                    label: 'Remise',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                ],
                              ),
                              const SizedBox(height: _baseUnit * 1.25),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(_baseUnit * 1.25),
                                decoration: BoxDecoration(
                                  color: _background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _borderLight),
                                ),
                                child: Column(
                                  children: [
                                    _buildAmountRow(
                                      'Sous-total estim\u00E9',
                                      _buildCommandeSubtotal(cmd),
                                      compact: true,
                                    ),
                                    const SizedBox(height: _baseUnit),
                                    _buildAmountRow(
                                      'Total final',
                                      '${cmd.total.toStringAsFixed(2)} DT',
                                      isPrimary: true,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        final compactInfoSection = _buildDetailsSection(
                          title: 'Informations g\u00E9n\u00E9rales',
                          compact: true,
                          child: LayoutBuilder(
                            builder: (context, infoConstraints) {
                              final spacing = _baseUnit * 0.75;
                              final cardWidth =
                                  (infoConstraints.maxWidth - spacing) / 2;

                              Widget infoCard({
                                required IconData icon,
                                required String label,
                                required String value,
                              }) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: _buildDetailInfoCard(
                                    icon: icon,
                                    label: label,
                                    value: value,
                                    compact: true,
                                  ),
                                );
                              }

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  infoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Date',
                                    value: cmd.dateCommandeFormatted,
                                  ),
                                  infoCard(
                                    icon: Icons.person_outline,
                                    label: 'Client',
                                    value: client?.fullName ?? '-',
                                  ),
                                  infoCard(
                                    icon: Icons.local_offer_outlined,
                                    label: 'R\u00E9f\u00E9rence',
                                    value: cmd.referenceCommandeClient,
                                  ),
                                  infoCard(
                                    icon: Icons.percent_outlined,
                                    label: 'Remise',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                ],
                              );
                            },
                          ),
                        );

                        final compactClientSection = _buildDetailsSection(
                          title: 'Coordonn\u00E9es client',
                          compact: true,
                          child: Column(
                            children: [
                              _buildDetailRow(
                                icon: Icons.person_outline,
                                label: 'Nom complet',
                                value: client?.fullName ?? '-',
                                compact: true,
                              ),
                              _buildDetailRow(
                                icon: Icons.phone_outlined,
                                label: 'T\u00E9l\u00E9phone',
                                value: client?.telephone ?? '-',
                                compact: true,
                              ),
                              _buildDetailRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: client?.email ?? '-',
                                compact: true,
                              ),
                              _buildDetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Adresse',
                                value: client?.adresse ?? '-',
                                isLast: true,
                                compact: true,
                              ),
                            ],
                          ),
                        );

                        final compactProductsSection = _buildDetailsSection(
                          title: 'Produits command\u00E9s',
                          compact: true,
                          child: Column(
                            children: [
                              if (cmd.produits.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    _baseUnit * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _background,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _borderLight),
                                  ),
                                  child: const Text(
                                    'Aucun produit dans cette commande.',
                                    style: TextStyle(color: _textSecondary),
                                  ),
                                )
                              else
                                ...cmd.produits.asMap().entries.map((entry) {
                                  return _buildProduitDetailCard(
                                    index: entry.key + 1,
                                    produit: entry.value,
                                    compact: true,
                                  );
                                }),
                            ],
                          ),
                        );

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              compactSummarySection,
                              const SizedBox(height: _baseUnit * 1.25),
                              compactInfoSection,
                              const SizedBox(height: _baseUnit * 1.25),
                              compactClientSection,
                              const SizedBox(height: _baseUnit * 1.25),
                              compactProductsSection,
                            ],
                          ),
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
                SizedBox(
                  height: compactDialog ? _baseUnit * 1.25 : _baseUnit * 2,
                ),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: _baseUnit,
                  runSpacing: _baseUnit,
                  children: [
                    if (_canConfirm(cmd))
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx, rootNavigator: true).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _onConfirm(cmd);
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Confirmer'),
                        style: _compactFilledButtonStyle(
                          backgroundColor: _success,
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Fermer'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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

  Future<_CommandeFormResult?> _openCommandeForm({
    CommandeModel? initialCommande,
  }) async {
    return _openMultiStepCommandeForm(initialCommande: initialCommande);
  }

  Future<_CommandeFormResult?> _openMultiStepCommandeForm({
    CommandeModel? initialCommande,
  }) async {
    final isEdit = initialCommande != null;
    int currentStep = 0;
    int? selectedClientId = initialCommande?.client?.idClient;
    String clientSearchTerm = '';
    String productSearchTerm = '';
    ClientModel? findClientById(int? clientId) {
      if (clientId == null) return null;
      try {
        return _clients.firstWhere((c) => c.id == clientId);
      } catch (_) {
        return null;
      }
    }

    double clientRemisePercent(ClientModel? client) {
      final value = client?.remise ?? 0;
      if (!value.isFinite) return 0;
      return value.clamp(0, 100).toDouble();
    }

    final clientSearchCtrl = TextEditingController();
    final productSearchCtrl = TextEditingController();
    final remiseCtrl = TextEditingController(
      text:
          (isEdit
                  ? initialCommande.tauxRemise
                  : clientRemisePercent(findClientById(selectedClientId)))
              .toStringAsFixed(2),
    );
    final lines = <_DraftLine>[
      if (isEdit && initialCommande.produits.isNotEmpty)
        ...initialCommande.produits.map(
          (p) => _newDraftLine(
            produitId: p.produitId,
            quantite: p.quantite,
            fallbackPrix: p.prixUnitaire,
          ),
        ),
    ];
    final removedLines = <_DraftLine>[];

    final result = await showDialog<_CommandeFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            ClientModel? selectedClient() {
              return findClientById(selectedClientId);
            }

            void syncSelectedClient(int? clientId) {
              selectedClientId = clientId;
              remiseCtrl.text = clientRemisePercent(
                findClientById(clientId),
              ).toStringAsFixed(2);
              if (!isEdit && clientId != null) {
                currentStep = 1;
              }
            }

            int lineQuantity(_DraftLine line) {
              return int.tryParse(line.quantiteController.text) ?? 0;
            }

            double lineUnitPrice(_DraftLine line) {
              final prod = _findProduitById(line.produitId);
              return prod?.prixVente ?? line.fallbackPrix ?? 0;
            }

            double lineTotal(_DraftLine line) {
              return lineQuantity(line) * lineUnitPrice(line);
            }

            double subTotal() {
              return lines.fold<double>(
                0,
                (sum, line) => sum + lineTotal(line),
              );
            }

            double remiseValue() {
              return double.tryParse(remiseCtrl.text) ?? 0;
            }

            double remiseAmount() {
              final rate = remiseValue().clamp(0, 100).toDouble();
              return subTotal() * (rate / 100);
            }

            double totalAfterRemise() {
              return subTotal() - remiseAmount();
            }

            bool hasValidLines() {
              return lines.any(
                (line) => line.produitId != null && lineQuantity(line) > 0,
              );
            }

            bool hasIncompleteLines() {
              return lines.any(
                (line) => line.produitId == null || lineQuantity(line) <= 0,
              );
            }

            bool lineHasStockIssue(_DraftLine line) {
              final prod = _findProduitById(line.produitId);
              final qty = lineQuantity(line);
              return prod != null && qty > prod.quantiteStock;
            }

            int stockIssueCount() {
              return lines.where(lineHasStockIssue).length;
            }

            void adjustQuantity(_DraftLine line, int delta) {
              final current = int.tryParse(line.quantiteController.text) ?? 1;
              final prod = _findProduitById(line.produitId);
              var next = current + delta;
              if (next < 1) next = 1;
              if (delta > 0) {
                if (prod == null) {
                  next = current;
                } else if (prod.quantiteStock <= 0) {
                  next = current;
                } else if (next > prod.quantiteStock) {
                  next = prod.quantiteStock;
                }
              }
              line.quantiteController.text = '$next';
            }

            String selectedClientName() {
              final client = selectedClient();
              if (client != null) return client.fullName;
              final fallback = initialCommande?.client?.fullName ?? '';
              return fallback.trim().isEmpty ? '-' : fallback;
            }

            String selectedClientPhone() {
              final value =
                  selectedClient()?.telephone ??
                  initialCommande?.client?.telephone ??
                  '';
              return value.trim().isEmpty ? '-' : value;
            }

            String selectedClientType() {
              final raw =
                  selectedClient()?.typeClient ??
                  initialCommande?.client?.typeClient;
              return _clientTypeLabel(raw);
            }

            Color clientTypeColor(String? raw) {
              switch (_normalizeClientType(raw)) {
                case 'vip':
                  return const Color(0xFF7C3AED);
                case 'fidele':
                  return _accent;
                case 'entreprise':
                  return const Color(0xFFEA580C);
                case 'particulier':
                default:
                  return _primary;
              }
            }

            List<ClientModel> filteredClients() {
              final search = clientSearchTerm.trim().toLowerCase();
              if (search.isEmpty) return _clients;
              final terms = search
                  .split(RegExp(r'\s+'))
                  .where((term) => term.isNotEmpty);
              return _clients.where((client) {
                final haystack = [
                  client.fullName,
                  client.telephone,
                  client.email ?? '',
                  client.adresse ?? '',
                  _clientTypeLabel(client.typeClient),
                ].join(' ').toLowerCase();
                return terms.every(haystack.contains);
              }).toList();
            }

            _DraftLine? findLineByProductId(int productId) {
              for (final line in lines) {
                if (line.produitId == productId) return line;
              }
              return null;
            }

            int quantityForProduct(ProduitOption product) {
              final line = findLineByProductId(product.idProduit);
              return line == null ? 0 : lineQuantity(line);
            }

            bool isProductSelected(ProduitOption product) {
              return findLineByProductId(product.idProduit) != null;
            }

            List<ProduitOption> filteredProducts() {
              final search = productSearchTerm.trim().toLowerCase();
              final selectedIds = lines
                  .map((line) => line.produitId)
                  .whereType<int>()
                  .toSet();
              final products = List<ProduitOption>.from(_produits)
                ..sort((a, b) {
                  final aSelected = selectedIds.contains(a.idProduit);
                  final bSelected = selectedIds.contains(b.idProduit);
                  if (aSelected != bSelected) return aSelected ? -1 : 1;
                  return a.libelle.toLowerCase().compareTo(
                    b.libelle.toLowerCase(),
                  );
                });
              if (search.isEmpty) return products;
              final terms = search
                  .split(RegExp(r'\s+'))
                  .where((term) => term.isNotEmpty);
              return products.where((product) {
                final haystack = [
                  product.libelle,
                  product.uniteMesure,
                  product.status,
                  '${product.prixVente}',
                  '${product.quantiteStock}',
                ].join(' ').toLowerCase();
                return terms.every(haystack.contains);
              }).toList();
            }

            void removeLine(_DraftLine line) {
              lines.remove(line);
              removedLines.add(line);
            }

            void addOrIncrementProduct(ProduitOption product) {
              final existing = findLineByProductId(product.idProduit);
              if (existing != null) {
                adjustQuantity(existing, 1);
                return;
              }
              lines.add(
                _newDraftLine(
                  produitId: product.idProduit,
                  quantite: product.quantiteStock > 0 ? 1 : 0,
                  fallbackPrix: product.prixVente,
                ),
              );
            }

            void decrementOrRemoveProduct(ProduitOption product) {
              final existing = findLineByProductId(product.idProduit);
              if (existing == null) return;
              final qty = lineQuantity(existing);
              if (qty <= 1) {
                removeLine(existing);
              } else {
                adjustQuantity(existing, -1);
              }
            }

            void clearCart() {
              for (final line in List<_DraftLine>.from(lines)) {
                removeLine(line);
              }
            }

            String stepSubtitle() {
              if (currentStep == 0) return 'Etape 1 : Selectionnez un client';
              if (currentStep == 1) {
                return 'Client : ${selectedClientName()} • ${lines.length} produit${lines.length > 1 ? 's' : ''}';
              }
              return 'Etape 3 : Validation';
            }

            Widget buildClientStep() {
              return _buildFormSection(
                title: 'Client',
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: clientSearchCtrl,
                      readOnly: isEdit,
                      onChanged: (value) =>
                          setModal(() => clientSearchTerm = value),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un client...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: clientSearchTerm.trim().isEmpty || isEdit
                            ? null
                            : IconButton(
                                onPressed: () {
                                  clientSearchCtrl.clear();
                                  setModal(() => clientSearchTerm = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: _baseUnit * 1.5),
                    if (selectedClient() != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(_baseUnit * 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedClientName(),
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedClientPhone(),
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  Wrap(
                                    spacing: _baseUnit,
                                    runSpacing: _baseUnit,
                                    children: [
                                      _InfoBadge(
                                        label: 'Type',
                                        value: selectedClientType(),
                                        compact: true,
                                      ),
                                      _InfoBadge(
                                        label: 'Remise',
                                        value:
                                            '${remiseValue().toStringAsFixed(2)}%',
                                        compact: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _success,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: _baseUnit * 1.5),
                    if (isEdit)
                      const Text(
                        'Le client reste verrouille pendant la modification.',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      SizedBox(
                        height: 340,
                        child: filteredClients().isEmpty
                            ? Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _borderLight),
                                ),
                                child: const Text(
                                  'Aucun client trouve.',
                                  style: TextStyle(color: _textSecondary),
                                ),
                              )
                            : ListView.separated(
                                itemCount: filteredClients().length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: _baseUnit),
                                itemBuilder: (_, index) {
                                  final client = filteredClients()[index];
                                  final selected =
                                      client.id == selectedClientId;
                                  final typeColor = clientTypeColor(
                                    client.typeClient,
                                  );

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => setModal(
                                      () => syncSelectedClient(client.id),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        _baseUnit * 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? const Color(0xFFEFF4FF)
                                            : _background,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: selected
                                              ? _primary.withValues(alpha: 0.24)
                                              : _borderLight,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  client.fullName,
                                                  style: const TextStyle(
                                                    color: _textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  client.telephone,
                                                  style: const TextStyle(
                                                    color: _textSecondary,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                if ((client.email ?? '')
                                                    .trim()
                                                    .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      client.email!,
                                                      style: const TextStyle(
                                                        color: _textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          _baseUnit * 1.15,
                                                      vertical: _baseUnit * 0.7,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: typeColor.withValues(
                                                    alpha: 0.1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  ClientType.label(
                                                    client.typeClient,
                                                    fallbackToDefault: true,
                                                  ),
                                                  style: TextStyle(
                                                    color: typeColor,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              if (selected) ...[
                                                const SizedBox(height: 10),
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: _success,
                                                  size: 20,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                  ],
                ),
              );
            }

            Widget buildProductCard(ProduitOption product) {
              final selected = isProductSelected(product);
              final qty = quantityForProduct(product);
              final stockColor = product.quantiteStock > 0 ? _success : _error;

              return Container(
                padding: const EdgeInsets.all(_baseUnit * 1.5),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFF2F7FF) : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? _primary.withValues(alpha: 0.24)
                        : _borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.libelle,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Stock: ${product.quantiteStock} ${product.uniteMesure}',
                                style: TextStyle(
                                  color: stockColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${product.prixVente.toStringAsFixed(2)} DT',
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!selected)
                              ElevatedButton.icon(
                                onPressed: product.quantiteStock <= 0
                                    ? null
                                    : () => setModal(
                                        () => addOrIncrementProduct(product),
                                      ),
                                style: _compactFilledButtonStyle(
                                  backgroundColor: _primary,
                                ),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Ajouter'),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: qty >= product.quantiteStock
                                    ? null
                                    : () => setModal(
                                        () => addOrIncrementProduct(product),
                                      ),
                                style: _compactFilledButtonStyle(
                                  backgroundColor: _primary,
                                ),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('+1'),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (selected) ...[
                      const SizedBox(height: _baseUnit),
                      const Divider(color: _borderLight),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setModal(
                              () => decrementOrRemoveProduct(product),
                            ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove, size: 18),
                          ),
                          Container(
                            width: 36,
                            alignment: Alignment.center,
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: qty >= product.quantiteStock
                                ? null
                                : () => setModal(
                                    () => addOrIncrementProduct(product),
                                  ),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 18),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setModal(() {
                              final line = findLineByProductId(
                                product.idProduit,
                              );
                              if (line != null) removeLine(line);
                            }),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: _error,
                            ),
                            label: const Text(
                              'Retirer',
                              style: TextStyle(color: _error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }

            Widget buildCartLine(_DraftLine line) {
              final prod = _findProduitById(line.produitId);

              return Container(
                margin: const EdgeInsets.only(bottom: _baseUnit),
                padding: const EdgeInsets.all(_baseUnit * 1.25),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderLight),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prod?.libelle ?? 'Produit',
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lineQuantity(line)} x ${lineUnitPrice(line).toStringAsFixed(2)} DT',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${lineTotal(line).toStringAsFixed(2)} DT',
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setModal(() => removeLine(line)),
                          child: const Text(
                            'Retirer',
                            style: TextStyle(color: _error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            Widget buildProductsStep() {
              final products = filteredProducts();
              final selectedTypeColor = clientTypeColor(
                selectedClient()?.typeClient,
              );

              return Column(
                children: [
                  _buildFormSection(
                    title: 'Produits',
                    compact: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Catalogue produits',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!isEdit)
                              TextButton(
                                onPressed: () =>
                                    setModal(() => currentStep = 0),
                                child: const Text('Changer client'),
                              ),
                          ],
                        ),
                        const SizedBox(height: _baseUnit),
                        TextFormField(
                          controller: productSearchCtrl,
                          onChanged: (value) =>
                              setModal(() => productSearchTerm = value),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: productSearchTerm.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      productSearchCtrl.clear();
                                      setModal(() => productSearchTerm = '');
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: _baseUnit * 1.5),
                        SizedBox(
                          height: 300,
                          child: products.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _background,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _borderLight),
                                  ),
                                  child: const Text(
                                    'Aucun produit trouve.',
                                    style: TextStyle(color: _textSecondary),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: products.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: _baseUnit),
                                  itemBuilder: (_, index) =>
                                      buildProductCard(products[index]),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _baseUnit * 1.5),
                  _buildFormSection(
                    title: 'Panier',
                    compact: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(_baseUnit * 1.25),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedClientName(),
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedClientPhone(),
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _baseUnit * 1.15,
                                  vertical: _baseUnit * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedTypeColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  selectedClientType(),
                                  style: TextStyle(
                                    color: selectedTypeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _baseUnit * 1.25),
                        if (lines.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(_baseUnit * 1.5),
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _borderLight),
                            ),
                            child: const Text(
                              'Aucun produit dans le panier.',
                              style: TextStyle(color: _textSecondary),
                            ),
                          )
                        else
                          ...lines.map(buildCartLine),
                        if (lines.isNotEmpty) ...[
                          const SizedBox(height: _baseUnit * 0.5),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => setModal(clearCart),
                              style: _compactOutlinedButtonStyle(
                                foregroundColor: _error,
                              ),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Vider le panier'),
                            ),
                          ),
                          const SizedBox(height: _baseUnit * 1.5),
                        ],
                        _buildAmountRow(
                          'Sous-total',
                          '${subTotal().toStringAsFixed(2)} DT',
                          compact: true,
                        ),
                        if (remiseValue() > 0) ...[
                          const SizedBox(height: _baseUnit),
                          _buildAmountRow(
                            'Remise (${remiseValue().toStringAsFixed(0)}%)',
                            '-${remiseAmount().toStringAsFixed(2)} DT',
                            compact: true,
                          ),
                        ],
                        const SizedBox(height: _baseUnit),
                        _buildAmountRow(
                          'Total',
                          '${totalAfterRemise().toStringAsFixed(2)} DT',
                          compact: true,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            Widget buildValidationStep() {
              final stockIssues = stockIssueCount();
              final ready =
                  selectedClientId != null &&
                  hasValidLines() &&
                  !hasIncompleteLines() &&
                  stockIssues == 0;

              return Column(
                children: [
                  _buildAvailabilityBanner(
                    available: ready,
                    title: ready
                        ? 'Tous les produits sont disponibles'
                        : 'Validation incomplete',
                    subtitle: ready
                        ? 'La commande peut etre creee immediatement.'
                        : stockIssues > 0
                        ? '$stockIssues ligne(s) depassent le stock.'
                        : 'Verifiez le client et les produits avant creation.',
                    compact: true,
                  ),
                  const SizedBox(height: _baseUnit * 1.5),
                  _buildFormSection(
                    title: 'Validation',
                    compact: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Client',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isEdit
                                  ? null
                                  : () => setModal(() => currentStep = 0),
                              child: const Text('Changer'),
                            ),
                          ],
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(_baseUnit * 1.25),
                          decoration: BoxDecoration(
                            color: _background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedClientName(),
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      selectedClientPhone(),
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _baseUnit * 1.15,
                                  vertical: _baseUnit * 0.7,
                                ),
                                decoration: BoxDecoration(
                                  color: clientTypeColor(
                                    selectedClient()?.typeClient,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  selectedClientType(),
                                  style: TextStyle(
                                    color: clientTypeColor(
                                      selectedClient()?.typeClient,
                                    ),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: _baseUnit * 1.5),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Produits',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _baseUnit * 1.15,
                                vertical: _baseUnit * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${lines.length} article${lines.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _baseUnit),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderLight),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _baseUnit * 1.25,
                                  vertical: _baseUnit,
                                ),
                                decoration: const BoxDecoration(
                                  color: _background,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'Produit',
                                        style: TextStyle(
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Qte',
                                        style: TextStyle(
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: _textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...lines.map((line) {
                                final prod = _findProduitById(line.produitId);
                                final issue = lineHasStockIssue(line);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: _baseUnit * 1.25,
                                    vertical: _baseUnit * 1.1,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: _borderLight),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod?.libelle ?? 'Produit',
                                              style: const TextStyle(
                                                color: _textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (issue)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                child: Text(
                                                  'Stock insuffisant',
                                                  style: TextStyle(
                                                    color: _error,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${lineQuantity(line)}',
                                          style: const TextStyle(
                                            color: _textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${lineTotal(line).toStringAsFixed(2)} DT',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: _primary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: _baseUnit),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setModal(() => currentStep = 1),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Modifier'),
                          ),
                        ),
                        const SizedBox(height: _baseUnit),
                        _buildAmountRow(
                          'Sous-total',
                          '${subTotal().toStringAsFixed(2)} DT',
                          compact: true,
                        ),
                        if (remiseValue() > 0) ...[
                          const SizedBox(height: _baseUnit),
                          _buildAmountRow(
                            'Remise',
                            '-${remiseAmount().toStringAsFixed(2)} DT',
                            compact: true,
                          ),
                        ],
                        const SizedBox(height: _baseUnit),
                        _buildAmountRow(
                          'Total final',
                          '${totalAfterRemise().toStringAsFixed(2)} DT',
                          compact: true,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            Future<void> save() async {
              if (selectedClientId == null) {
                _showMessage('Veuillez selectionner un client', isError: true);
                setModal(() => currentStep = 0);
                return;
              }
              if (!hasValidLines()) {
                _showMessage(
                  'Ajoutez au moins un produit valide',
                  isError: true,
                );
                setModal(() => currentStep = 1);
                return;
              }
              if (hasIncompleteLines()) {
                _showMessage(
                  'Chaque ligne doit contenir un produit et une quantite valide',
                  isError: true,
                );
                setModal(() => currentStep = 1);
                return;
              }
              if (stockIssueCount() > 0) {
                _showMessage(
                  'Certaines quantites depassent le stock disponible',
                  isError: true,
                );
                setModal(() => currentStep = 2);
                return;
              }

              final selectedClientModel = selectedClient();
              final produits = _buildProduitPayload(lines);
              Navigator.of(dialogContext, rootNavigator: true).pop(
                _CommandeFormResult(
                  clientId: selectedClientId!,
                  produits: produits,
                  remiseTotale: remiseValue(),
                  clientAdresse:
                      selectedClientModel?.adresse ??
                      initialCommande?.client?.adresse,
                  clientTelephone:
                      selectedClientModel?.telephone ??
                      initialCommande?.client?.telephone,
                  clientEmail:
                      selectedClientModel?.email ??
                      initialCommande?.client?.email,
                ),
              );
            }

            void nextStep() {
              if (currentStep == 0) {
                if (selectedClientId == null) {
                  _showMessage(
                    'Veuillez selectionner un client',
                    isError: true,
                  );
                  return;
                }
                setModal(() => currentStep = 1);
                return;
              }

              if (!hasValidLines()) {
                _showMessage(
                  'Ajoutez au moins un produit valide',
                  isError: true,
                );
                return;
              }
              if (hasIncompleteLines()) {
                _showMessage(
                  'Chaque ligne doit contenir un produit et une quantite valide',
                  isError: true,
                );
                return;
              }
              setModal(() => currentStep = 2);
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: AdaptiveLayout.dialogWidth(
                    dialogContext,
                    max: 560,
                    sideMargin: 8,
                  ),
                  constraints: BoxConstraints(
                    maxHeight: AdaptiveLayout.dialogHeight(
                      dialogContext,
                      ratio: 0.94,
                    ),
                  ),
                  color: _surface,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          _baseUnit * 2,
                          _baseUnit * 2,
                          _baseUnit * 2,
                          _baseUnit * 1.5,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, Color(0xFF3A69E8)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEdit
                                        ? 'Modifier la commande'
                                        : 'Nouvelle commande',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    stepSubtitle(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentStep > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _baseUnit * 1.25,
                                  vertical: _baseUnit,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Total\n${totalAfterRemise().toStringAsFixed(2)} DT',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                                rootNavigator: true,
                              ).pop(),
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(_baseUnit * 2),
                          child: Column(
                            children: [
                              Wrap(
                                spacing: _baseUnit,
                                runSpacing: _baseUnit,
                                children: [
                                  _buildWizardStepChip(
                                    index: 0,
                                    label: 'Client',
                                    active: currentStep == 0,
                                    complete: currentStep > 0,
                                  ),
                                  _buildWizardStepChip(
                                    index: 1,
                                    label: 'Produits',
                                    active: currentStep == 1,
                                    complete: currentStep > 1,
                                  ),
                                  _buildWizardStepChip(
                                    index: 2,
                                    label: 'Validation',
                                    active: currentStep == 2,
                                    complete: false,
                                  ),
                                ],
                              ),
                              const SizedBox(height: _baseUnit * 1.5),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (currentStep == 0) buildClientStep(),
                                      if (currentStep == 1) buildProductsStep(),
                                      if (currentStep == 2)
                                        buildValidationStep(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: _baseUnit * 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: currentStep == 0
                                          ? () => Navigator.of(
                                              dialogContext,
                                              rootNavigator: true,
                                            ).pop()
                                          : () => setModal(
                                              () => currentStep -= 1,
                                            ),
                                      style: _compactOutlinedButtonStyle(),
                                      icon: Icon(
                                        currentStep == 0
                                            ? Icons.close_rounded
                                            : Icons.arrow_back_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        currentStep == 0 ? 'Annuler' : 'Retour',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: _baseUnit),
                                  Expanded(
                                    child: currentStep < 2
                                        ? ElevatedButton.icon(
                                            onPressed: nextStep,
                                            style: _compactFilledButtonStyle(),
                                            icon: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                            ),
                                            label: Text(
                                              currentStep == 0
                                                  ? 'Produits'
                                                  : 'Validation',
                                            ),
                                          )
                                        : ElevatedButton.icon(
                                            onPressed:
                                                selectedClientId != null &&
                                                    hasValidLines() &&
                                                    !hasIncompleteLines() &&
                                                    stockIssueCount() == 0
                                                ? save
                                                : null,
                                            style: _compactFilledButtonStyle(),
                                            icon: const Icon(
                                              Icons.save_outlined,
                                              size: 16,
                                            ),
                                            label: Text(
                                              isEdit
                                                  ? 'Enregistrer'
                                                  : 'Creer la commande',
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;

    for (final line in lines) {
      line.dispose();
    }
    for (final line in removedLines) {
      line.dispose();
    }
    clientSearchCtrl.dispose();
    productSearchCtrl.dispose();
    remiseCtrl.dispose();

    return result;
  }

  // ignore: unused_element
  Future<_CommandeFormResult?> _openCommandeFormLegacy({
    CommandeModel? initialCommande,
  }) async {
    final isEdit = initialCommande != null;
    final formKey = GlobalKey<FormState>();

    int? selectedClientId = initialCommande?.client?.idClient;

    ClientModel? findClientById(int? clientId) {
      if (clientId == null) return null;
      try {
        return _clients.firstWhere((c) => c.id == clientId);
      } catch (_) {
        return null;
      }
    }

    double clientRemisePercent(ClientModel? client) {
      final value = client?.remise ?? 0;
      if (!value.isFinite) return 0;
      return value.clamp(0, 100).toDouble();
    }

    final remiseCtrl = TextEditingController(
      text:
          (isEdit
                  ? initialCommande.tauxRemise
                  : clientRemisePercent(findClientById(selectedClientId)))
              .toStringAsFixed(2),
    );

    final lines = <_DraftLine>[
      if (isEdit && initialCommande.produits.isNotEmpty)
        ...initialCommande.produits.map(
          (p) => _newDraftLine(
            produitId: p.produitId,
            quantite: p.quantite,
            fallbackPrix: p.prixUnitaire,
          ),
        )
      else
        _newDraftLine(produitId: _firstAvailableProduitId([])),
    ];

    final removedLines = <_DraftLine>[];

    final result = await showDialog<_CommandeFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            double subTotal() {
              double total = 0;
              for (final line in lines) {
                final qty = int.tryParse(line.quantiteController.text) ?? 0;
                final prod = _findProduitById(line.produitId);
                final prix = prod?.prixVente ?? line.fallbackPrix ?? 0;
                total += qty * prix;
              }
              return total;
            }

            double remiseValue() {
              return double.tryParse(remiseCtrl.text) ?? 0;
            }

            double totalAfterRemise() {
              final r = remiseValue().clamp(0, 100);
              return subTotal() * (1 - r / 100);
            }

            bool canAddProduct() {
              return _firstAvailableProduitId(lines) != null;
            }

            ClientModel? selectedClient() {
              return findClientById(selectedClientId);
            }

            Future<void> save() async {
              final hasValidLines = lines.any((l) {
                final q = int.tryParse(l.quantiteController.text) ?? 0;
                return l.produitId != null && q > 0;
              });

              if (selectedClientId == null) {
                _showMessage('Veuillez sélectionner un client', isError: true);
                return;
              }

              if (!hasValidLines) {
                _showMessage(
                  'Ajoutez au moins un produit valide',
                  isError: true,
                );
                return;
              }

              if (!(formKey.currentState?.validate() ?? false)) return;

              final selectedClientModel = selectedClient();
              final produits = _buildProduitPayload(lines);
              Navigator.of(dialogContext, rootNavigator: true).pop(
                _CommandeFormResult(
                  clientId: selectedClientId!,
                  produits: produits,
                  remiseTotale: remiseValue(),
                  clientAdresse: selectedClientModel?.adresse,
                  clientTelephone: selectedClientModel?.telephone,
                  clientEmail: selectedClientModel?.email,
                ),
              );
            }

            final compactViewport = _isPhoneWidth(ctx, breakpoint: 700);

            return Dialog(
              insetPadding: EdgeInsets.all(compactViewport ? 10 : 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: AdaptiveLayout.dialogWidth(
                  dialogContext,
                  max: 980,
                  sideMargin: compactViewport ? 8 : 12,
                ),
                constraints: BoxConstraints(
                  maxHeight: AdaptiveLayout.dialogHeight(
                    dialogContext,
                    ratio: compactViewport ? 0.94 : 0.9,
                  ),
                ),
                padding: EdgeInsets.all(
                  compactViewport ? _baseUnit * 2 : _baseUnit * 3,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit
                                  ? 'Modifier la commande'
                                  : 'Nouvelle commande',
                              style: TextStyle(
                                fontSize: compactViewport ? 18 : 20,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          if (!compactViewport) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: _baseUnit * 1.5,
                                vertical: _baseUnit,
                              ),
                              decoration: BoxDecoration(
                                color: _background,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: _borderLight),
                              ),
                              child: Text(
                                'Interface stable',
                                style: TextStyle(
                                  color: _primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: _baseUnit),
                          ],
                          IconButton(
                            onPressed: () => Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: compactViewport
                            ? _baseUnit * 1.25
                            : _baseUnit * 2,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 860;

                                  final leftPanel = Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFormSection(
                                        title: 'Informations générales',
                                        compact: compact,
                                        child: Column(
                                          children: [
                                            DropdownButtonFormField<int>(
                                              value: selectedClientId,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                labelText: 'Client',
                                                prefixIcon: const Icon(
                                                  Icons.person_outline,
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              items: _clients.map((c) {
                                                return DropdownMenuItem<int>(
                                                  value: c.id,
                                                  child: Text(
                                                    '${c.nom} (${c.telephone})',
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: isEdit
                                                  ? null
                                                  : (v) {
                                                      setModal(() {
                                                        selectedClientId = v;
                                                        remiseCtrl.text =
                                                            clientRemisePercent(
                                                              findClientById(v),
                                                            ).toStringAsFixed(
                                                              2,
                                                            );
                                                      });
                                                    },
                                              validator: (v) =>
                                                  v == null ? 'Requis' : null,
                                            ),
                                            const SizedBox(
                                              height: _baseUnit * 1.5,
                                            ),
                                            TextFormField(
                                              controller: remiseCtrl,
                                              readOnly: true,
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              decoration: InputDecoration(
                                                labelText: 'Remise client (%)',
                                                prefixIcon: const Icon(
                                                  Icons.percent,
                                                ),
                                                helperText: isEdit
                                                    ? 'Remise déjà enregistrée sur cette commande.'
                                                    : 'Appliquée automatiquement selon le type du client.',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              validator: (v) {
                                                final value = double.tryParse(
                                                  v ?? '',
                                                );
                                                if (value == null)
                                                  return 'Valeur invalide';
                                                if (value < 0 || value > 100)
                                                  return 'Entre 0 et 100';
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: _baseUnit * 2),
                                      _buildFormSection(
                                        title: 'Produits',
                                        compact: compact,
                                        child: Column(
                                          children: [
                                            ...List.generate(lines.length, (
                                              idx,
                                            ) {
                                              final line = lines[idx];
                                              final available =
                                                  _availableProductsForLine(
                                                    lines,
                                                    line,
                                                  );
                                              final prod = _findProduitById(
                                                line.produitId,
                                              );
                                              final qty =
                                                  int.tryParse(
                                                    line
                                                        .quantiteController
                                                        .text,
                                                  ) ??
                                                  0;
                                              final unitPrice =
                                                  prod?.prixVente ??
                                                  line.fallbackPrix ??
                                                  0;
                                              final lineTotal = qty * unitPrice;

                                              return Container(
                                                key: ValueKey(line.rowKey),
                                                margin: EdgeInsets.only(
                                                  bottom: compactViewport
                                                      ? _baseUnit
                                                      : _baseUnit * 1.5,
                                                ),
                                                padding: EdgeInsets.all(
                                                  compactViewport
                                                      ? _baseUnit * 1.25
                                                      : _baseUnit * 1.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _background,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: _borderLight,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            'Ligne ${idx + 1}',
                                                            style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  _textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: _error,
                                                          ),
                                                          onPressed:
                                                              lines.length <= 1
                                                              ? null
                                                              : () {
                                                                  removedLines.add(
                                                                    lines
                                                                        .removeAt(
                                                                          idx,
                                                                        ),
                                                                  );
                                                                  setModal(
                                                                    () {},
                                                                  );
                                                                },
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: _baseUnit,
                                                    ),
                                                    DropdownButtonFormField<
                                                      int
                                                    >(
                                                      key: ValueKey(
                                                        'product_${line.rowKey}',
                                                      ),
                                                      value:
                                                          available.any(
                                                            (p) =>
                                                                p.idProduit ==
                                                                line.produitId,
                                                          )
                                                          ? line.produitId
                                                          : null,
                                                      isExpanded: true,
                                                      decoration: InputDecoration(
                                                        labelText: 'Produit',
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                      items: available.map((p) {
                                                        return DropdownMenuItem<
                                                          int
                                                        >(
                                                          value: p.idProduit,
                                                          child: Text(
                                                            '${p.libelle} (stock: ${p.quantiteStock})',
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (v) =>
                                                          setModal(
                                                            () =>
                                                                line.produitId =
                                                                    v,
                                                          ),
                                                      validator: (v) =>
                                                          v == null
                                                          ? 'Requis'
                                                          : null,
                                                    ),
                                                    const SizedBox(
                                                      height: _baseUnit,
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextFormField(
                                                            key: ValueKey(
                                                              'qty_${line.rowKey}',
                                                            ),
                                                            controller: line
                                                                .quantiteController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Quantité',
                                                              border: OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                            ),
                                                            onChanged: (_) =>
                                                                setModal(() {}),
                                                            validator: (v) {
                                                              final q =
                                                                  int.tryParse(
                                                                    v ?? '',
                                                                  );
                                                              return (q ==
                                                                          null ||
                                                                      q <= 0)
                                                                  ? 'Invalide'
                                                                  : null;
                                                            },
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: _baseUnit,
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal:
                                                                  compactViewport
                                                                  ? _baseUnit
                                                                  : _baseUnit *
                                                                        1.5,
                                                              vertical:
                                                                  compactViewport
                                                                  ? _baseUnit *
                                                                        1.25
                                                                  : _baseUnit *
                                                                        1.8,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: _surface,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    _borderLight,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const Text(
                                                                  'Prix unitaire',
                                                                  style: TextStyle(
                                                                    color:
                                                                        _textSecondary,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  '${unitPrice.toStringAsFixed(2)} DT',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        _textPrimary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: _baseUnit,
                                                        ),
                                                        Expanded(
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(
                                                              horizontal:
                                                                  compactViewport
                                                                  ? _baseUnit
                                                                  : _baseUnit *
                                                                        1.5,
                                                              vertical:
                                                                  compactViewport
                                                                  ? _baseUnit *
                                                                        1.25
                                                                  : _baseUnit *
                                                                        1.8,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: _surface,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    _borderLight,
                                                              ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                const Text(
                                                                  'Sous-total',
                                                                  style: TextStyle(
                                                                    color:
                                                                        _textSecondary,
                                                                    fontSize:
                                                                        11,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Text(
                                                                  '${lineTotal.toStringAsFixed(2)} DT',
                                                                  style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        _textPrimary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton.icon(
                                                onPressed: canAddProduct()
                                                    ? () {
                                                        final newId =
                                                            _firstAvailableProduitId(
                                                              lines,
                                                            );
                                                        if (newId != null) {
                                                          lines.add(
                                                            _newDraftLine(
                                                              produitId: newId,
                                                            ),
                                                          );
                                                          setModal(() {});
                                                        }
                                                      }
                                                    : null,
                                                icon: const Icon(Icons.add),
                                                label: const Text(
                                                  'Ajouter un produit',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );

                                  final rightPanel = _buildFormSection(
                                    title: 'Résumé de la commande',
                                    compact: compact,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSummaryTile(
                                          label: 'Client',
                                          value: selectedClient()?.nom ?? '-',
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Téléphone',
                                          value:
                                              selectedClient()?.telephone ??
                                              '-',
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Nombre de lignes',
                                          value: '${lines.length}',
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Remise',
                                          value:
                                              '${remiseValue().toStringAsFixed(2)}%',
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit * 1.5),
                                        const Divider(color: _borderLight),
                                        const SizedBox(height: _baseUnit * 1.5),
                                        _buildAmountRow(
                                          'Sous-total',
                                          '${subTotal().toStringAsFixed(2)} DT',
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildAmountRow(
                                          'Total final',
                                          '${totalAfterRemise().toStringAsFixed(2)} DT',
                                          isPrimary: true,
                                          compact: compact,
                                        ),
                                        const SizedBox(height: _baseUnit * 2),
                                        const Text(
                                          'Aperçu produits',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: _textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        if (lines.isEmpty)
                                          const Text(
                                            'Aucun produit',
                                            style: TextStyle(
                                              color: _textSecondary,
                                            ),
                                          )
                                        else
                                          ...lines.map((l) {
                                            final prod = _findProduitById(
                                              l.produitId,
                                            );
                                            final qty =
                                                int.tryParse(
                                                  l.quantiteController.text,
                                                ) ??
                                                0;
                                            final amount =
                                                qty *
                                                (prod?.prixVente ??
                                                    l.fallbackPrix ??
                                                    0);

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: _baseUnit,
                                              ),
                                              padding: const EdgeInsets.all(
                                                _baseUnit * 1.25,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _background,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: _borderLight,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${prod?.libelle ?? 'Produit'} x$qty',
                                                      style: const TextStyle(
                                                        color: _textPrimary,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${amount.toStringAsFixed(2)} DT',
                                                    style: const TextStyle(
                                                      color: _textSecondary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                      ],
                                    ),
                                  );

                                  if (compact) {
                                    return Column(
                                      children: [
                                        leftPanel,
                                        const SizedBox(height: _baseUnit * 2),
                                        rightPanel,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: leftPanel),
                                      const SizedBox(width: _baseUnit * 2),
                                      Expanded(flex: 2, child: rightPanel),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: _baseUnit * 2),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: _baseUnit,
                        runSpacing: _baseUnit,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton.icon(
                            onPressed: save,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: Text(isEdit ? 'Enregistrer' : 'Créer'),
                            style: _compactFilledButtonStyle(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await WidgetsBinding.instance.endOfFrame;

    for (final l in lines) {
      l.dispose();
    }
    for (final l in removedLines) {
      l.dispose();
    }
    remiseCtrl.dispose();

    return result;
  }

  String _normalizeClientType(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    if (value.contains('vip')) return 'vip';
    if (value.contains('fidel')) return 'fidele';
    if (value.contains('entreprise')) return 'entreprise';
    if (value.contains('particulier')) return 'particulier';
    return 'particulier';
  }

  String _clientTypeLabel(String? raw) {
    switch (_normalizeClientType(raw)) {
      case 'vip':
        return 'VIP';
      case 'fidele':
        return 'FIDELE';
      case 'entreprise':
        return 'ENTREPRISE';
      default:
        return 'PARTICULIER';
    }
  }

  Widget _buildFormSection({
    required String title,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? _baseUnit * 1.5 : _baseUnit * 2),
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
            style: TextStyle(
              fontSize: compact ? 14 : 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: compact ? _baseUnit : _baseUnit * 1.5),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailsSection({
    required String title,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? _baseUnit * 1.25 : _baseUnit * 2),
      decoration: BoxDecoration(
        color: compact ? _surface.withValues(alpha: 0.96) : _surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: _borderLight),
        boxShadow: compact
            ? const []
            : [
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
            style: TextStyle(
              fontSize: compact ? 13.5 : 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          SizedBox(height: compact ? _baseUnit * 0.9 : _baseUnit * 1.5),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailMetaPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.1,
        vertical: _baseUnit * 0.75,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfoCard({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 0 : 190),
      padding: EdgeInsets.all(compact ? _baseUnit * 1.05 : _baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 28 : 36,
            height: compact ? 28 : 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
              border: Border.all(color: _borderLight),
            ),
            child: Icon(icon, size: compact ? 15 : 18, color: _primary),
          ),
          SizedBox(width: compact ? 7 : _baseUnit),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: compact ? 10.5 : 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 11.8 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
    bool compact = false,
  }) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: _baseUnit * 0.85),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: _borderLight)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: _textSecondary),
            const SizedBox(width: _baseUnit),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 10.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : _baseUnit),
      padding: EdgeInsets.all(compact ? _baseUnit : _baseUnit * 1.25),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: compact ? 16 : 18, color: _textSecondary),
          const SizedBox(width: _baseUnit),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 12 : 13,
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
    required dynamic produit,
    bool compact = false,
  }) {
    if (compact) {
      return Container(
        margin: const EdgeInsets.only(bottom: _baseUnit * 0.75),
        padding: const EdgeInsets.all(_baseUnit * 1.1),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderLight),
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: _baseUnit),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    produit.libelle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.8,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${produit.quantite} x ${produit.prixUnitaire.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _baseUnit),
            Text(
              '${produit.sousTotal.toStringAsFixed(2)} DT',
              style: const TextStyle(
                color: _primaryDark,
                fontWeight: FontWeight.w800,
                fontSize: 12.8,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: compact ? _baseUnit : _baseUnit * 1.25),
      padding: EdgeInsets.all(compact ? _baseUnit * 1.2 : _baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(compact ? 8 : 10),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : 14,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                '${produit.sousTotal.toStringAsFixed(2)} DT',
                style: TextStyle(
                  color: _primaryDark,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? _baseUnit : _baseUnit * 1.25),
          Wrap(
            spacing: _baseUnit,
            runSpacing: _baseUnit,
            children: [
              _InfoBadge(
                label: 'Quantité',
                value: '${produit.quantite}',
                compact: compact,
              ),
              _InfoBadge(
                label: 'Prix unitaire',
                value: '${produit.prixUnitaire.toStringAsFixed(2)} DT',
                compact: compact,
              ),
              _InfoBadge(
                label: 'Sous-total',
                value: '${produit.sousTotal.toStringAsFixed(2)} DT',
                compact: compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? _baseUnit * 1.15 : _baseUnit * 1.5,
        vertical: compact ? _baseUnit : _baseUnit * 1.3,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _textSecondary,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    bool isPrimary = false,
    bool compact = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? _textPrimary : _textSecondary,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              fontSize: compact ? (isPrimary ? 14 : 12) : (isPrimary ? 15 : 13),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? _accent : _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? (isPrimary ? 16 : 13) : (isPrimary ? 18 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildWizardStepChip({
    required int index,
    required String label,
    required bool active,
    required bool complete,
  }) {
    final background = active
        ? _primary
        : complete
        ? const Color(0xFFE9F8EF)
        : _background;
    final foreground = active
        ? Colors.white
        : complete
        ? _success
        : _textSecondary;
    final border = active
        ? _primary
        : complete
        ? const Color(0xFFB7E4C7)
        : _borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.25,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white,
              shape: BoxShape.circle,
            ),
            child: complete
                ? Icon(Icons.check, size: 12, color: foreground)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: _baseUnit),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBanner({
    required bool available,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    final background = available
        ? const Color(0xFFE9F8EF)
        : const Color(0xFFFFF4F2);
    final border = available
        ? const Color(0xFFB7E4C7)
        : const Color(0xFFF7C2BA);
    final foreground = available ? const Color(0xFF11853F) : _error;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? _baseUnit * 1.5 : _baseUnit * 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.error_outline,
            color: foreground,
            size: compact ? 20 : 22,
          ),
          const SizedBox(width: _baseUnit),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildCommandeSubtotal(CommandeModel cmd) {
    final subtotal = cmd.produits.fold<double>(
      0,
      (sum, p) => sum + p.sousTotal,
    );
    return '${subtotal.toStringAsFixed(2)} DT';
  }

  bool _canConfirm(CommandeModel cmd) {
    return !_isBusy && cmd.statut.trim().toUpperCase() == 'EN_ATTENTE';
  }

  _DraftLine _newDraftLine({
    int? produitId,
    int quantite = 1,
    double? fallbackPrix,
  }) {
    _draftLineSeed += 1;
    return _DraftLine(
      rowKey: 'line_$_draftLineSeed',
      produitId: produitId,
      quantite: quantite,
      fallbackPrix: fallbackPrix,
    );
  }

  List<ProduitOption> _availableProductsForLine(
    List<_DraftLine> lines,
    _DraftLine currentLine,
  ) {
    final selected = <int>{};
    for (final l in lines) {
      if (l.rowKey == currentLine.rowKey) continue;
      if (l.produitId != null) selected.add(l.produitId!);
    }

    return _produits.where((p) {
      return p.idProduit == currentLine.produitId ||
          !selected.contains(p.idProduit);
    }).toList();
  }

  int? _firstAvailableProduitId(List<_DraftLine> lines) {
    final selected = lines.map((l) => l.produitId).whereType<int>().toSet();
    for (final p in _produits) {
      if (!selected.contains(p.idProduit)) return p.idProduit;
    }
    return null;
  }

  ProduitOption? _findProduitById(int? id) {
    if (id == null) return null;
    try {
      return _produits.firstWhere((p) => p.idProduit == id);
    } catch (_) {
      return null;
    }
  }

  List<CommandeProduitPayload> _buildProduitPayload(List<_DraftLine> lines) {
    final map = <int, CommandeProduitPayload>{};

    for (final l in lines) {
      final pid = l.produitId;
      final qty = int.tryParse(l.quantiteController.text) ?? 0;
      if (pid == null || qty <= 0) continue;

      final prod = _findProduitById(pid);
      final prix = prod?.prixVente ?? l.fallbackPrix;

      if (map.containsKey(pid)) {
        final existing = map[pid]!;
        map[pid] = CommandeProduitPayload(
          produitId: pid,
          quantite: existing.quantite + qty,
          prixUnitaire: existing.prixUnitaire ?? prix,
        );
      } else {
        map[pid] = CommandeProduitPayload(
          produitId: pid,
          quantite: qty,
          prixUnitaire: prix,
        );
      }
    }

    return map.values.toList();
  }

  void _showMessage(String msg, {bool isError = false}) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? _error : _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _isPhoneWidth(context, breakpoint: 700);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _error, size: 48),
            const SizedBox(height: _baseUnit * 2),
            Text(_errorMessage!, style: const TextStyle(color: _error)),
            const SizedBox(height: _baseUnit * 2),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: _background,
      child: Scrollbar(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_isBusy)
              const SliverToBoxAdapter(
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_commandes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(compact: isPhone),
              )
            else
              ..._buildOrderSlivers(compact: isPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isPhone = _isPhoneWidth(context, breakpoint: 760);

    if (isPhone) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          _baseUnit * 1.5,
          _baseUnit * 1.5,
          _baseUnit * 1.5,
          _baseUnit,
        ),
        child: Container(
          padding: const EdgeInsets.all(_baseUnit * 1.5),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Commandes commerciales',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _buildCountPill(
                    _commandes.length,
                    compact: true,
                    countOnly: true,
                  ),
                  const SizedBox(width: 4),
                  _buildHeaderIconButton(
                    tooltip: 'Actualiser',
                    icon: Icons.refresh,
                    onPressed: _isBusy
                        ? null
                        : () => _reloadCommandes(showBusy: true),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Suivi rapide des commandes en cours.',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: _baseUnit),
              Wrap(
                spacing: _baseUnit,
                runSpacing: _baseUnit,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ActionChip(
                    avatar: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: _activeFilterCount > 0 ? _primary : _textSecondary,
                    ),
                    label: Text(
                      _activeFilterCount > 0
                          ? 'Filtres ($_activeFilterCount)'
                          : 'Filtres',
                    ),
                    onPressed: _isBusy ? null : _openMobileFilterSheet,
                    backgroundColor: _activeFilterCount > 0
                        ? _primary.withOpacity(0.10)
                        : _background,
                    side: BorderSide(
                      color: _activeFilterCount > 0
                          ? _primary.withOpacity(0.28)
                          : _borderLight,
                    ),
                    labelStyle: TextStyle(
                      color: _activeFilterCount > 0
                          ? _primaryDark
                          : _textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (_activeFilterCount > 0)
                    InputChip(
                      avatar: Icon(
                        Icons.filter_alt_outlined,
                        size: 16,
                        color: _primaryDark,
                      ),
                      label: Text(_displayStatus(_statusFilter)),
                      selected: true,
                      showCheckmark: false,
                      backgroundColor: _primary.withOpacity(0.10),
                      selectedColor: _primary.withOpacity(0.10),
                      side: BorderSide(color: _primary.withOpacity(0.26)),
                      labelStyle: const TextStyle(
                        color: _primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: _isBusy ? null : () => _setFilter('TOUS'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ActionChip(
                    avatar: Icon(
                      _useGrid
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_rounded,
                      size: 18,
                      color: _textSecondary,
                    ),
                    label: Text(_useGrid ? 'Liste' : 'Grille'),
                    onPressed: () => setState(() => _useGrid = !_useGrid),
                    backgroundColor: _background,
                    side: const BorderSide(color: _borderLight),
                    labelStyle: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: _baseUnit * 1.1),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _onCreate,
                  icon: const Icon(Icons.add, size: 17),
                  label: const Text('Nouvelle commande'),
                  style: _compactFilledButtonStyle(dense: true),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _baseUnit * 2,
        _baseUnit * 2,
        _baseUnit * 2,
        _baseUnit,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(
              _isPhoneWidth(context, breakpoint: 760)
                  ? _baseUnit * 1.5
                  : _baseUnit * 2,
            ),
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
                    Text(
                      'Commandes Commerciales',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      'Workflow de vente, suivi et actions sur commandes dans une interface unifiée.',
                      style: TextStyle(
                        color: const Color(0xFFE3EBFF),
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                  ],
                );

                final counter = _buildCountPill(
                  _commandes.length,
                  onDark: true,
                  compact: compact,
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
                  children: [
                    Expanded(child: titleBlock),
                    counter,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: _baseUnit * 1.5),
          Container(
            padding: EdgeInsets.all(
              _isPhoneWidth(context, breakpoint: 760)
                  ? _baseUnit * 1.5
                  : _baseUnit * 2,
            ),
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
                final compact = constraints.maxWidth < 760;
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtres & Actions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: _baseUnit),
                      _buildStatusFilter(compact: true),
                      const SizedBox(height: _baseUnit * 1.25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isBusy ? null : _onCreate,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouvelle commande'),
                          style: _compactFilledButtonStyle(),
                        ),
                      ),
                      const SizedBox(height: _baseUnit),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () => _reloadCommandes(showBusy: true),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Actualiser'),
                              style: _compactOutlinedButtonStyle(),
                            ),
                          ),
                          const SizedBox(width: _baseUnit),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _useGrid = !_useGrid),
                              icon: Icon(
                                _useGrid
                                    ? Icons.view_agenda_outlined
                                    : Icons.grid_view_rounded,
                                size: 18,
                              ),
                              label: Text(_useGrid ? 'Liste' : 'Grille'),
                              style: _compactOutlinedButtonStyle(),
                            ),
                          ),
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
                        OutlinedButton.icon(
                          onPressed: _isBusy
                              ? null
                              : () => _reloadCommandes(showBusy: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualiser'),
                          style: _compactOutlinedButtonStyle(),
                        ),
                        const SizedBox(width: _baseUnit),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _useGrid = !_useGrid),
                          icon: Icon(
                            _useGrid
                                ? Icons.view_agenda_outlined
                                : Icons.grid_view_rounded,
                          ),
                          label: Text(_useGrid ? 'Vue liste' : 'Vue grille'),
                          style: _compactOutlinedButtonStyle(),
                        ),
                        const SizedBox(width: _baseUnit),
                        ElevatedButton.icon(
                          onPressed: _isBusy ? null : _onCreate,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Nouvelle commande'),
                          style: _compactFilledButtonStyle(),
                        ),
                      ],
                    ),
                    const SizedBox(height: _baseUnit * 1.5),
                    _buildStatusFilter(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _setFilter(String status) {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    _reloadCommandes(showBusy: true);
  }

  int get _activeFilterCount => _statusFilter == 'TOUS' ? 0 : 1;

  Future<void> _openMobileFilterSheet() async {
    var draftStatus = _statusFilter;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Filtres commandes',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (draftStatus != 'TOUS')
                          TextButton(
                            onPressed: () {
                              modalSetState(() {
                                draftStatus = 'TOUS';
                              });
                            },
                            child: const Text('Effacer'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choisissez un statut a afficher dans la liste.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: _baseUnit,
                      runSpacing: _baseUnit,
                      children: _statuses.map((status) {
                        final selected = draftStatus == status;
                        return ChoiceChip(
                          label: Text(
                            status == 'TOUS' ? 'Tous' : _displayStatus(status),
                          ),
                          selected: selected,
                          selectedColor: _primary.withOpacity(0.16),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected ? _primary : _borderLight,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? _primaryDark : _textPrimary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          onSelected: (_) {
                            modalSetState(() {
                              draftStatus = status;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Fermer'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            final shouldReload = draftStatus != _statusFilter;
                            Navigator.of(sheetContext).pop();
                            if (!shouldReload) return;
                            setState(() {
                              _statusFilter = draftStatus;
                            });
                            _reloadCommandes(showBusy: true);
                          },
                          child: const Text('Appliquer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isPhoneWidth(BuildContext context, {double breakpoint = 640}) {
    return MediaQuery.sizeOf(context).width < breakpoint;
  }

  ButtonStyle _compactOutlinedButtonStyle({
    Color? foregroundColor,
    bool dense = false,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor,
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: Size(0, dense ? 32 : 36),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? _baseUnit : _baseUnit * 1.25,
        vertical: dense ? _baseUnit * 0.85 : _baseUnit,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dense ? 11 : 12),
      ),
      textStyle: TextStyle(
        fontSize: dense ? 12 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  ButtonStyle _compactFilledButtonStyle({
    Color backgroundColor = _accent,
    bool dense = false,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: Size(0, dense ? 34 : 38),
      padding: EdgeInsets.symmetric(
        horizontal: dense ? _baseUnit * 1.2 : _baseUnit * 1.5,
        vertical: dense ? _baseUnit : _baseUnit * 1.1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dense ? 13 : 12),
      ),
      textStyle: TextStyle(
        fontSize: dense ? 12.5 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: 32, height: 32),
      icon: Icon(icon, size: 18.5),
      style: IconButton.styleFrom(
        foregroundColor: _primary,
        backgroundColor: _background,
        side: BorderSide(color: _borderLight),
      ),
    );
  }

  Widget _buildCountPill(
    int count, {
    bool onDark = false,
    bool compact = false,
    bool countOnly = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? _baseUnit * 1.2 : _baseUnit * 1.5,
        vertical: compact ? _baseUnit * 0.8 : _baseUnit,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withOpacity(0.18)
            : _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 18 : 30),
        border: Border.all(
          color: onDark
              ? Colors.white.withOpacity(0.28)
              : _primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        countOnly ? '$count' : '$count commandes',
        style: TextStyle(
          color: onDark ? Colors.white : _primary,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 12 : 14,
        ),
      ),
    );
  }

  Widget _buildStatusFilter({bool compact = false}) {
    final icons = <String, IconData>{
      'TOUS': Icons.all_inbox_outlined,
      'EN_ATTENTE': Icons.hourglass_top_outlined,
      'ANNULEE': Icons.block_outlined,
    };

    final chips = _statuses.map((status) {
      final selected = _statusFilter == status;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[status] ?? Icons.tune,
              size: compact ? 14 : 16,
              color: selected ? _primaryDark : _textSecondary,
            ),
            SizedBox(width: compact ? 5 : 6),
            Text(status == 'TOUS' ? 'Tous' : _displayStatus(status)),
          ],
        ),
        selected: selected,
        selectedColor: _primary.withOpacity(0.16),
        backgroundColor: _surface,
        side: BorderSide(color: selected ? _primary : _borderLight),
        labelStyle: TextStyle(
          color: selected ? _primaryDark : _textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: compact ? 12 : 13,
        ),
        labelPadding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 0 : 2,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        onSelected: (_) => _setFilter(status),
      );
    }).toList();

    final content = Wrap(
      spacing: _baseUnit,
      runSpacing: _baseUnit,
      children: chips,
    );

    if (!compact) return content;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: content,
    );
  }

  String _displayStatus(String raw) {
    final norm = raw.trim().toUpperCase();
    if (norm == 'EN_ATTENTE') return 'En attente';
    if (norm == 'CONFIRMEE') return 'Confirmée';
    if (norm == 'ANNULEE') return 'Annulée';
    return raw;
  }

  Widget _buildEmptyState({bool compact = false}) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(compact ? _baseUnit * 2.5 : _baseUnit * 4),
        margin: EdgeInsets.all(compact ? _baseUnit * 1.5 : _baseUnit * 2),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: compact ? 48 : 64,
              color: _textSecondary,
            ),
            SizedBox(height: compact ? _baseUnit * 1.5 : _baseUnit * 2),
            const Text(
              'Aucune commande disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: _baseUnit),
            Text(
              _statusFilter == 'TOUS'
                  ? 'Les commandes confirmées sont transférées vers Factures. Créez une nouvelle commande pour continuer.'
                  : 'Ajustez les filtres ou créez une nouvelle commande.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: compact ? 12 : 13,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? _baseUnit * 1.5 : _baseUnit * 2),
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Créer une commande'),
              style: _compactFilledButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderSlivers({bool compact = false}) {
    if (_useGrid) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            compact ? _baseUnit * 1.5 : _baseUnit * 2,
            _baseUnit,
            compact ? _baseUnit * 1.5 : _baseUnit * 2,
            compact ? _baseUnit * 1.5 : _baseUnit * 2,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: compact ? 360 : 430,
              crossAxisSpacing: compact ? _baseUnit * 1.5 : _baseUnit * 2,
              mainAxisSpacing: compact ? _baseUnit * 1.5 : _baseUnit * 2,
              mainAxisExtent: compact ? 252 : 300,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildOrderCard(_commandes[index], grid: true),
              childCount: _commandes.length,
            ),
          ),
        ),
      ];
    }

    if (compact) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _baseUnit * 1.5,
            _baseUnit,
            _baseUnit * 1.5,
            _baseUnit * 1.5,
          ),
          sliver: SliverToBoxAdapter(child: _buildOrdersTable(compact: true)),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          compact ? _baseUnit * 1.5 : _baseUnit * 2,
          _baseUnit,
          compact ? _baseUnit * 1.5 : _baseUnit * 2,
          compact ? _baseUnit * 1.5 : _baseUnit * 2,
        ),
        sliver: SliverList.builder(
          itemCount: _commandes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: compact ? _baseUnit * 1.1 : _baseUnit * 1.5,
              ),
              child: _buildOrderCard(_commandes[index], grid: false),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildOrdersTable({required bool compact}) {
    return ColoredBox(
      color: _surface,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1120),
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 80,
              horizontalMargin: 10,
              columnSpacing: 18,
              dividerThickness: 0.8,
              headingRowColor: WidgetStatePropertyAll(
                _background.withValues(alpha: 0.92),
              ),
              headingTextStyle: const TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              columns: const [
                DataColumn(label: Text('COMMANDE')),
                DataColumn(label: Text('CLIENT')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('PRODUITS')),
                DataColumn(label: Text('MONTANT')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: _commandes.map((cmd) {
                final canEdit = !_isBusy && cmd.canEdit;
                final canCancel = !_isBusy && cmd.canCancel;
                final canConfirm = _canConfirm(cmd);

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: Text(
                          cmd.referenceCommandeClient,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          cmd.client?.fullName ?? '-',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(cmd.dateCommandeFormatted)),
                    DataCell(
                      SizedBox(
                        width: 240,
                        child: Text(
                          _productsPreview(cmd),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text('${cmd.total.toStringAsFixed(2)} DT')),
                    DataCell(_StatusChip(status: cmd.statut, compact: true)),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Details',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _onDetails(cmd),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Modifier',
                            visualDensity: VisualDensity.compact,
                            onPressed: canEdit ? () => _onEdit(cmd) : null,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Confirmer',
                            visualDensity: VisualDensity.compact,
                            onPressed: canConfirm
                                ? () => _onConfirm(cmd)
                                : null,
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Annuler',
                            visualDensity: VisualDensity.compact,
                            onPressed: canCancel ? () => _onCancel(cmd) : null,
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? _baseUnit : _baseUnit * 1.25,
        vertical: compact ? _baseUnit * 0.8 : _baseUnit,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: _textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CommandeModel cmd, {required bool grid}) {
    final canEdit = !_isBusy && cmd.canEdit;
    final canCancel = !_isBusy && cmd.canCancel;
    final canConfirm = _canConfirm(cmd);
    final isPhone = _isPhoneWidth(context, breakpoint: 480);
    final cardRadius = isPhone ? 14.0 : 20.0;
    final cardPadding = isPhone ? _baseUnit * 1.1 : _baseUnit * 2;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: _borderLight),
        boxShadow: AdaptiveSurface.shadow(
          context,
          breakpoint: 480,
          compactBlur: 9,
          compactOffsetY: 4,
          regularBlur: 14,
          regularOffsetY: 6,
          compactColor: const Color(0x08000000),
          regularColor: const Color(0x08000000),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(cardRadius),
          onTap: () => _onDetails(cmd),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isPhone ? 32 : 40,
                      height: isPhone ? 32 : 40,
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(isPhone ? 9 : 12),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
                        size: isPhone ? 18 : 24,
                      ),
                    ),
                    SizedBox(
                      width: isPhone ? _baseUnit * 0.85 : _baseUnit * 1.25,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cmd.referenceCommandeClient,
                            maxLines: isPhone ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isPhone ? 13.5 : 15,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cmd.dateCommandeFormatted,
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: isPhone ? 10.5 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isPhone ? _baseUnit * 0.6 : _baseUnit),
                    _StatusChip(status: cmd.statut, compact: isPhone),
                  ],
                ),
                SizedBox(height: isPhone ? _baseUnit * 0.75 : _baseUnit * 1.5),
                if (isPhone)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetaTile(
                          icon: Icons.person_outline,
                          label: 'Client',
                          value: cmd.client?.fullName ?? '-',
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: _baseUnit * 0.65),
                      Expanded(
                        child: _buildMetaTile(
                          icon: Icons.payments_outlined,
                          label: 'Total',
                          value: '${cmd.total.toStringAsFixed(2)} DT',
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: _baseUnit * 0.65),
                      Expanded(
                        child: _buildMetaTile(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Lignes',
                          value: '${cmd.produits.length}',
                          compact: true,
                        ),
                      ),
                    ],
                  )
                else
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
                        value: '${cmd.total.toStringAsFixed(2)} DT',
                      ),
                      _buildMetaTile(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Lignes',
                        value: '${cmd.produits.length}',
                      ),
                    ],
                  ),
                SizedBox(height: isPhone ? _baseUnit * 0.75 : _baseUnit * 1.5),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isPhone ? _baseUnit * 0.95 : _baseUnit * 1.25,
                    vertical: isPhone ? _baseUnit * 0.7 : _baseUnit,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(isPhone ? 10 : 12),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: isPhone ? 14 : 16,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _productsPreview(cmd),
                          maxLines: isPhone ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: isPhone ? 10.8 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!grid) ...[
                  SizedBox(
                    height: isPhone ? _baseUnit * 0.75 : _baseUnit * 1.5,
                  ),
                  if (isPhone)
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _onDetails(cmd),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 15,
                                ),
                                label: const Text('Details'),
                                style: _compactOutlinedButtonStyle(dense: true),
                              ),
                            ),
                            const SizedBox(width: _baseUnit * 0.75),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: canEdit ? () => _onEdit(cmd) : null,
                                icon: const Icon(Icons.edit_outlined, size: 15),
                                label: const Text('Modifier'),
                                style: _compactOutlinedButtonStyle(dense: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _baseUnit * 0.75),
                        if (canConfirm || canCancel)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: canConfirm
                                      ? () => _onConfirm(cmd)
                                      : null,
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 15,
                                  ),
                                  label: const Text('Confirmer'),
                                  style: _compactOutlinedButtonStyle(
                                    dense: true,
                                    foregroundColor: _success,
                                  ),
                                ),
                              ),
                              const SizedBox(width: _baseUnit * 0.75),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: canCancel
                                      ? () => _onCancel(cmd)
                                      : null,
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 15,
                                  ),
                                  label: const Text('Annuler'),
                                  style: _compactOutlinedButtonStyle(
                                    dense: true,
                                    foregroundColor: _error,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: _baseUnit,
                              vertical: _baseUnit * 0.9,
                            ),
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: _borderLight),
                            ),
                            child: const Text(
                              'Traitee',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: _baseUnit,
                      runSpacing: _baseUnit,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _onDetails(cmd),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text('Details'),
                          style: _compactOutlinedButtonStyle(),
                        ),
                        OutlinedButton.icon(
                          onPressed: canEdit ? () => _onEdit(cmd) : null,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifier'),
                          style: _compactOutlinedButtonStyle(),
                        ),
                        OutlinedButton.icon(
                          onPressed: canConfirm ? () => _onConfirm(cmd) : null,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Confirmer'),
                          style: _compactOutlinedButtonStyle(
                            foregroundColor: _success,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: canCancel ? () => _onCancel(cmd) : null,
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Annuler'),
                          style: _compactOutlinedButtonStyle(
                            foregroundColor: _error,
                          ),
                        ),
                      ],
                    ),
                ] else ...[
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Details',
                        onPressed: () => _onDetails(cmd),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        visualDensity: VisualDensity.compact,
                        onPressed: canEdit ? () => _onEdit(cmd) : null,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Confirmer',
                        visualDensity: VisualDensity.compact,
                        onPressed: canConfirm ? () => _onConfirm(cmd) : null,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                      ),
                      IconButton(
                        tooltip: 'Annuler',
                        visualDensity: VisualDensity.compact,
                        onPressed: canCancel ? () => _onCancel(cmd) : null,
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _productsPreview(CommandeModel cmd) {
    if (cmd.produits.isEmpty) return 'Aucun produit';
    final names = cmd.produits.map((p) => p.libelle).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names[0]} + ${names[1]} + ${names.length - 2} autres';
  }
}

class _DraftLine {
  final String rowKey;
  int? produitId;
  final TextEditingController quantiteController;
  final double? fallbackPrix;

  _DraftLine({
    required this.rowKey,
    this.produitId,
    int quantite = 1,
    this.fallbackPrix,
  }) : quantiteController = TextEditingController(text: '$quantite');

  void dispose() => quantiteController.dispose();
}

class _CommandeFormResult {
  final int clientId;
  final List<CommandeProduitPayload> produits;
  final double remiseTotale;
  final String? clientAdresse;
  final String? clientTelephone;
  final String? clientEmail;

  _CommandeFormResult({
    required this.clientId,
    required this.produits,
    required this.remiseTotale,
    this.clientAdresse,
    this.clientTelephone,
    this.clientEmail,
  });
}
