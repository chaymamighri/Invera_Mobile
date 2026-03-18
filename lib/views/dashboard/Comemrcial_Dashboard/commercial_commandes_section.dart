import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_globals.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';

// ---------- THEME CONSTANTS (reuse from clients section) ----------
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

// ---------- REUSABLE WIDGETS ----------
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    late Color bg, fg;

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
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
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
          Text(
            '$label: ',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- MAIN SECTION ----------
class CommercialCommandesSection extends StatefulWidget {
  const CommercialCommandesSection({super.key});

  @override
  State<CommercialCommandesSection> createState() =>
      _CommercialCommandesSectionState();
}

class _CommercialCommandesSectionState extends State<CommercialCommandesSection>
    with TickerProviderStateMixin {
  final CommandeService _commandeService = CommandeService();
  final ClientService _clientService = ClientService();

  List<CommandeModel> _commandes = [];
  List<ClientModel> _clients = [];
  List<ProduitOption> _produits = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  String _statusFilter = 'TOUS';
  int _draftLineSeed = 0;

  static const List<String> _statuses = [
    'TOUS',
    'EN_ATTENTE',
    'CONFIRMEE',
    'ANNULEE',
  ];

  bool _useGrid = false;

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
      final results = await Future.wait([
        _commandeService.getCommandes(),
        _clientService.getClients(),
        _commandeService.getProduits(),
      ]);
      if (!mounted) return;

      setState(() {
        _commandes = _sortCommandesByCreation(
          results[0] as List<CommandeModel>,
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
    if (showBusy && mounted) setState(() => _isBusy = true);

    try {
      final statut = _statusFilter == 'TOUS' ? null : _statusFilter;
      final data = await _commandeService.getCommandes(statut: statut);
      if (!mounted) return;
      setState(() => _commandes = _sortCommandesByCreation(data));
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (showBusy && mounted) setState(() => _isBusy = false);
    }
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
      if (mounted) _showMessage(e.toString(), isError: true);
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
      if (mounted) _showMessage(e.toString(), isError: true);
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
      _showMessage('Commande confirmée');
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
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
      if (mounted) _showMessage(e.toString(), isError: true);
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

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: AdaptiveLayout.dialogWidth(ctx, max: 1000, sideMargin: 12),
            constraints: BoxConstraints(
              maxHeight: AdaptiveLayout.dialogHeight(ctx, ratio: 0.9),
            ),
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
                            'Détails de la commande',
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
                    _StatusChip(status: cmd.statut),
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
                              title: 'Informations générales',
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
                                    label: 'Référence',
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
                              title: 'Coordonnées client',
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.person_outline,
                                    label: 'Nom complet',
                                    value: client?.fullName ?? '-',
                                  ),
                                  _buildDetailRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Téléphone',
                                    value: client?.telephone ?? '-',
                                  ),
                                  _buildDetailRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: client?.email ?? '-',
                                  ),
                                  _buildDetailRow(
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
                              title: 'Produits commandés',
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
                                      final index = entry.key;
                                      final p = entry.value;
                                      return _buildProduitDetailCard(
                                        index: index + 1,
                                        produit: p,
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
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Statut',
                                    value: _displayStatus(cmd.statut),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Remise appliquée',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  const Divider(color: _borderLight),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  _buildAmountRow(
                                    'Sous-total estimé',
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
                                        margin: EdgeInsets.only(
                                          bottom: _baseUnit,
                                        ),
                                        padding: EdgeInsets.all(
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
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _success,
                          foregroundColor: Colors.white,
                        ),
                      ),
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

  Future<_CommandeFormResult?> _openCommandeForm({
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

              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              final produits = _buildProduitPayload(lines);
              Navigator.of(dialogContext, rootNavigator: true).pop(
                _CommandeFormResult(
                  clientId: selectedClientId!,
                  produits: produits,
                  remiseTotale: remiseValue(),
                  clientAdresse: null,
                  clientTelephone: null,
                  clientEmail: null,
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: AdaptiveLayout.dialogWidth(
                  dialogContext,
                  max: 980,
                  sideMargin: 12,
                ),
                constraints: BoxConstraints(
                  maxHeight: AdaptiveLayout.dialogHeight(
                    dialogContext,
                    ratio: 0.9,
                  ),
                ),
                padding: EdgeInsets.all(_baseUnit * 3),
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _baseUnit * 1.5,
                              vertical: _baseUnit,
                            ),
                            decoration: BoxDecoration(
                              color: _background,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: _borderLight),
                            ),
                            child: Text(
                              'Interface unique',
                              style: TextStyle(
                                color: _primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: _baseUnit),
                          IconButton(
                            onPressed: () => Navigator.of(
                              dialogContext,
                              rootNavigator: true,
                            ).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: _baseUnit * 2),
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
                                        child: Column(
                                          children: [
                                            DropdownButtonFormField<int>(
                                              initialValue: selectedClientId,
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
                                                return DropdownMenuItem(
                                                  value: c.id,
                                                  child: Text(
                                                    '${c.nom} (${c.telephone})',
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: isEdit
                                                  ? null
                                                  : (v) => setModal(() {
                                                      selectedClientId = v;
                                                      remiseCtrl.text =
                                                          clientRemisePercent(
                                                            findClientById(v),
                                                          ).toStringAsFixed(2);
                                                    }),
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
                                                if (value == null) {
                                                  return 'Valeur invalide';
                                                }
                                                if (value < 0 || value > 100) {
                                                  return 'Entre 0 et 100';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: _baseUnit * 2),
                                      _buildFormSection(
                                        title: 'Produits',
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
                                                  bottom: _baseUnit * 1.5,
                                                ),
                                                padding: EdgeInsets.all(
                                                  _baseUnit * 1.5,
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
                                                      initialValue:
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
                                                        return DropdownMenuItem(
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
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      _baseUnit *
                                                                      1.5,
                                                                  vertical:
                                                                      _baseUnit *
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
                                                                        12,
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
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      _baseUnit *
                                                                      1.5,
                                                                  vertical:
                                                                      _baseUnit *
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
                                                                        12,
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSummaryTile(
                                          label: 'Client',
                                          value: selectedClient()?.nom ?? '-',
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Téléphone',
                                          value:
                                              selectedClient()?.telephone ??
                                              '-',
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Nombre de lignes',
                                          value: '${lines.length}',
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildSummaryTile(
                                          label: 'Remise',
                                          value:
                                              '${remiseValue().toStringAsFixed(2)}%',
                                        ),
                                        const SizedBox(height: _baseUnit * 1.5),
                                        const Divider(color: _borderLight),
                                        const SizedBox(height: _baseUnit * 1.5),
                                        _buildAmountRow(
                                          'Sous-total',
                                          '${subTotal().toStringAsFixed(2)} DT',
                                        ),
                                        const SizedBox(height: _baseUnit),
                                        _buildAmountRow(
                                          'Total final',
                                          '${totalAfterRemise().toStringAsFixed(2)} DT',
                                          isPrimary: true,
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
                                              margin: EdgeInsets.only(
                                                bottom: _baseUnit,
                                              ),
                                              padding: EdgeInsets.all(
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
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton.icon(
                            onPressed: save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(isEdit ? 'Enregistrer' : 'Créer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: _baseUnit * 2,
                                vertical: _baseUnit * 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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

    // Important fix:
    // wait until the dialog is fully removed from the widget tree
    // before disposing controllers used by TextFormField.
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

  Widget _buildFormSection({required String title, required Widget child}) {
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

  Widget _buildDetailRow({
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
    required dynamic produit,
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
              _InfoBadge(label: 'Quantité', value: '${produit.quantite}'),
              _InfoBadge(
                label: 'Prix unitaire',
                value: '${produit.prixUnitaire.toStringAsFixed(2)} DT',
              ),
              _InfoBadge(
                label: 'Sous-total',
                value: '${produit.sousTotal.toStringAsFixed(2)} DT',
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
    return _produits
        .where(
          (p) =>
              p.idProduit == currentLine.produitId ||
              !selected.contains(p.idProduit),
        )
        .toList();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: _error, size: 48),
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          if (_isBusy)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_commandes.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
          else
            ..._buildOrderSlivers(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _baseUnit * 2,
        _baseUnit * 2,
        _baseUnit * 2,
        _baseUnit,
      ),
      child: Column(
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
                  children: const [
                    Text(
                      'Commandes Commerciales',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Workflow de vente, suivi et actions sur commandes dans une interface unifiée.',
                      style: TextStyle(color: Color(0xFFE3EBFF), fontSize: 13),
                    ),
                  ],
                );

                final counter = _buildCountPill(
                  _commandes.length,
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
                final compact = constraints.maxWidth < 760;
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
                      _buildStatusFilter(),
                      const SizedBox(height: _baseUnit * 1.5),
                      Wrap(
                        spacing: _baseUnit,
                        runSpacing: _baseUnit,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isBusy ? null : _onCreate,
                            icon: const Icon(Icons.add),
                            label: const Text('Nouvelle commande'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isBusy
                                ? null
                                : () => _reloadCommandes(showBusy: true),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualiser'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _useGrid = !_useGrid),
                            icon: Icon(
                              _useGrid
                                  ? Icons.view_agenda_outlined
                                  : Icons.grid_view_rounded,
                            ),
                            label: Text(_useGrid ? 'Vue liste' : 'Vue grille'),
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
                        ),
                        const SizedBox(width: _baseUnit),
                        ElevatedButton.icon(
                          onPressed: _isBusy ? null : _onCreate,
                          icon: const Icon(Icons.add),
                          label: const Text('Nouvelle commande'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
    setState(() => _statusFilter = status);
    _reloadCommandes(showBusy: true);
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

  Widget _buildStatusFilter() {
    final icons = <String, IconData>{
      'TOUS': Icons.all_inbox_outlined,
      'EN_ATTENTE': Icons.hourglass_top_outlined,
      'CONFIRMEE': Icons.verified_outlined,
      'ANNULEE': Icons.block_outlined,
    };

    return Wrap(
      spacing: _baseUnit,
      runSpacing: _baseUnit,
      children: _statuses.map((status) {
        final selected = _statusFilter == status;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icons[status] ?? Icons.tune,
                size: 16,
                color: selected ? _primaryDark : _textSecondary,
              ),
              const SizedBox(width: 6),
              Text(status == 'TOUS' ? 'Tous' : _displayStatus(status)),
            ],
          ),
          selected: selected,
          selectedColor: _primary.withValues(alpha: 0.16),
          backgroundColor: _surface,
          side: BorderSide(color: selected ? _primary : _borderLight),
          labelStyle: TextStyle(
            color: selected ? _primaryDark : _textPrimary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
          onSelected: (_) => _setFilter(status),
        );
      }).toList(),
    );
  }

  String _displayStatus(String raw) {
    if (raw == 'EN_ATTENTE') return 'En attente';
    if (raw == 'CONFIRMEE') return 'Confirmée';
    if (raw == 'ANNULEE') return 'Annulée';
    return raw;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(_baseUnit * 4),
        margin: EdgeInsets.all(_baseUnit * 2),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: _textSecondary),
            const SizedBox(height: _baseUnit * 2),
            const Text(
              'Aucune commande disponible',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: _baseUnit),
            const Text(
              'Créez votre première commande en cliquant sur le bouton ci-dessous.',
              style: TextStyle(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _baseUnit * 2),
            ElevatedButton.icon(
              onPressed: _isBusy ? null : _onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Créer une commande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderSlivers() {
    if (_useGrid) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _baseUnit * 2,
            _baseUnit,
            _baseUnit * 2,
            _baseUnit * 2,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 430,
              crossAxisSpacing: _baseUnit * 2,
              mainAxisSpacing: _baseUnit * 2,
              mainAxisExtent: 300,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildOrderCard(_commandes[index], grid: true);
            }, childCount: _commandes.length),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          _baseUnit * 2,
          _baseUnit,
          _baseUnit * 2,
          _baseUnit * 2,
        ),
        sliver: SliverList.builder(
          itemCount: _commandes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(bottom: _baseUnit * 1.5),
              child: _buildOrderCard(_commandes[index], grid: false),
            );
          },
        ),
      ),
    ];
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

  Widget _buildOrderCard(CommandeModel cmd, {required bool grid}) {
    final canEdit = !_isBusy && cmd.canEdit;
    final canCancel = !_isBusy && cmd.canCancel;
    final canConfirm = _canConfirm(cmd);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _onDetails(cmd),
          child: Padding(
            padding: EdgeInsets.all(_baseUnit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    _StatusChip(status: cmd.statut),
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
                      value: '${cmd.total.toStringAsFixed(2)} DT',
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
                          _productsPreview(cmd),
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
                if (!grid) ...[
                  const SizedBox(height: _baseUnit * 1.5),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: _baseUnit,
                    runSpacing: _baseUnit,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _onDetails(cmd),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Détails'),
                      ),
                      OutlinedButton.icon(
                        onPressed: canEdit ? () => _onEdit(cmd) : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier'),
                      ),
                      OutlinedButton.icon(
                        onPressed: canConfirm ? () => _onConfirm(cmd) : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirmer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _success,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: canCancel ? () => _onCancel(cmd) : null,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Annuler'),
                        style: OutlinedButton.styleFrom(
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
                        tooltip: 'Détails',
                        onPressed: () => _onDetails(cmd),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Modifier',
                        onPressed: canEdit ? () => _onEdit(cmd) : null,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Confirmer',
                        onPressed: canConfirm ? () => _onConfirm(cmd) : null,
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Annuler',
                        onPressed: canCancel ? () => _onCancel(cmd) : null,
                        icon: const Icon(Icons.cancel_outlined),
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

// Helper classes
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
