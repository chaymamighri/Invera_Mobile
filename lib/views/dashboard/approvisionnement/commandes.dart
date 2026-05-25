import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/facture_pdf.dart';
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
  int _currentPage = 1;
  int _itemsPerPage = 10;
  String? _actionInProgress;

  List<ProcurementOrder> _orders = const [];
  List<ProcurementSupplier> _suppliers = const [];
  List<ProcurementProduct> _products = const [];

  ProcurementUserRole get _role => ProcurementRoleStore.instance.role;

  static const double _colOrder = 170;
  static const double _colSupplier = 220;
  static const double _colDate = 170;
  static const double _colTotal = 150;
  static const double _colStatus = 210;
  static const double _colActions = 236;
  static const double _rowHorizontalPadding = 18;

  @override
  void initState() {
    super.initState();
    ProcurementRoleStore.instance.addListener(_onRoleChanged);
    _loadData();
  }

  @override
  void dispose() {
    ProcurementRoleStore.instance.removeListener(_onRoleChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRoleChanged() {
    if (!mounted) return;
    setState(() {});
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
      return right.compareTo(left);
    });

    return filtered;
  }

  int get _totalPages {
    final total = _filteredOrders.length;
    if (total == 0) return 1;
    return (total / _itemsPerPage).ceil();
  }

  List<ProcurementOrder> get _paginatedOrders {
    final filtered = _filteredOrders;
    final safePage = _currentPage.clamp(1, _totalPages);
    final start = (safePage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return const [];
    return filtered.sublist(start, end);
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

    final result = await showDialog<ProcurementOrderDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProcurementOrderFormDialog(
        suppliers: _suppliers,
        products: _products,
        initialOrder: initial,
      ),
    );

    if (result == null) return;

    try {
      if (result.createPayload != null) {
        final created = await _service.createOrder(result.createPayload!);
        if (!mounted) return;
        setState(() {
          _orders = [created, ..._orders];
          _currentPage = 1;
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

  Future<void> _deleteOrder(ProcurementOrder order) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Supprimer la commande',
      message: 'Supprimer ${order.referenceCommande} des commandes actives ?',
      confirmLabel: 'Supprimer',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      await _service.deleteOrder(order.idCommandeFournisseur);
      if (!mounted) return;
      setState(() {
        _orders = _orders
            .where(
              (item) =>
                  item.idCommandeFournisseur != order.idCommandeFournisseur,
            )
            .toList();
      });
      showMessage(context, 'Commande archivee avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
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

    final motif = await showDialog<String>(
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
    final payload = await showDialog<ReceptionModalResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceptionModal(order: order),
    );

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

  Future<void> _invoiceOrder(ProcurementOrder order) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Facturer la commande',
      message: 'Marquer ${order.referenceCommande} comme facturee ?',
      confirmLabel: 'Facturer',
      confirmColor: procurementPurple,
    );

    if (confirmed != true) return;

    final billedAt = DateTime.now();

    setState(() {
      _actionInProgress = 'invoice-${order.idCommandeFournisseur}';
    });

    try {
      final updated = await _service.invoiceOrder(order.idCommandeFournisseur);
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

      try {
        await _exportInvoicePdf(
          updated,
          billedAt: billedAt,
          showSuccess: false,
        );
        if (!mounted) return;
        showMessage(context, 'Commande facturee. PDF pret.');
      } catch (error) {
        if (!mounted) return;
        showMessage(
          context,
          'Commande facturee, mais le PDF n\'a pas pu etre genere: ${error.toString().replaceFirst('Exception: ', '')}',
          error: true,
        );
      }
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

  Future<void> _exportInvoicePdf(
    ProcurementOrder order, {
    DateTime? billedAt,
    bool showSuccess = true,
  }) async {
    final facture = buildProcurementFactureModelFromOrder(
      order,
      billedAt: billedAt,
    );
    await exportProcurementInvoicePdf(order, facture);
    if (!mounted || !showSuccess) return;
    showMessage(context, 'PDF ${facture.referenceFactureClient} genere.');
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

    final canDelete = ProcurementOrderActionPolicy.canDelete(
      order,
      _role,
      showArchives: isArchived,
    );
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
    final canInvoice = ProcurementOrderActionPolicy.canInvoice(
      order,
      _role,
      showArchives: isArchived,
    );
    final canRestore = ProcurementOrderActionPolicy.canRestore(
      showArchives: isArchived,
    );

    if (canDelete) {
      addIcon(
        icon: Icons.delete_outline,
        tooltip: 'Supprimer',
        color: procurementDanger,
        onPressed: () => _deleteOrder(order),
      );
    }

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

    if (canInvoice) {
      addIcon(
        icon: order.normalizedStatus == ProcurementOrderStatus.facturee
            ? Icons.picture_as_pdf_outlined
            : Icons.receipt_long_outlined,
        tooltip: order.normalizedStatus == ProcurementOrderStatus.facturee
            ? 'PDF facture'
            : 'Facturer',
        color: procurementPurple,
        onPressed: _actionInProgress == 'invoice-$id'
            ? null
            : () {
                if (order.normalizedStatus == ProcurementOrderStatus.facturee) {
                  _exportInvoicePdf(order);
                } else {
                  _invoiceOrder(order);
                }
              },
      );
    }

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

    return SectionSurface(
      title: 'Pilotage des commandes',
      subtitle:
          'Recherche, filtres, pagination et actions adaptees au telephone comme au web',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPhone) ...[
            TextField(
              controller: _searchController,
              onChanged: (_) {
                setState(() {
                  _currentPage = 1;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Rechercher par numero ou fournisseur...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _statusFilter.isEmpty ? null : _statusFilter,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Tous les statuts'),
                      ),
                      ...ProcurementOrderStatus.all.map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(orderStatusLabel(status)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? '';
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _itemsPerPage,
                    decoration: const InputDecoration(labelText: 'Par page'),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _itemsPerPage = value;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _showArchived = !_showArchived;
                      _currentPage = 1;
                    });
                    await _loadData();
                  },
                  icon: Icon(
                    _showArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(_showArchived ? 'Retour actives' : 'Archives'),
                ),
                if (_role == ProcurementUserRole.responsableAchat &&
                    !_showArchived)
                  FilledButton.icon(
                    onPressed: () => _showOrderDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle'),
                  ),
              ],
            ),
          ] else
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
                      setState(() {
                        _currentPage = 1;
                      });
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
                      ...ProcurementOrderStatus.all.map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(orderStatusLabel(status)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? '';
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<int>(
                    initialValue: _itemsPerPage,
                    decoration: const InputDecoration(labelText: 'Par page'),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _itemsPerPage = value;
                        _currentPage = 1;
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
                      _currentPage = 1;
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
      child: const Row(
        children: [
          SizedBox(
            width: _colOrder,
            child: Text(
              'No commande',
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
            child: Text(
              'Date commande',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: procurementMuted,
              ),
            ),
          ),
          SizedBox(
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
          SizedBox(
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
          SizedBox(
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
                if (order.motifRejet?.trim().isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Motif: ${order.motifRejet!}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: procurementDanger,
                      ),
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

  Widget _buildOrderMeta(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: procurementMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: procurementLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: procurementMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? procurementInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ProcurementOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _showArchived ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: procurementLine),
        boxShadow: procurementCardShadow,
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
                      order.referenceCommande,
                      style: const TextStyle(
                        color: procurementInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.partenaireNom,
                      style: const TextStyle(
                        color: procurementMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: procurementPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: procurementPrimary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  formatPrice(order.totalTTC),
                  style: const TextStyle(
                    color: procurementPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (order.motifRejet?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: procurementDanger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: procurementDanger.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                'Motif du rejet: ${order.motifRejet!}',
                style: const TextStyle(
                  color: procurementDanger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ProcurementStatusBadge(status: order.statut),
              StatusPill(
                label: formatDate(order.dateCommande, withTime: true),
                color: procurementPrimary,
              ),
              if (_showArchived)
                const StatusPill(label: 'Archivee', color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildOrderMeta('Fournisseur', order.partenaireNom),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOrderMeta(
                  'Email',
                  order.fournisseur?.email.trim().isNotEmpty == true
                      ? order.fournisseur!.email
                      : 'Non renseigne',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Actions rapides',
            style: TextStyle(
              color: procurementInk.withValues(alpha: 0.78),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _buildActions(order)),
        ],
      ),
    );
  }

  Widget _buildCompactList() {
    final rows = _paginatedOrders;

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

    return Column(
      children: [
        for (final order in rows) _buildOrderCard(order),
        Container(
          decoration: BoxDecoration(
            color: procurementSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: procurementLine),
            boxShadow: procurementCardShadow,
          ),
          child: _buildPaginationFooter(compact: true),
        ),
      ],
    );
  }

  Widget _buildTable() {
    final rows = _paginatedOrders;

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
      child: Column(
        children: [
          SingleChildScrollView(
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
          _buildPaginationFooter(compact: false),
        ],
      ),
    );
  }

  Widget _buildPaginationFooter({required bool compact}) {
    final totalItems = _filteredOrders.length;
    final startIndex = totalItems == 0
        ? 0
        : ((_currentPage - 1) * _itemsPerPage) + 1;
    final endIndex =
        ((_currentPage - 1) * _itemsPerPage + _paginatedOrders.length).clamp(
          0,
          totalItems,
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Affichage de $startIndex a $endIndex sur $totalItems commandes',
            style: const TextStyle(color: procurementMuted, fontSize: 12.5),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!compact)
                IconButton(
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage = 1)
                      : null,
                  icon: const Icon(Icons.first_page),
                ),
              IconButton(
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage -= 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              for (final page in _visiblePageNumbers(
                maxVisible: compact ? 3 : 5,
              ))
                FilledButton.tonal(
                  onPressed: () => setState(() => _currentPage = page),
                  style: FilledButton.styleFrom(
                    backgroundColor: _currentPage == page
                        ? procurementPrimary.withValues(alpha: 0.15)
                        : null,
                  ),
                  child: Text('$page'),
                ),
              IconButton(
                onPressed: _currentPage < _totalPages
                    ? () => setState(() => _currentPage += 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              if (!compact)
                IconButton(
                  onPressed: _currentPage < _totalPages
                      ? () => setState(() => _currentPage = _totalPages)
                      : null,
                  icon: const Icon(Icons.last_page),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _visiblePageNumbers({required int maxVisible}) {
    var startPage = _currentPage - (maxVisible ~/ 2);
    if (startPage < 1) startPage = 1;

    var endPage = startPage + maxVisible - 1;
    if (endPage > _totalPages) {
      endPage = _totalPages;
      startPage = (endPage - maxVisible + 1).clamp(1, endPage);
    }

    return [for (int i = startPage; i <= endPage; i++) i];
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
        final useCompactLayout = constraints.maxWidth < 880;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProcurementRoleSwitchCard(
              currentRole: _role,
              onChanged: (role) {
                ProcurementRoleStore.instance.setRole(role);
              },
            ),
            const SizedBox(height: 16),
            _buildToolbar(),
            const SizedBox(height: 20),
            useCompactLayout ? _buildCompactList() : _buildTable(),
          ],
        );
      },
    );
  }
}
