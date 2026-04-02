import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/services/procurement_service.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_invoice_pdf.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_order_form_dialog.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

class ProcurementOrdersSection extends StatefulWidget {
  final bool receptionMode;
  final VoidCallback? onSwitchToReceptions;

  const ProcurementOrdersSection({
    super.key,
    required this.receptionMode,
    this.onSwitchToReceptions,
  });

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

  List<ProcurementOrder> _orders = const [];
  List<ProcurementSupplier> _suppliers = const [];
  List<ProcurementProduct> _products = const [];

  bool _isOrderVisibleInCurrentMode(ProcurementOrder order) {
    if (_showArchived) return true;

    final status = order.statut.toUpperCase();
    if (widget.receptionMode) {
      return status == 'ENVOYEE' || status == 'RECUE' || status == 'FACTUREE';
    }

    return status != 'RECUE' && status != 'FACTUREE';
  }

  List<ProcurementOrder> get _ordersForCurrentMode =>
      _orders.where(_isOrderVisibleInCurrentMode).toList();

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
      final futures = <Future<dynamic>>[
        _service.getOrders(archived: _showArchived),
      ];
      if (!widget.receptionMode) {
        futures.add(_service.getSuppliers(activeOnly: true));
        futures.add(_service.getProducts());
      }
      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _orders = results[0] as List<ProcurementOrder>;
        _suppliers = !widget.receptionMode
            ? results[1] as List<ProcurementSupplier>
            : const [];
        _products = !widget.receptionMode
            ? results[2] as List<ProcurementProduct>
            : const [];
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

    final filtered = _ordersForCurrentMode.where((order) {
      final matchesQuery =
          query.isEmpty ||
          order.referenceCommande.toLowerCase().contains(query) ||
          order.partenaireNom.toLowerCase().contains(query) ||
          (order.fournisseur?.email.toLowerCase().contains(query) ?? false);
      final matchesStatus =
          _statusFilter.isEmpty || order.statut.toUpperCase() == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final left = a.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });

