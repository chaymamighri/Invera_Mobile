import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/formulaire_commande.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';
import 'package:invera_mobile/widgets/approvisionnement/details_commande.dart';
import 'package:invera_mobile/widgets/approvisionnement/role_utilisateur.dart';
import 'package:invera_mobile/widgets/approvisionnement/reception.dart';

class ProcurementOrdersSection extends StatefulWidget {
  const ProcurementOrdersSection({super.key});

  @override
  State<ProcurementOrdersSection> createState() =>
      _ProcurementOrdersSectionState();
}

class _ProcurementOrdersSectionState extends State<ProcurementOrdersSection> {
  final ProcurementService _service = ProcurementService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _showArchived = false;
  String _statusFilter = '';
  bool _sortDateDescending = true;
  String? _actionInProgress;

  List<ProcurementOrder> _orders = const [];
  List<ProcurementSupplier> _suppliers = const [];
  List<ProcurementProduct> _products = const [];

  ProcurementUserRole get _role => ProcurementUserRole.responsableAchat;

  static const double _colOrder = 170;
  static const double _colSupplier = 220;
  static const double _colDate = 170;
  static const double _colTotal = 150;
  static const double _colStatus = 250;
  static const double _colActions = 170;
  static const double _rowHorizontalPadding = 18;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _service.getOrders(archived: _showArchived),
        _service.getSuppliers(activeOnly: false),
        _service.getProducts(),
      ]);

      if (!mounted) return;

      setState(() {
        _orders = results[0] as List<ProcurementOrder>;
        _suppliers = (results[1] as List<ProcurementSupplier>)
            .where((supplier) => supplier.actif)
            .toList();
        _products = results[2] as List<ProcurementProduct>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<ProcurementOrder> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _orders.where((order) {
      final matchesQuery =
          query.isEmpty ||
          order.referenceCommande.toLowerCase().contains(query) ||
          order.partenaireNom.toLowerCase().contains(query) ||
          (order.fournisseur?.email.toLowerCase().contains(query) ?? false);

      final matchesStatus =
          _statusFilter.isEmpty || order.normalizedStatus == _statusFilter;

      return matchesQuery && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final left = a.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sortDateDescending
          ? right.compareTo(left)
          : left.compareTo(right);
    });

    return filtered;
  }

  List<String> get _statusOptions {
    final options = <String>[...ProcurementOrderStatus.responsableAchatFlow];
    for (final order in _orders) {
      final status = order.normalizedStatus;
      if (status.isNotEmpty && !options.contains(status)) {
        options.add(status);
      }
    }
    return options;
  }

  bool get _hasActiveToolbarFilters =>
      _searchController.text.trim().isNotEmpty ||
      _statusFilter.isNotEmpty ||
      _showArchived;

  int get _activeToolbarFilterCount {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_statusFilter.isNotEmpty) count++;
    if (_showArchived) count++;
    return count;
  }

  void _resetToolbarFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = '';
      _showArchived = false;
    });
    _loadData();
  }

  Future<void> _showOrderDialog({ProcurementOrder? initial}) async {
    if (initial == null && _suppliers.isEmpty) {
      showMessage(
        context,
        'Aucun fournisseur actif disponible pour creer une commande.',
        error: true,
      );
      return;
    }

    Future<ProcurementOrderDialogResult?> openOrderFormDialog() {
      final useBottomSheet = MediaQuery.of(context).size.width < 600;

      if (useBottomSheet) {
        return showModalBottomSheet<ProcurementOrderDialogResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ProcurementOrderFormDialog(
            suppliers: _suppliers,
            products: _products,
            initialOrder: initial,
            isBottomSheet: true,
          ),
        );
      }

      return showDialog<ProcurementOrderDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ProcurementOrderFormDialog(
          suppliers: _suppliers,
          products: _products,
          initialOrder: initial,
        ),
      );
    }

    final result = await openOrderFormDialog();

    if (result == null) return;

    try {
      if (result.createPayload != null) {
        final created = await _service.createOrder(result.createPayload!);
        if (!mounted) return;
        setState(() {
          _orders = [created, ..._orders];
        });
        showMessage(context, 'Commande creee avec succes.');
      } else if (result.updatePayload != null && initial != null) {
        final updated = await _service.updateOrder(
          initial.idCommandeFournisseur,
          result.updatePayload!,
        );
        if (!mounted) return;
        setState(() {
          _orders = [
            for (final order in _orders)
              if (order.idCommandeFournisseur == updated.idCommandeFournisseur)
                updated
              else
                order,
          ];
        });
        showMessage(context, 'Commande mise a jour.');
      }
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _showOrderDetails(ProcurementOrder order) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CommandeDetailsModal(order: order),
    );
  }

  Future<void> _restoreOrder(ProcurementOrder order) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Restaurer la commande',
      message: 'Restaurer ${order.referenceCommande} ?',
      confirmLabel: 'Restaurer',
      confirmColor: const Color(0xFF16A34A),
    );

    if (confirmed != true) return;

    try {
      await _service.restoreOrder(order.idCommandeFournisseur);
      if (!mounted) return;
      await _loadData();
      if (!mounted) return;
      showMessage(context, 'Commande restauree avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _runOrderAction(
    ProcurementOrder order, {
    required String actionKey,
    required Future<ProcurementOrder> Function() action,
    required String title,
    required String message,
    required String confirmLabel,
    required String successMessage,
    Color confirmColor = const Color(0xFF2563EB),
  }) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    );

    if (confirmed != true) return;

    setState(() {
      _actionInProgress = actionKey;
    });

    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _orders = [
          for (final item in _orders)
            if (item.idCommandeFournisseur == updated.idCommandeFournisseur)
              updated
            else
              item,
        ];
        _actionInProgress = null;
      });
      showMessage(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = null;
      });
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _rejectOrder(ProcurementOrder order) async {
    final controller = TextEditingController();
    final useBottomSheet = MediaQuery.sizeOf(context).width < 600;

    final motif = useBottomSheet
        ? await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (dialogContext) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  MediaQuery.viewInsetsOf(dialogContext).bottom > 0
                      ? MediaQuery.viewInsetsOf(dialogContext).bottom
                      : 12,
                ),
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Rejeter ${order.referenceCommande}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: procurementInk,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Motif du rejet',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: controller,
                            minLines: 3,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Expliquez le motif du rejet...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    final value = controller.text.trim();
                                    if (value.isEmpty) return;
                                    Navigator.pop(dialogContext, value);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: procurementWarning,
                                  ),
                                  child: const Text('Rejeter'),
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
            },
          )
        : await showDialog<String>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text('Rejeter ${order.referenceCommande}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Motif du rejet',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Expliquez le motif du rejet...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Annuler'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isEmpty) return;
                      Navigator.pop(dialogContext, value);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: procurementWarning,
                    ),
                    child: const Text('Rejeter'),
                  ),
                ],
              );
            },
          );

    controller.dispose();
    if (!mounted) return;

    if (motif == null || motif.isEmpty) return;

    setState(() {
      _actionInProgress = 'reject-${order.idCommandeFournisseur}';
    });

    try {
      final updated = await _service.rejectOrder(
        order.idCommandeFournisseur,
        motif,
      );
      if (!mounted) return;
      setState(() {
        _orders = [
          for (final item in _orders)
            if (item.idCommandeFournisseur == updated.idCommandeFournisseur)
              updated
            else
              item,
        ];
        _actionInProgress = null;
      });
      showMessage(context, 'Commande rejetee avec succes.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = null;
      });
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _receiveOrder(ProcurementOrder order) async {
    final useBottomSheet = MediaQuery.sizeOf(context).width < 600;

    final payload = useBottomSheet
        ? await showModalBottomSheet<ReceptionModalResult>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ReceptionModal(order: order, isBottomSheet: true),
          )
        : await showDialog<ReceptionModalResult>(
            context: context,
            barrierDismissible: false,
            builder: (_) => ReceptionModal(order: order),
          );

    if (!mounted) return;
    if (payload == null) return;

    setState(() {
      _actionInProgress = 'receive-${order.idCommandeFournisseur}';
    });

    try {
      final updated = await _service.receiveOrder(
        order.idCommandeFournisseur,
        quantitesRecues: payload.quantitesRecues,
        numeroBL: payload.numeroBL,
        produitsAReactiver: payload.produitsAReactiver,
      );
      if (!mounted) return;
      setState(() {
        _orders = [
          for (final item in _orders)
            if (item.idCommandeFournisseur == updated.idCommandeFournisseur)
              updated
            else
              item,
        ];
        _actionInProgress = null;
      });
      showMessage(context, 'Reception enregistree avec succes.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = null;
      });
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  String _formatCompactAmount(num value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k TND';
    }
    return formatPrice(value);
  }

  int _countOrdersByStatuses(Set<String> statuses) {
    return _filteredOrders
        .where((order) => statuses.contains(order.normalizedStatus))
        .length;
  }

  double get _visibleTotalAmount =>
      _filteredOrders.fold<double>(0, (sum, order) => sum + order.totalTTC);

  Future<void> _openCompactToolbarSheet() async {
    var draftStatus = _statusFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            void resetDraft() {
              modalSetState(() {
                draftStatus = '';
              });
            }

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: procurementSurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: procurementLine),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140D1B2A),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Filtres commandes',
                          style: TextStyle(
                            color: procurementInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (draftStatus.isNotEmpty)
                          TextButton(
                            onPressed: resetDraft,
                            child: const Text('Effacer'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>('orders-sheet-status-$draftStatus'),
                      initialValue: draftStatus.isEmpty ? null : draftStatus,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Tous les statuts'),
                        ),
                        ..._statusOptions.map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(orderStatusLabel(status)),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        modalSetState(() {
                          draftStatus = value ?? '';
                        });
                      },
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
                            setState(() {
                              _statusFilter = draftStatus;
                            });
                            Navigator.of(sheetContext).pop();
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

  List<Widget> _buildActions(ProcurementOrder order) {
    final widgets = <Widget>[];
    final id = order.idCommandeFournisseur;
    final isArchived = _showArchived;

    void addIcon({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
      Color? color,
      bool filled = false,
    }) {
      final child = Icon(icon, size: 20);
      final button = filled
          ? FilledButton.tonal(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                foregroundColor: color,
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: child,
            )
          : IconButton(
              onPressed: onPressed,
              tooltip: tooltip,
              icon: child,
              color: color,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: (color ?? procurementMuted).withValues(
                  alpha: 0.08,
                ),
                side: BorderSide(
                  color: (color ?? procurementMuted).withValues(alpha: 0.16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );

      widgets.add(Tooltip(message: tooltip, child: button));
    }

    final canEdit = ProcurementOrderActionPolicy.canEdit(
      order,
      _role,
      showArchives: isArchived,
    );
    final canValidate = ProcurementOrderActionPolicy.canValidate(
      order,
      _role,
      showArchives: isArchived,
    );
    final canReject = ProcurementOrderActionPolicy.canReject(
      order,
      _role,
      showArchives: isArchived,
    );
    final canResend = ProcurementOrderActionPolicy.canResendAfterRejection(
      order,
      _role,
      showArchives: isArchived,
    );
    final canSend = ProcurementOrderActionPolicy.canSend(
      order,
      _role,
      showArchives: isArchived,
    );
    final canReceive = ProcurementOrderActionPolicy.canReceive(
      order,
      _role,
      showArchives: isArchived,
    );
    final canRestore = ProcurementOrderActionPolicy.canRestore(
      showArchives: isArchived,
    );

    if (canEdit) {
      addIcon(
        icon: Icons.edit_outlined,
        tooltip: 'Modifier',
        color: const Color(0xFFF59E0B),
        onPressed: () => _showOrderDialog(initial: order),
      );
    }

    if (canValidate) {
      addIcon(
        icon: Icons.verified_outlined,
        tooltip: 'Valider',
        color: procurementPrimary,
        onPressed: _actionInProgress == 'validate-$id'
            ? null
            : () => _runOrderAction(
                order,
                actionKey: 'validate-$id',
                action: () => _service.validateOrder(id),
                title: 'Valider la commande',
                message: 'Valider ${order.referenceCommande} ?',
                confirmLabel: 'Valider',
                successMessage: 'Commande validee avec succes.',
              ),
      );
    }

    if (canReject) {
      addIcon(
        icon: Icons.cancel_outlined,
        tooltip: 'Rejeter',
        color: procurementWarning,
        onPressed: _actionInProgress == 'reject-$id'
            ? null
            : () => _rejectOrder(order),
      );
    }

    if (canResend) {
      addIcon(
        icon: Icons.autorenew,
        tooltip: 'Renvoyer en attente',
        color: procurementPrimary,
        onPressed: _actionInProgress == 'resend-$id'
            ? null
            : () => _runOrderAction(
                order,
                actionKey: 'resend-$id',
                action: () => _service.resendOrderAfterRejection(id),
                title: 'Renvoyer la commande',
                message:
                    'Renvoyer ${order.referenceCommande} en attente apres correction ?',
                confirmLabel: 'Renvoyer',
                successMessage: 'Commande renvoyee en attente.',
              ),
      );
    }

    if (canSend) {
      addIcon(
        icon: Icons.send_outlined,
        tooltip: 'Envoyer',
        color: procurementPrimary,
        onPressed: _actionInProgress == 'send-$id'
            ? null
            : () => _runOrderAction(
                order,
                actionKey: 'send-$id',
                action: () => _service.sendOrder(id),
                title: 'Envoyer la commande',
                message: 'Envoyer ${order.referenceCommande} au fournisseur ?',
                confirmLabel: 'Envoyer',
                successMessage: 'Commande envoyee avec succes.',
              ),
      );
    }

    if (canReceive) {
      addIcon(
        icon: Icons.local_shipping_outlined,
        tooltip: 'Receptionner',
        color: procurementAccent,
        onPressed: _actionInProgress == 'receive-$id'
            ? null
            : () => _receiveOrder(order),
      );
    }

    addIcon(
      icon: Icons.visibility_outlined,
      tooltip: 'Details',
      color: const Color(0xFF64748B),
      onPressed: () => _showOrderDetails(order),
    );

    if (canRestore) {
      addIcon(
        icon: Icons.restore_outlined,
        tooltip: 'Restaurer',
        color: procurementAccent,
        onPressed: () => _restoreOrder(order),
      );
    }

    return widgets;
  }

  Widget _buildToolbar() {
    final isPhone = AdaptiveLayout.isPhone(context);

    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              hintText: 'Rechercher par numero ou fournisseur...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _openCompactToolbarSheet,
                icon: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: _hasActiveToolbarFilters
                      ? procurementPrimary
                      : procurementMuted,
                ),
                label: Text(
                  _hasActiveToolbarFilters
                      ? 'Filtres ($_activeToolbarFilterCount)'
                      : 'Filtres',
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _hasActiveToolbarFilters
                      ? procurementPrimary.withValues(alpha: 0.10)
                      : procurementSoftBackground,
                  side: BorderSide(
                    color: _hasActiveToolbarFilters
                        ? procurementPrimary.withValues(alpha: 0.28)
                        : procurementLine,
                  ),
                  foregroundColor: _hasActiveToolbarFilters
                      ? procurementPrimaryDark
                      : procurementInk,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              FilterChip(
                selected: _showArchived,
                visualDensity: VisualDensity.compact,
                onSelected: (value) async {
                  setState(() {
                    _showArchived = value;
                  });
                  await _loadData();
                },
                label: Text(_showArchived ? 'Archives' : 'Actives'),
                avatar: Icon(
                  _showArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 17,
                  color: _showArchived ? procurementPrimary : procurementMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: procurementSoftBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: procurementLine),
                ),
                child: Text(
                  '${_filteredOrders.length} commandes',
                  style: const TextStyle(
                    color: procurementMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_hasActiveToolbarFilters)
                OutlinedButton.icon(
                  onPressed: _resetToolbarFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              if (_role == ProcurementUserRole.responsableAchat &&
                  !_showArchived) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showOrderDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle'),
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    return SectionSurface(
      title: 'Pilotage des commandes',
      subtitle:
          'Recherche, filtres et actions adaptees au telephone comme au web',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'Rechercher par numero ou fournisseur...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter.isEmpty ? null : _statusFilter,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Tous les statuts'),
                    ),
                    ..._statusOptions.map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(orderStatusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value ?? '';
                    });
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  setState(() {
                    _showArchived = !_showArchived;
                  });
                  await _loadData();
                },
                icon: Icon(
                  _showArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(
                  _showArchived ? 'Retour aux actives' : 'Afficher archives',
                ),
              ),
              if (_role == ProcurementUserRole.responsableAchat &&
                  !_showArchived)
                FilledButton.icon(
                  onPressed: () => _showOrderDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle commande'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MiniMetric(
                label: 'Commandes visibles',
                value: '${_filteredOrders.length}',
                color: procurementPrimary,
              ),
              MiniMetric(
                label: 'En cours',
                value:
                    '${_countOrdersByStatuses(const {ProcurementOrderStatus.brouillon, ProcurementOrderStatus.validee, ProcurementOrderStatus.envoyee, ProcurementOrderStatus.rejetee})}',
                color: procurementWarning,
              ),
              MiniMetric(
                label: 'A facturer',
                value:
                    '${_countOrdersByStatuses(const {ProcurementOrderStatus.recue})}',
                color: procurementAccent,
              ),
              MiniMetric(
                label: 'Montant visible',
                value: _formatCompactAmount(_visibleTotalAmount),
                color: procurementPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _rowHorizontalPadding,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colOrder,
            child: Text(
              'N° commande',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
          SizedBox(
            width: _colSupplier,
            child: Text(
              'Fournisseur',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
          SizedBox(
            width: _colDate,
            child: InkWell(
              onTap: () {
                setState(() {
                  _sortDateDescending = !_sortDateDescending;
                });
              },
              child: Row(
                children: [
                  const Text(
                    'Date commande',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: procurementMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _sortDateDescending
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 16,
                    color: procurementPrimary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            width: _colTotal,
            child: Text(
              'Total TTC',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
          const SizedBox(
            width: _colStatus,
            child: Text(
              'Statut',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
          const SizedBox(
            width: _colActions,
            child: Text(
              'Actions',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(ProcurementOrder order) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _rowHorizontalPadding,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: _showArchived ? const Color(0xFFF8FAFC) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _colOrder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.referenceCommande,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: procurementInk,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _colSupplier,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.partenaireNom,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (order.fournisseur?.email.trim().isNotEmpty == true)
                  Text(
                    order.fournisseur!.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: procurementMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: _colDate,
            child: Text(
              formatDate(order.dateCommande, withTime: true),
              style: const TextStyle(color: procurementMuted),
            ),
          ),
          SizedBox(
            width: _colTotal,
            child: Text(
              formatPrice(order.totalTTC),
              style: const TextStyle(
                color: procurementPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: _colStatus,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ProcurementStatusBadge(status: order.statut),
                if (order.motifRejet?.trim().isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: procurementDanger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Motif du rejet : ${order.motifRejet!}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: procurementDanger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_showArchived)
                  const StatusPill(label: 'Archivee', color: Color(0xFF64748B)),
              ],
            ),
          ),
          SizedBox(
            width: _colActions,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.end,
                children: _buildActions(order),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final rows = _filteredOrders;

    if (rows.isEmpty) {
      return EmptyPanel(
        title: _showArchived
            ? 'Aucune commande archivee'
            : 'Aucune commande trouvee',
        message: _showArchived
            ? 'Les commandes supprimees apparaitront ici.'
            : 'Aucune commande ne correspond aux filtres actuels.',
      );
    }

    final tableWidth =
        (_rowHorizontalPadding * 2) +
        _colOrder +
        _colSupplier +
        _colDate +
        _colTotal +
        _colStatus +
        _colActions;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: procurementSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: procurementLine),
        boxShadow: procurementCardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          child: Column(
            children: [
              _buildHeaderRow(),
              for (final order in rows) _buildOrderRow(order),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingPanel(message: 'Chargement des commandes...');
    }

    if (_error != null) {
      return AsyncErrorCard(
        title: 'Impossible de charger les commandes',
        message: _error!,
        onRetry: _loadData,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(),
            const SizedBox(height: 20),
            _buildTable(),
          ],
        );
      },
    );
  }
}