    return filtered;
  }

  Future<void> _showOrderDialog({ProcurementOrder? initial}) async {
    if (!widget.receptionMode &&
        initial == null &&
        (_suppliers.isEmpty || _products.isEmpty)) {
      showMessage(
        context,
        'Produits ou fournisseurs indisponibles pour creer une commande.',
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
        });
        showMessage(context, 'Commande fournisseur creee avec succes.');
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
        showMessage(context, 'Commande fournisseur mise a jour.');
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
      builder: (_) => OrderDetailsDialog(order: order),
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
        _orders = [
          for (final item in _orders)
            if (item.idCommandeFournisseur != order.idCommandeFournisseur) item,
        ];
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
      message:
          'Restaurer ${order.referenceCommande} dans les commandes actives ?',
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

  Future<void> _invoiceOrder(ProcurementOrder order) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Facturer la commande',
      message: 'Marquer ${order.referenceCommande} comme facturee ?',
      confirmLabel: 'Facturer',
      confirmColor: const Color(0xFF7C3AED),
    );

    if (confirmed != true) return;

    final billedAt = DateTime.now();

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
      });

      try {
        await _exportInvoicePdf(
          updated,
          billedAt: billedAt,
          showSuccess: false,
        );
        if (!mounted) return;
        showMessage(
          context,
          'Commande fournisseur facturee avec succes. PDF pret.',
        );
      } catch (error) {
        if (!mounted) return;
        showMessage(
          context,
          'Commande fournisseur facturee, mais le PDF n\'a pas pu etre genere: ${error.toString().replaceFirst('Exception: ', '')}',
          error: true,
        );
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

    showMessage(
      context,
      'PDF ${facture.referenceFactureClient} genere avec succes.',
    );
  }

  bool _canGenerateInvoicePdf(ProcurementOrder order) {
    final status = order.statut.toUpperCase();
    return status == 'RECUE' || status == 'FACTUREE';
  }

  Future<void> _handleInvoiceAction(ProcurementOrder order) async {
    if (order.canInvoice) {
      await _invoiceOrder(order);
      return;
    }

    await _exportInvoicePdf(order);
  }

  Future<void> _runOrderAction(
    ProcurementOrder order, {
    required Future<ProcurementOrder> Function() action,
    required String title,
    required String message,
    required String confirmLabel,
    required String successMessage,
    Color confirmColor = const Color(0xFF2D47C8),
  }) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    );

    if (confirmed != true) return;

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
      });
      showMessage(context, successMessage);
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LoadingPanel(
        message: widget.receptionMode
            ? 'Chargement des receptions...'
            : 'Chargement des commandes fournisseurs...',
      );
    }

    if (_error != null) {
      return AsyncErrorCard(
        title: widget.receptionMode
            ? 'Impossible de charger les receptions'
            : 'Impossible de charger les commandes fournisseurs',
        message: _error!,
        onRetry: _loadData,
      );
    }

    final filteredOrders = _filteredOrders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionSurface(
          title: widget.receptionMode
              ? 'Suivi des receptions'
              : 'Pilotage des commandes',
          subtitle: widget.receptionMode
              ? 'Recevez ou facturez les commandes deja envoyees'
              : 'Filtrez, creez et orchestrez les bons de commande',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: widget.receptionMode
                            ? 'Numero ou fournisseur'
                            : 'Rechercher une commande',
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter.isEmpty
                          ? null
                          : _statusFilter,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: [
                        if (!widget.receptionMode)
                          const DropdownMenuItem<String>(
                            value: 'BROUILLON',
                            child: Text('Brouillon'),
                          ),
                        if (!widget.receptionMode)
                          const DropdownMenuItem<String>(
                            value: 'VALIDEE',
                            child: Text('Validee'),
                          ),
                        const DropdownMenuItem<String>(
                          value: 'ENVOYEE',
                          child: Text('Envoyee'),
                        ),
                        if (widget.receptionMode)
                          const DropdownMenuItem<String>(
                            value: 'RECUE',
                            child: Text('Recue'),
                          ),
                        if (widget.receptionMode)
                          const DropdownMenuItem<String>(
                            value: 'FACTUREE',
                            child: Text('Facturee'),
                          ),
                        if (!widget.receptionMode)
                          const DropdownMenuItem<String>(
                            value: 'ANNULEE',
                            child: Text('Annulee'),
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
                  if (!widget.receptionMode)
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _showArchived = !_showArchived;
                          _statusFilter = '';
                        });
                        await _loadData();
                      },
                      icon: Icon(
                        _showArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                      ),
                      label: Text(
                        _showArchived
                            ? 'Retour aux actives'
                            : 'Afficher archives',
                      ),
                    ),
                  if (!widget.receptionMode)
                    FilledButton.icon(
                      onPressed: _showArchived
                          ? null
                          : () => _showOrderDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle commande'),
                    ),
                ],
              ),
              if (!widget.receptionMode && !_showArchived)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: widget.onSwitchToReceptions,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Ouvrir le suivi des receptions'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (filteredOrders.isEmpty)
          EmptyPanel(
            title: widget.receptionMode
                ? 'Aucune reception a afficher'
                : (_showArchived
                      ? 'Aucune commande archivee'
                      : 'Aucune commande fournisseur'),
            message: widget.receptionMode
                ? 'Les commandes envoyees, recues ou facturees apparaitront ici.'
                : (_showArchived
                      ? 'Les commandes supprimees seront listees ici.'
                      : 'Les commandes recues ou facturees restent visibles dans le suivi des receptions.'),
          )
        else
          Column(
            children: [
              for (final order in filteredOrders) ...[
                OrderCard(
                  order: order,
                  receptionMode: widget.receptionMode,
                  showArchived: _showArchived,
                  onView: () => _showOrderDetails(order),
                  onEdit:
                      order.canEdit && !_showArchived && !widget.receptionMode
                      ? () => _showOrderDialog(initial: order)
                      : null,
                  onDelete:
                      order.canDelete && !_showArchived && !widget.receptionMode
                      ? () => _deleteOrder(order)
                      : null,
                  onRestore: _showArchived ? () => _restoreOrder(order) : null,
                  onValidate:
                      order.canValidate &&
                          !_showArchived &&
                          !widget.receptionMode
                      ? () => _runOrderAction(
                          order,
                          action: () => _service.validateOrder(
                            order.idCommandeFournisseur,
                          ),
                          title: 'Valider la commande',
                          message:
                              'Valider ${order.referenceCommande} pour la passer en commande approuvee ?',
                          confirmLabel: 'Valider',
                          successMessage:
                              'Commande fournisseur validee avec succes.',
                        )
                      : null,
                  onSend:
                      order.canSend && !_showArchived && !widget.receptionMode
                      ? () => _runOrderAction(
                          order,
                          action: () =>
                              _service.sendOrder(order.idCommandeFournisseur),
                          title: 'Envoyer la commande',
                          message:
                              'Envoyer ${order.referenceCommande} au fournisseur ?',
                          confirmLabel: 'Envoyer',
                          successMessage:
                              'Commande fournisseur envoyee avec succes.',
                        )
                      : null,
                  onReceive: order.canReceive && !_showArchived
                      ? () => _runOrderAction(
                          order,
                          action: () => _service.receiveOrder(
                            order.idCommandeFournisseur,
                          ),
                          title: 'Receptionner la commande',
                          message:
                              'Confirmez-vous la reception complete de ${order.referenceCommande} ?',
                          confirmLabel: 'Receptionner',
                          successMessage: 'Reception enregistree avec succes.',
                          confirmColor: const Color(0xFF16A34A),
                        )
                      : null,
                  onInvoice: _canGenerateInvoicePdf(order) && !_showArchived
                      ? () => _handleInvoiceAction(order)
                      : null,
                  onCancel:
                      order.canCancel && !_showArchived && !widget.receptionMode
                      ? () => _runOrderAction(
                          order,
                          action: () =>
                              _service.cancelOrder(order.idCommandeFournisseur),
                          title: 'Annuler la commande',
                          message:
                              'Annuler ${order.referenceCommande} ? Cette action reste visible dans l\'historique.',
                          confirmLabel: 'Annuler',
                          successMessage:
                              'Commande fournisseur annulee avec succes.',
                          confirmColor: Colors.red,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class DraftOrderLine {
  final int produitId;
  final String produitLabel;
  final int quantite;
  final double prixUnitaire;
  final String status;

  const DraftOrderLine({
    required this.produitId,
    required this.produitLabel,
    required this.quantite,
    required this.prixUnitaire,
    required this.status,
  });

  double get totalTtc => quantite * prixUnitaire * 1.19;

  DraftOrderLine copyWith({int? quantite, double? prixUnitaire}) {
    return DraftOrderLine(
      produitId: produitId,
      produitLabel: produitLabel,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      status: status,
    );
  }
}

class OrderDialogResult {
  final ProcurementOrderCreatePayload? createPayload;
  final ProcurementOrderUpdatePayload? updatePayload;

  const OrderDialogResult({this.createPayload, this.updatePayload});
}

class PurchaseOrderFormDialog extends StatefulWidget {
  final List<ProcurementSupplier> suppliers;
  final List<ProcurementProduct> products;
  final ProcurementOrder? initialOrder;

  const PurchaseOrderFormDialog({
    super.key,
    required this.suppliers,
    required this.products,
    required this.initialOrder,
  });

  @override
  State<PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogLegacyState();
}

class _PurchaseOrderFormDialogLegacyState
    extends State<PurchaseOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late DateTime _deliveryDate;

  int? _supplierId;
  bool _showInactiveProducts = false;
  final List<DraftOrderLine> _lines = [];
  int? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _priceController = TextEditingController();

  bool get _isEditing => widget.initialOrder != null;

  List<ProcurementProduct> get _selectableProducts {
    final products = widget.products.where((product) {
      return _showInactiveProducts || product.active;
    }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    return products;
  }

  double get _totalTtc =>
      _lines.fold<double>(0, (sum, line) => sum + line.totalTtc);

  @override
  void initState() {
    super.initState();
    final order = widget.initialOrder;
    _addressController = TextEditingController(
      text: order?.adresseLivraison ?? '',
    );
    _deliveryDate = order?.dateLivraisonPrevue ?? DateTime.now();
    _supplierId = order?.fournisseur?.idFournisseur;

    if (order != null) {
      for (final line in order.produits) {
        _lines.add(
          DraftOrderLine(
            produitId: line.produitId,
            produitLabel: line.libelle,
            quantite: line.quantite,
            prixUnitaire: line.prixUnitaire,
            status: 'READ_ONLY',
          ),
        );
      }
    } else if (_selectableProducts.isNotEmpty) {
      final firstProduct = _selectableProducts.first;
      _selectedProductId = firstProduct.idProduit;
      _priceController.text = firstProduct.prixAchat.toStringAsFixed(3);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate.isBefore(today) ? today : _deliveryDate,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );

    if (picked == null) return;
    setState(() {
      _deliveryDate = DateTime(picked.year, picked.month, picked.day, 9);
    });
  }

  void _handleProductSelection(int? productId) {
    ProcurementProduct? selected;
    for (final product in widget.products) {
      if (product.idProduit == productId) {
        selected = product;
        break;
      }
    }

    setState(() {
      _selectedProductId = productId;
      _priceController.text = selected?.prixAchat.toStringAsFixed(3) ?? '';
    });
  }

  void _addLine() {
    final productId = _selectedProductId;
    final quantity = int.tryParse(_quantityController.text);
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));

    if (productId == null ||
        quantity == null ||
        quantity <= 0 ||
        price == null) {
      showMessage(
        context,
        'Selectionnez un produit et renseignez une quantite / prix valides.',
        error: true,
      );
      return;
    }

    ProcurementProduct? product;
    for (final item in widget.products) {
      if (item.idProduit == productId) {
        product = item;
        break;
      }
    }
    if (product == null) return;

    final existingIndex = _lines.indexWhere(
      (line) => line.produitId == productId,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _lines[existingIndex];
        _lines[existingIndex] = existing.copyWith(
          quantite: existing.quantite + quantity,
          prixUnitaire: price,
        );
      } else {
        _lines.add(
          DraftOrderLine(
            produitId: product!.idProduit,
            produitLabel: product.displayName,
            quantite: quantity,
            prixUnitaire: price,
            status: product.active ? 'ACTIF' : 'INACTIF',
          ),
        );
      }
      _quantityController.text = '1';
      _priceController.text = product!.prixAchat.toStringAsFixed(3);
    });
  }

  void _removeLine(DraftOrderLine line) {
    setState(() {
      _lines.remove(line);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_supplierId == null) {
      showMessage(context, 'Choisissez un fournisseur.', error: true);
      return;
    }

    if (!_isEditing && _lines.isEmpty) {
      showMessage(
        context,
        'Ajoutez au moins une ligne produit a la commande.',
        error: true,
      );
      return;
    }

    if (_isEditing) {
      Navigator.pop(
        context,
        OrderDialogResult(
          updatePayload: ProcurementOrderUpdatePayload(
            dateLivraisonPrevue: _deliveryDate,
            adresseLivraison: _addressController.text.trim(),
          ),
        ),
      );
      return;
    }

    final payload = ProcurementOrderCreatePayload(
      fournisseurId: _supplierId!,
      dateLivraisonPrevue: _deliveryDate,
      adresseLivraison: _addressController.text.trim(),
      lignesCommande: _lines
          .map(
            (line) => ProcurementOrderLinePayload(
              produitId: line.produitId,
              quantite: line.quantite,
              prixUnitaire: line.prixUnitaire,
            ),
          )
          .toList(),
    );

    Navigator.pop(context, OrderDialogResult(createPayload: payload));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text(
        _isEditing
            ? 'Modifier la commande brouillon'
            : 'Nouvelle commande fournisseur',
      ),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _supplierId,
                  decoration: const InputDecoration(labelText: 'Fournisseur'),
                  items: widget.suppliers
                      .map(
                        (supplier) => DropdownMenuItem<int>(
                          value: supplier.idFournisseur,
                          child: Text(supplier.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: _isEditing
                      ? null
                      : (value) {
                          setState(() {
                            _supplierId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null) return 'Selectionnez un fournisseur';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Adresse de livraison',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Renseignez l\'adresse de livraison';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDeliveryDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text('Livraison prevue: ${formatDate(_deliveryDate)}'),
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Le backend autorise actuellement la modification de la date et de l\'adresse sur une commande brouillon. Les lignes et le fournisseur sont affiches en lecture seule pour rester coherents avec le comportement serveur.',
                    style: TextStyle(color: Color(0xFF607089), fontSize: 12.5),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    value: _showInactiveProducts,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Afficher les produits inactifs'),
                    subtitle: const Text(
                      'Le backend peut les reactiver automatiquement a la reception.',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _showInactiveProducts = value;
                        if (_selectedProductId != null &&
                            !_selectableProducts.any(
                              (product) =>
                                  product.idProduit == _selectedProductId,
                            )) {
                          final first = _selectableProducts.isEmpty
                              ? null
                              : _selectableProducts.first;
                          _selectedProductId = first?.idProduit;
                          _priceController.text =
                              first?.prixAchat.toStringAsFixed(3) ?? '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Produit',
                          ),
                          items: _selectableProducts
                              .map(
                                (product) => DropdownMenuItem<int>(
                                  value: product.idProduit,
                                  child: Text(
                                    '${product.displayName} (${product.active ? 'actif' : 'inactif'})',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _handleProductSelection,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantite',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Prix unit.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _selectableProducts.isEmpty
                            ? null
                            : _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SectionSurface(
                  title: 'Lignes commande',
                  subtitle: _isEditing
                      ? 'Lecture seule'
                      : 'Le total est calcule a partir des lignes ci-dessous',
                  child: _lines.isEmpty
                      ? const EmptyPanel(
                          title: 'Aucune ligne',
                          message:
                              'Ajoutez au moins un produit a cette commande fournisseur.',
                        )
                      : Column(
                          children: [
                            for (final line in _lines) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.produitLabel,
                                          style: const TextStyle(
                                            color: Color(0xFF1F2A44),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${line.quantite} x ${formatMoney(line.prixUnitaire)}',
                                          style: const TextStyle(
                                            color: Color(0xFF607089),
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  StatusPill(
                                    label: line.status == 'INACTIF'
                                        ? 'Produit inactif'
                                        : (line.status == 'READ_ONLY'
                                              ? 'Lecture seule'
                                              : 'Actif'),
                                    color: line.status == 'INACTIF'
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatMoney(line.totalTtc),
                                    style: const TextStyle(
                                      color: Color(0xFF1F2A44),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (!_isEditing) ...[
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: () => _removeLine(line),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (line != _lines.last)
                                const Divider(color: Color(0xFFE6EAF2)),
                            ],
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total TTC: ${formatMoney(_totalTtc)}',
                                style: const TextStyle(
                                  color: Color(0xFF1F2A44),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Mettre a jour' : 'Creer'),
        ),
      ],
    );
  }
}

class OrderDetailsDialog extends StatelessWidget {
  final ProcurementOrder order;

  const OrderDetailsDialog({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text(order.referenceCommande),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  DetailBadge(
                    label: 'Fournisseur',
                    value: order.partenaireNom,
                    color: const Color(0xFF2D47C8),
                  ),
                  DetailBadge(
                    label: 'Date commande',
                    value: order.dateCommandeFormatted,
                    color: const Color(0xFF0F766E),
                  ),
                  DetailBadge(
                    label: 'Livraison prevue',
                    value: order.dateLivraisonPrevueFormatted,
                    color: const Color(0xFFEA580C),
                  ),
                  DetailBadge(
                    label: 'Statut',
                    value: order.statutDisplay,
                    color: orderStatusColor(order.statut),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Adresse de livraison',
                style: const TextStyle(
                  color: Color(0xFF1F2A44),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.adresseLivraison,
                style: const TextStyle(color: Color(0xFF607089)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lignes commande',
                style: TextStyle(
                  color: Color(0xFF1F2A44),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (order.produits.isEmpty)
                const EmptyPanel(
                  title: 'Aucune ligne',
                  message: 'Cette commande ne contient aucun produit.',
                )
              else
                Column(
                  children: [
                    for (final line in order.produits) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.libelle,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2A44),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Quantite ${line.quantite} • recue ${line.quantiteRecue}',
                                  style: const TextStyle(
                                    color: Color(0xFF607089),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(line.prixUnitaire),
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatMoney(line.total),
                                style: const TextStyle(
                                  color: Color(0xFF1F2A44),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (line != order.produits.last)
                        const Divider(color: Color(0xFFE6EAF2)),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total HT: ${formatMoney(order.totalHT)}',
                      style: const TextStyle(color: Color(0xFF607089)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TVA: ${formatMoney(order.totalTVA)}',
                      style: const TextStyle(color: Color(0xFF607089)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total TTC: ${formatMoney(order.total)}',
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
