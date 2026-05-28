import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';

const double _purchaseBaseUnit = 8.0;
const double _purchaseDefaultVatRate = 19.0;
const Color _purchasePrimary = Color(0xFF2563EB);
const Color _purchasePrimaryDark = Color(0xFF1D4ED8);
const Color _purchaseAccent = Color(0xFF16A34A);
const Color _purchaseBackground = Color(0xFFF4F7FC);
const Color _purchaseSurface = Colors.white;
const Color _purchaseTextPrimary = Color(0xFF1F2A44);
const Color _purchaseTextSecondary = Color(0xFF607089);
const Color _purchaseBorderLight = Color(0xFFE6EAF2);
const Color _purchaseError = Color(0xFFB42318);
const Color _purchaseWarning = Color(0xFFEA580C);

class ProcurementOrderDialogResult {
  final ProcurementOrderCreatePayload? createPayload;
  final ProcurementOrderUpdatePayload? updatePayload;

  const ProcurementOrderDialogResult({this.createPayload, this.updatePayload});
}

class ProcurementOrderFormDialog extends StatefulWidget {
  final List<ProcurementSupplier> suppliers;
  final List<ProcurementProduct> products;
  final ProcurementOrder? initialOrder;
  final bool isBottomSheet;

  const ProcurementOrderFormDialog({
    super.key,
    required this.suppliers,
    required this.products,
    required this.initialOrder,
    this.isBottomSheet = false,
  });

  @override
  State<ProcurementOrderFormDialog> createState() =>
      _ProcurementOrderFormDialogState();
}

class _PurchaseDraftLine {
  final String rowKey;
  int? categorieId;
  int? produitId;
  final TextEditingController quantiteController;
  final TextEditingController prixController;
  final String? fallbackLabel;
  final bool readOnly;

  _PurchaseDraftLine({
    required this.rowKey,
    this.categorieId,
    this.produitId,
    int quantite = 1,
    double? prixUnitaire,
    this.fallbackLabel,
    this.readOnly = false,
  }) : quantiteController = TextEditingController(text: '$quantite'),
       prixController = TextEditingController(
         text: prixUnitaire == null ? '' : prixUnitaire.toStringAsFixed(3),
       );

  int get quantity => int.tryParse(quantiteController.text) ?? 0;

  double get unitPrice =>
      double.tryParse(prixController.text.replaceAll(',', '.')) ?? 0;

  void dispose() {
    quantiteController.dispose();
    prixController.dispose();
  }
}

class _SupplierProductPickerDialog extends StatefulWidget {
  final List<ProcurementProduct> products;
  final ProcurementSupplier? supplier;
  final Set<int> selectedProductIds;
  final bool isBottomSheet;

  const _SupplierProductPickerDialog({
    required this.products,
    required this.supplier,
    required this.selectedProductIds,
    this.isBottomSheet = false,
  });

  @override
  State<_SupplierProductPickerDialog> createState() =>
      _SupplierProductPickerDialogState();
}

class _SupplierProductPickerDialogState
    extends State<_SupplierProductPickerDialog> {
  ProcurementProduct? _selectedProduct;
  int _quantity = 1;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _changeQuantity(int value) {
    final nextQuantity = value < 1 ? 1 : value;
    setState(() {
      _quantity = nextQuantity;
      _quantityController.text = '$nextQuantity';
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        widget.isBottomSheet || MediaQuery.of(context).size.width < 600;
    final surface = Container(
      width: widget.isBottomSheet
          ? double.infinity
          : AdaptiveLayout.dialogWidth(context, max: 680, sideMargin: 16),
      constraints: BoxConstraints(
        maxHeight: widget.isBottomSheet
            ? MediaQuery.sizeOf(context).height * 0.82
            : AdaptiveLayout.dialogHeight(context, ratio: 0.82),
      ),
      decoration: BoxDecoration(
        color: _purchaseSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(
                compact ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_purchasePrimary, _purchasePrimaryDark],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ajouter un produit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  compact ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fournisseur : ${widget.supplier?.displayName ?? '-'}',
                      style: TextStyle(
                        color: _purchaseTextSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12.5 : 13,
                      ),
                    ),
                    const SizedBox(height: _purchaseBaseUnit * 1.5),
                    if (widget.products.isEmpty)
                      const EmptyPanel(
                        title: 'Aucun produit disponible',
                        message:
                            'Ce fournisseur n a aucun produit a commander.',
                      )
                    else
                      ...widget.products.map(_buildProductOption),
                    if (_selectedProduct != null) ...[
                      const SizedBox(height: _purchaseBaseUnit * 1.25),
                      Container(
                        padding: EdgeInsets.all(
                          compact
                              ? _purchaseBaseUnit * 1.25
                              : _purchaseBaseUnit * 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _purchaseBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _purchaseBorderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quantite (minimum 1)',
                              style: TextStyle(
                                color: _purchaseTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            Row(
                              children: [
                                IconButton.outlined(
                                  onPressed: _quantity <= 1
                                      ? null
                                      : () => _changeQuantity(_quantity - 1),
                                  icon: const Icon(Icons.remove),
                                  visualDensity: VisualDensity.compact,
                                ),
                                SizedBox(
                                  width: compact ? 76 : 92,
                                  child: TextFormField(
                                    controller: _quantityController,
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      final parsed = int.tryParse(value);
                                      if (parsed != null) {
                                        _changeQuantity(parsed);
                                      }
                                    },
                                  ),
                                ),
                                IconButton.outlined(
                                  onPressed: () =>
                                      _changeQuantity(_quantity + 1),
                                  icon: const Icon(Icons.add),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(
                compact ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
              ),
              decoration: const BoxDecoration(
                color: _purchaseBackground,
                border: Border(top: BorderSide(color: _purchaseBorderLight)),
              ),
              child: compact
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: _purchaseBaseUnit),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selectedProduct == null
                                ? null
                                : () => Navigator.pop(context, (
                                    product: _selectedProduct!,
                                    quantity: _quantity,
                                  )),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purchasePrimary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Ajouter'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: _purchaseBaseUnit),
                        ElevatedButton(
                          onPressed: _selectedProduct == null
                              ? null
                              : () => Navigator.pop(context, (
                                  product: _selectedProduct!,
                                  quantity: _quantity,
                                )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purchasePrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Ajouter a la commande'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.only(
          left: _purchaseBaseUnit,
          right: _purchaseBaseUnit,
          top: _purchaseBaseUnit,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(top: false, child: surface),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: surface,
    );
  }

  Widget _buildProductOption(ProcurementProduct product) {
    final alreadyAdded = widget.selectedProductIds.contains(product.idProduit);
    final disabled = alreadyAdded || !product.active;
    final selected = _selectedProduct?.idProduit == product.idProduit;

    return InkWell(
      onTap: disabled
          ? null
          : () {
              setState(() {
                _selectedProduct = product;
              });
              _changeQuantity(1);
            },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: _purchaseBaseUnit),
        padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
        decoration: BoxDecoration(
          color: selected
              ? _purchasePrimary.withValues(alpha: 0.08)
              : disabled
              ? _purchaseBackground
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? _purchasePrimary
                : disabled
                ? _purchaseBorderLight
                : _purchaseBorderLight,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        product.displayName,
                        style: TextStyle(
                          color: disabled
                              ? _purchaseTextSecondary
                              : _purchaseTextPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!product.active)
                        const StatusPill(
                          label: 'Inactif',
                          color: _purchaseWarning,
                        ),
                      if (alreadyAdded)
                        const StatusPill(
                          label: 'Deja dans la commande',
                          color: _purchaseAccent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Prix: ${formatPrice(product.prixAchat)}',
                        style: const TextStyle(
                          color: _purchaseTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        'Stock: ${product.quantiteStock}',
                        style: const TextStyle(
                          color: _purchaseTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        'TVA: ${formatVatRate(product.tauxTVA ?? product.categorie?.tauxTVA ?? _purchaseDefaultVatRate)}',
                        style: const TextStyle(
                          color: _purchaseTextSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _purchasePrimary),
          ],
        ),
      ),
    );
  }
}

class _ProcurementOrderFormDialogState
    extends State<ProcurementOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProcurementService _service = ProcurementService();

  late final TextEditingController _addressController;
  late DateTime _deliveryDate;

  int? _supplierId;
  bool _loadingSupplierProducts = false;
  String? _supplierProductsError;
  List<ProcurementProduct> _supplierProducts = const [];

  final List<_PurchaseDraftLine> _lines = <_PurchaseDraftLine>[];
  int _draftLineSeed = 0;
  int _mobileStep = 0;

  bool get _isEditing => widget.initialOrder != null;
  bool get _isRejectedEdit =>
      widget.initialOrder?.normalizedStatus == ProcurementOrderStatus.rejetee;
  bool get _canEditLines => !_isEditing || _isRejectedEdit;

  List<ProcurementSupplier> get _supplierOptions {
    final map = <int, ProcurementSupplier>{
      for (final supplier in widget.suppliers) supplier.idFournisseur: supplier,
    };
    final initialSupplier = widget.initialOrder?.fournisseur;
    if (initialSupplier != null) {
      map.putIfAbsent(initialSupplier.idFournisseur, () => initialSupplier);
    }
    final list = map.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  List<ProcurementProduct> get _availableProducts =>
      _supplierProducts.toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  ProcurementSupplier? _findSupplierById(int? supplierId) {
    if (supplierId == null) return null;
    try {
      return _supplierOptions.firstWhere(
        (supplier) => supplier.idFournisseur == supplierId,
      );
    } catch (_) {
      return null;
    }
  }

  ProcurementProduct? _findProductById(int? productId) {
    if (productId == null) return null;
    try {
      return [
        ..._supplierProducts,
        ...widget.products,
      ].firstWhere((p) => p.idProduit == productId);
    } catch (_) {
      return null;
    }
  }

  double _getVatRateForProduct(ProcurementProduct? product) {
    final raw = product?.tauxTVA ?? product?.categorie?.tauxTVA;
    if (raw == null || raw <= 0) return _purchaseDefaultVatRate;
    return raw;
  }

  String _supplierOptionLabel(ProcurementSupplier supplier) {
    final contact = supplier.telephone.trim().isNotEmpty
        ? supplier.telephone.trim()
        : supplier.email.trim();
    if (contact.isEmpty) return supplier.displayName;
    return '${supplier.displayName} ($contact)';
  }

  bool get _isGeneralInfoReady =>
      _supplierId != null && _addressController.text.trim().isNotEmpty;

  Future<void> _onSupplierChanged(int? supplierId) async {
    final previousSupplier = _findSupplierById(_supplierId);
    final nextSupplier = _findSupplierById(supplierId);
    final currentAddress = _addressController.text.trim();
    final previousAddress = previousSupplier?.adresse.trim() ?? '';
    final shouldPrefillAddress =
        currentAddress.isEmpty ||
        (previousAddress.isNotEmpty && currentAddress == previousAddress);

    setState(() {
      _supplierId = supplierId;
      for (final line in _lines) {
        line.dispose();
      }
      _lines.clear();
      _supplierProducts = const [];
      _supplierProductsError = null;
      _mobileStep = 0;
      if (!_isEditing &&
          nextSupplier != null &&
          shouldPrefillAddress &&
          nextSupplier.adresse.trim().isNotEmpty) {
        _addressController.text = nextSupplier.adresse.trim();
      }
    });

    if (supplierId != null) {
      await _loadProductsForSupplier(supplierId);
    }
  }

  _PurchaseDraftLine _newDraftLine({
    int? categorieId,
    int? produitId,
    int quantite = 1,
    double? prixUnitaire,
    String? fallbackLabel,
    bool readOnly = false,
  }) {
    _draftLineSeed += 1;
    final product = _findProductById(produitId);
    return _PurchaseDraftLine(
      rowKey: 'purchase_line_$_draftLineSeed',
      categorieId: categorieId ?? product?.categorie?.idCategorie,
      produitId: produitId,
      quantite: quantite,
      prixUnitaire: prixUnitaire ?? product?.prixAchat,
      fallbackLabel: fallbackLabel ?? product?.displayName,
      readOnly: readOnly,
    );
  }

  double _lineSubTotal(_PurchaseDraftLine line) =>
      line.quantity * line.unitPrice;

  double _lineVatRate(_PurchaseDraftLine line) {
    final product = _findProductById(line.produitId);
    return _getVatRateForProduct(product);
  }

  double _lineVatAmount(_PurchaseDraftLine line) =>
      _lineSubTotal(line) * (_lineVatRate(line) / 100);

  double _lineTotalTtc(_PurchaseDraftLine line) =>
      _lineSubTotal(line) + _lineVatAmount(line);

  double get _subTotalHt =>
      _lines.fold<double>(0, (sum, line) => sum + _lineSubTotal(line));

  double get _totalVat =>
      _lines.fold<double>(0, (sum, line) => sum + _lineVatAmount(line));

  double get _totalTtc => _subTotalHt + _totalVat;

  Map<double, ({double ht, double tva})> get _vatBreakdown {
    final data = <double, ({double ht, double tva})>{};

    for (final line in _lines) {
      final rate = _lineVatRate(line);
      final ht = _lineSubTotal(line);
      final tva = _lineVatAmount(line);
      final existing = data[rate];
      data[rate] = (
        ht: (existing?.ht ?? 0) + ht,
        tva: (existing?.tva ?? 0) + tva,
      );
    }

    final sortedKeys = data.keys.toList()..sort();
    return {for (final key in sortedKeys) key: data[key]!};
  }

  String get _vatSummaryLabel {
    final rates = _vatBreakdown.keys.toList()..sort();
    if (rates.isEmpty) return formatVatRate(_purchaseDefaultVatRate);
    if (rates.length == 1) return formatVatRate(rates.first);
    return 'multi-taux';
  }

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
      _mobileStep = _canEditLines ? 1 : 0;
      _supplierProducts = widget.products
          .where((product) => product.fournisseurId == _supplierId)
          .toList();
      for (final line in order.lignesCommande) {
        final product = _findProductById(line.produitId);
        _lines.add(
          _newDraftLine(
            produitId: line.produitId,
            categorieId: product?.categorie?.idCategorie,
            quantite: line.quantite,
            prixUnitaire: line.prixUnitaire,
            fallbackLabel: line.produitLibelle,
            readOnly: !_canEditLines,
          ),
        );
      }
    }

    if (_supplierId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadProductsForSupplier(_supplierId!);
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
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

  Future<void> _loadProductsForSupplier(int supplierId) async {
    setState(() {
      _loadingSupplierProducts = true;
      _supplierProductsError = null;
    });

    try {
      final products = await _service.getProductsBySupplier(supplierId);
      if (!mounted) return;
      setState(() {
        _supplierProducts = products;
        _loadingSupplierProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      final fallbackProducts = widget.products
          .where((product) => product.fournisseurId == supplierId)
          .toList();
      setState(() {
        _supplierProducts = fallbackProducts;
        _supplierProductsError = fallbackProducts.isEmpty
            ? error.toString().replaceFirst('Exception: ', '')
            : null;
        _loadingSupplierProducts = false;
      });
    }
  }

  void _addProductToOrder(ProcurementProduct product, int quantity) {
    if (!_canEditLines) return;

    if (_supplierId == null) {
      showMessage(
        context,
        'Veuillez d’abord selectionner un fournisseur.',
        error: true,
      );
      return;
    }

    if (quantity <= 0) {
      showMessage(
        context,
        'La quantite doit etre superieure a 0.',
        error: true,
      );
      return;
    }

    final unitPrice = product.prixAchat;
    if (unitPrice <= 0) {
      showMessage(
        context,
        'Le prix unitaire doit etre superieur a 0.',
        error: true,
      );
      return;
    }

    final existingIndex = _lines.indexWhere(
      (line) => line.produitId == product.idProduit,
    );

    setState(() {
      if (existingIndex >= 0) {
        final existing = _lines[existingIndex];
        final nextQty = existing.quantity + quantity;
        existing.quantiteController.text = '$nextQty';
      } else {
        _lines.add(
          _newDraftLine(
            produitId: product.idProduit,
            categorieId: product.categorie?.idCategorie,
            quantite: quantity,
            prixUnitaire: unitPrice,
            fallbackLabel: product.displayName,
          ),
        );
      }
    });
  }

  void _removeLine(_PurchaseDraftLine line) {
    setState(() {
      _lines.remove(line);
    });
    line.dispose();
  }

  void _updateLineQuantity(_PurchaseDraftLine line, String value) {
    if (line.readOnly) return;

    final parsed = int.tryParse(value);
    if (parsed == null) return;

    if (parsed < 0) {
      line.quantiteController.text = '0';
      line.quantiteController.selection = TextSelection.fromPosition(
        const TextPosition(offset: 1),
      );
    }

    setState(() {});
  }

  List<ProcurementOrderLinePayload> _buildPayloadLines() {
    final merged = <int, ProcurementOrderLinePayload>{};

    for (final line in _lines) {
      final productId = line.produitId;
      final quantity = line.quantity;
      final price = line.unitPrice;
      final product = _findProductById(productId);
      final tauxTVA = _getVatRateForProduct(product);

      if (productId == null || quantity <= 0 || price <= 0) continue;

      final existing = merged[productId];
      merged[productId] = ProcurementOrderLinePayload(
        produitId: productId,
        quantite: (existing?.quantite ?? 0) + quantity,
        prixUnitaire: price,
        tauxTVA: tauxTVA,
      );
    }

    return merged.values.toList();
  }

  Future<void> _continueToProductStep() async {
    if (!_formKey.currentState!.validate()) return;

    if (_supplierId == null) {
      showMessage(
        context,
        'Veuillez selectionner un fournisseur.',
        error: true,
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      showMessage(context, 'Renseignez l\'adresse de livraison.', error: true);
      return;
    }

    if (_supplierProducts.isEmpty && !_loadingSupplierProducts) {
      await _loadProductsForSupplier(_supplierId!);
      if (!mounted) return;
    }

    setState(() {
      _mobileStep = 1;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_supplierId == null) {
      showMessage(
        context,
        'Veuillez selectionner un fournisseur.',
        error: true,
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      showMessage(context, 'Renseignez l\'adresse de livraison.', error: true);
      return;
    }

    final payloadLines = _buildPayloadLines();
    if (payloadLines.isEmpty) {
      showMessage(
        context,
        'Veuillez ajouter au moins un produit valide a la commande.',
        error: true,
      );
      return;
    }

    if (_isEditing) {
      Navigator.pop(
        context,
        ProcurementOrderDialogResult(
          updatePayload: ProcurementOrderUpdatePayload(
            fournisseurId: _supplierId!,
            dateLivraisonPrevue: _deliveryDate,
            adresseLivraison: _addressController.text.trim(),
            lignesCommande: payloadLines,
          ),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      ProcurementOrderDialogResult(
        createPayload: ProcurementOrderCreatePayload(
          fournisseurId: _supplierId!,
          dateLivraisonPrevue: _deliveryDate,
          adresseLivraison: _addressController.text.trim(),
          lignesCommande: payloadLines,
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required Widget child,
    bool compact = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
      ),
      decoration: BoxDecoration(
        color: _purchaseSurface,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: _purchaseBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: compact ? 10 : 14,
            offset: Offset(0, compact ? 4 : 6),
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
              color: _purchaseTextPrimary,
            ),
          ),
          SizedBox(
            height: compact
                ? _purchaseBaseUnit * 1.25
                : _purchaseBaseUnit * 1.5,
          ),
          child,
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
        horizontal: compact
            ? _purchaseBaseUnit * 1.25
            : _purchaseBaseUnit * 1.5,
        vertical: compact ? _purchaseBaseUnit : _purchaseBaseUnit * 1.3,
      ),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _purchaseTextSecondary,
                fontSize: compact ? 11.5 : 12,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _purchaseTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12.5 : 14,
              ),
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
              color: isPrimary ? _purchaseTextPrimary : _purchaseTextSecondary,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              fontSize: compact
                  ? (isPrimary ? 14 : 12.5)
                  : (isPrimary ? 15 : 13),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? _purchaseAccent : _purchaseTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: compact ? (isPrimary ? 16 : 13.5) : (isPrimary ? 18 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _purchaseBaseUnit * 1.5,
        vertical: _purchaseBaseUnit * 1.6,
      ),
      decoration: BoxDecoration(
        color: _purchaseSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _purchaseTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isPrimary ? _purchaseAccent : _purchaseTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isPrimary ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVatBreakdownCard() {
    if (_vatBreakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail de la TVA',
            style: TextStyle(
              color: _purchaseTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.2),
          Wrap(
            spacing: _purchaseBaseUnit,
            runSpacing: _purchaseBaseUnit,
            children: _vatBreakdown.entries.map((entry) {
              return Container(
                width: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _purchaseSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _purchaseBorderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TVA ${formatVatRate(entry.key)}',
                      style: const TextStyle(
                        color: _purchaseTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(entry.value.tva),
                      style: const TextStyle(
                        color: _purchasePrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Base: ${formatPrice(entry.value.ht)}',
                      style: const TextStyle(
                        color: _purchaseTextSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductPicker() async {
    if (_supplierId == null) {
      showMessage(
        context,
        'Veuillez selectionner un fournisseur.',
        error: true,
      );
      return;
    }

    final useBottomSheet =
        widget.isBottomSheet || MediaQuery.of(context).size.width < 600;

    if (_supplierProducts.isEmpty && !_loadingSupplierProducts) {
      await _loadProductsForSupplier(_supplierId!);
    }

    if (!mounted) return;

    Future<({ProcurementProduct product, int quantity})?> openPicker() {
      if (useBottomSheet) {
        return showModalBottomSheet<
          ({ProcurementProduct product, int quantity})
        >(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SupplierProductPickerDialog(
            products: _availableProducts,
            supplier: _findSupplierById(_supplierId),
            selectedProductIds: _lines
                .map((line) => line.produitId)
                .whereType<int>()
                .toSet(),
            isBottomSheet: true,
          ),
        );
      }

      return showDialog<({ProcurementProduct product, int quantity})>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SupplierProductPickerDialog(
          products: _availableProducts,
          supplier: _findSupplierById(_supplierId),
          selectedProductIds: _lines
              .map((line) => line.produitId)
              .whereType<int>()
              .toSet(),
        ),
      );
    }

    final selected = await openPicker();

    if (selected == null) return;
    _addProductToOrder(selected.product, selected.quantity);
  }

  Widget _buildPhoneStepChip({
    required int step,
    required IconData icon,
    required String label,
    required bool enabled,
  }) {
    final selected = _mobileStep == step;
    final completed = step < _mobileStep;
    final accent = selected || completed
        ? _purchasePrimary
        : _purchaseTextSecondary.withValues(alpha: 0.18);
    final foreground = selected || completed
        ? _purchasePrimary
        : _purchaseTextSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: !enabled
          ? null
          : () {
              if (step == 0) {
                setState(() {
                  _mobileStep = 0;
                });
                return;
              }
              _continueToProductStep();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? _purchasePrimary.withValues(alpha: 0.10)
              : _purchaseBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected || completed
                    ? _purchasePrimary.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                completed ? Icons.check_rounded : icon,
                size: 14,
                color: foreground,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStepBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPhoneStepChip(
            step: 0,
            icon: Icons.apartment_outlined,
            label: 'Infos',
            enabled: true,
          ),
          const SizedBox(width: 10),
          _buildPhoneStepChip(
            step: 1,
            icon: Icons.inventory_2_outlined,
            label: 'Produits',
            enabled: _isGeneralInfoReady,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHint({
    required IconData icon,
    required String title,
    required String message,
    Color color = _purchasePrimary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _purchaseTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: _purchaseTextSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsHeader({bool compact = false}) {
    final selectedSupplier = _findSupplierById(_supplierId);

    if (_supplierId == null) {
      if (compact) {
        return _buildCompactHint(
          icon: Icons.store_outlined,
          title: 'Choisissez un fournisseur',
          message: 'Selectionnez d abord un fournisseur.',
        );
      }
      return const EmptyPanel(
        title: 'Choisissez un fournisseur',
        message: 'Selectionnez un fournisseur pour charger ses produits.',
      );
    }

    if (_loadingSupplierProducts) {
      return SizedBox(
        height: compact ? 60 : null,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_supplierProductsError != null) {
      if (compact) {
        return _buildCompactHint(
          icon: Icons.error_outline,
          title: 'Produits indisponibles',
          message: _supplierProductsError!,
          color: _purchaseWarning,
        );
      }
      return EmptyPanel(
        title: 'Produits indisponibles',
        message: _supplierProductsError!,
      );
    }

    final productCount = _availableProducts.length;

    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _purchaseBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _purchaseBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedSupplier != null)
              Text(
                selectedSupplier.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _purchaseTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            if (selectedSupplier != null) const SizedBox(height: 4),
            Text(
              productCount == 0
                  ? 'Aucun produit disponible pour ce fournisseur'
                  : '$productCount produit(s) disponible(s) pour ce fournisseur',
              style: const TextStyle(
                color: _purchaseTextSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: productCount == 0 ? null : _openProductPicker,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter produit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purchasePrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedSupplier == null
                      ? 'Produits dans la commande'
                      : 'Fournisseur : ${selectedSupplier.displayName}',
                  style: const TextStyle(
                    color: _purchaseTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: productCount == 0 ? null : _openProductPicker,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter un produit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purchasePrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            productCount == 0
                ? 'Aucun produit disponible pour ce fournisseur'
                : '$productCount produit(s) disponible(s) pour ce fournisseur',
            style: const TextStyle(
              color: _purchaseTextSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(
    int index,
    _PurchaseDraftLine line, {
    bool compact = false,
  }) {
    final product = _findProductById(line.produitId);
    final isInactive = product != null && !product.active;
    final vatRate = _lineVatRate(line);

    return Container(
      key: ValueKey(line.rowKey),
      margin: EdgeInsets.only(
        bottom: compact ? _purchaseBaseUnit : _purchaseBaseUnit * 1.5,
      ),
      padding: EdgeInsets.all(
        compact ? _purchaseBaseUnit * 1.25 : _purchaseBaseUnit * 1.5,
      ),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ligne ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _purchaseTextPrimary,
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ),
              if (product != null)
                StatusPill(
                  label: isInactive ? 'Inactif' : 'Actif',
                  color: isInactive
                      ? _purchaseWarning
                      : const Color(0xFF16A34A),
                ),
              if (!line.readOnly) ...[
                const SizedBox(width: _purchaseBaseUnit),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: _purchaseError),
                  onPressed: () => _removeLine(line),
                ),
              ],
            ],
          ),
          const SizedBox(height: _purchaseBaseUnit),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product?.displayName ?? line.fallbackLabel ?? 'Produit',
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: TextStyle(
                color: _purchaseTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : 15,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              product == null
                  ? '-'
                  : '${product.categorieLabel} • TVA ${formatVatRate(vatRate)}',
              style: TextStyle(
                color: _purchaseTextSecondary,
                fontSize: compact ? 12 : 12.5,
              ),
            ),
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          if (compact)
            Column(
              children: [
                TextFormField(
                  controller: line.quantiteController,
                  readOnly: line.readOnly,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantite',
                    isDense: true,
                    prefixIcon: const Icon(Icons.tag_outlined, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => _updateLineQuantity(line, value),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Quantite invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: _purchaseBaseUnit),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _purchaseSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _purchaseBorderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: _purchaseTextSecondary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Prix unitaire',
                          style: TextStyle(
                            color: _purchaseTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        formatPrice(line.unitPrice),
                        style: const TextStyle(
                          color: _purchaseTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: _purchaseBaseUnit),
                _buildMetricCard(
                  label: 'Sous-total HT',
                  value: formatPrice(_lineSubTotal(line)),
                ),
                const SizedBox(height: _purchaseBaseUnit),
                _buildMetricCard(
                  label: 'Total TTC',
                  value: formatPrice(_lineTotalTtc(line)),
                  isPrimary: true,
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantiteController,
                    readOnly: line.readOnly,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantite',
                      prefixIcon: const Icon(Icons.tag_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => _updateLineQuantity(line, value),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Quantite invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: _purchaseBaseUnit),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _purchaseSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _purchaseBorderLight),
                    ),
                    child: Text(
                      formatPrice(line.unitPrice),
                      style: const TextStyle(
                        color: _purchaseTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _purchaseBaseUnit * 1.5),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Sous-total HT',
                    value: formatPrice(_lineSubTotal(line)),
                  ),
                ),
                const SizedBox(width: _purchaseBaseUnit),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total TTC',
                    value: formatPrice(_lineTotalTtc(line)),
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsSection({bool compact = false}) {
    final readOnlyEdit = _isEditing && !_canEditLines;

    return _buildFormSection(
      title: 'Produits',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (readOnlyEdit)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
              decoration: BoxDecoration(
                color: _purchaseBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _purchaseBorderLight),
              ),
              child: const Text(
                'En mode edition, le fournisseur et les lignes restent en lecture seule. Seuls la date de livraison et l’adresse sont modifiables.',
                style: TextStyle(color: _purchaseTextSecondary, fontSize: 12.5),
              ),
            )
          else ...[
            _buildProductsHeader(compact: compact),
          ],
          SizedBox(
            height: compact ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
          ),
          if (_lines.isEmpty)
            compact
                ? _buildCompactHint(
                    icon: Icons.inventory_2_outlined,
                    title: 'Aucune ligne',
                    message: 'Ajoutez au moins un produit a cette commande.',
                  )
                : const EmptyPanel(
                    title: 'Aucune ligne',
                    message:
                        'Ajoutez au moins un produit a cette commande fournisseur.',
                  )
          else
            ...List.generate(
              _lines.length,
              (index) => _buildLineCard(index, _lines[index], compact: compact),
            ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection({bool compact = false}) {
    return _buildFormSection(
      title: compact ? 'Informations commande' : 'Informations generales',
      compact: compact,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _supplierId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Fournisseur',
              isDense: compact,
              prefixIcon: const Icon(Icons.apartment_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _supplierOptions.map((supplier) {
              return DropdownMenuItem<int>(
                value: supplier.idFournisseur,
                child: Text(
                  _supplierOptionLabel(supplier),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _isEditing ? null : (value) => _onSupplierChanged(value),
            validator: (value) =>
                value == null ? 'Selectionnez un fournisseur' : null,
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: compact ? 3 : 4,
            decoration: InputDecoration(
              labelText: 'Adresse de livraison',
              isDense: compact,
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Renseignez l\'adresse de livraison';
              }
              return null;
            },
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _pickDeliveryDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                compact
                    ? 'Livraison ${formatDate(_deliveryDate)}'
                    : 'Livraison prevue: ${formatDate(_deliveryDate)}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({bool compact = false}) {
    final supplier = _findSupplierById(_supplierId);

    return _buildFormSection(
      title: compact ? 'Resume commande' : 'Resume de la commande',
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryTile(
            label: 'Fournisseur',
            value: supplier?.displayName ?? '-',
            compact: compact,
          ),
          const SizedBox(height: _purchaseBaseUnit),
          if (compact) ...[
            _buildSummaryTile(
              label: 'Livraison',
              value: formatDate(_deliveryDate),
              compact: true,
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Adresse',
              value: _addressController.text.trim().isEmpty
                  ? '-'
                  : _addressController.text.trim(),
              compact: true,
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Lignes',
              value: '${_lines.length}',
              compact: true,
            ),
            const SizedBox(height: _purchaseBaseUnit * 1.25),
          ] else ...[
            _buildSummaryTile(
              label: 'Telephone',
              value: supplier?.telephone.trim().isNotEmpty == true
                  ? supplier!.telephone
                  : '-',
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Email',
              value: supplier?.email.trim().isNotEmpty == true
                  ? supplier!.email
                  : '-',
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Adresse',
              value: _addressController.text.trim().isEmpty
                  ? (supplier?.adresse.trim().isNotEmpty == true
                        ? supplier!.adresse
                        : '-')
                  : _addressController.text.trim(),
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Date livraison',
              value: formatDate(_deliveryDate),
            ),
            const SizedBox(height: _purchaseBaseUnit),
            _buildSummaryTile(
              label: 'Nombre de lignes',
              value: '${_lines.length}',
            ),
            const SizedBox(height: _purchaseBaseUnit * 1.5),
            _buildVatBreakdownCard(),
            if (_vatBreakdown.isNotEmpty)
              const SizedBox(height: _purchaseBaseUnit * 1.5),
          ],
          const Divider(color: _purchaseBorderLight),
          const SizedBox(height: _purchaseBaseUnit * 1.25),
          _buildAmountRow(
            'Sous-total HT',
            formatPrice(_subTotalHt),
            compact: compact,
          ),
          const SizedBox(height: _purchaseBaseUnit),
          _buildAmountRow(
            'TVA $_vatSummaryLabel',
            formatPrice(_totalVat),
            compact: compact,
          ),
          const SizedBox(height: _purchaseBaseUnit),
          _buildAmountRow(
            'Total TTC',
            formatPrice(_totalTtc),
            isPrimary: true,
            compact: compact,
          ),
          if (!compact) ...[
            const SizedBox(height: _purchaseBaseUnit * 2),
            const Text(
              'Apercu produits',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _purchaseTextPrimary,
              ),
            ),
            const SizedBox(height: _purchaseBaseUnit),
            if (_lines.isEmpty)
              const Text(
                'Aucun produit',
                style: TextStyle(color: _purchaseTextSecondary),
              )
            else
              ..._lines.map((line) {
                final product = _findProductById(line.produitId);
                return Container(
                  margin: EdgeInsets.only(bottom: _purchaseBaseUnit),
                  padding: EdgeInsets.all(_purchaseBaseUnit * 1.25),
                  decoration: BoxDecoration(
                    color: _purchaseBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _purchaseBorderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product?.displayName ?? line.fallbackLabel ?? 'Produit'} x${line.quantity}',
                          style: const TextStyle(
                            color: _purchaseTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatPrice(_lineTotalTtc(line)),
                        style: const TextStyle(
                          color: _purchaseTextSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 860;
    final phone = MediaQuery.of(context).size.width < 560;
    final isSheet = widget.isBottomSheet;
    final usePhoneStepFlow = phone && _canEditLines;
    final availableHeight = MediaQuery.sizeOf(context).height;
    final title = _isEditing
        ? (phone ? 'Modifier la commande' : 'Modifier le bon de commande')
        : (phone ? 'Bon de commande' : 'Nouveau bon de commande');
    final subtitle = _isRejectedEdit
        ? 'Corrigez la livraison puis les lignes avant le renvoi.'
        : _isEditing
        ? 'Mettez a jour la livraison et les informations utiles.'
        : 'Creez un bon fournisseur propre et rapide sur mobile.';

    final surface = Container(
      width: isSheet
          ? double.infinity
          : AdaptiveLayout.dialogWidth(
              context,
              max: 980,
              sideMargin: phone ? 8 : 12,
            ),
      constraints: BoxConstraints(
        maxHeight: isSheet
            ? availableHeight * 0.88
            : AdaptiveLayout.dialogHeight(context, ratio: phone ? 0.94 : 0.9),
      ),
      decoration: BoxDecoration(
        color: _purchaseSurface,
        borderRadius: BorderRadius.circular(phone ? 22 : 24),
        border: Border.all(color: _purchaseBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(phone ? 22 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  phone ? _purchaseBaseUnit * 2 : _purchaseBaseUnit * 3,
                  phone ? _purchaseBaseUnit * 2 : _purchaseBaseUnit * 3,
                  phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2.5,
                  phone ? _purchaseBaseUnit * 1.25 : _purchaseBaseUnit * 2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: isSheet ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: phone ? 17 : 20,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: _purchaseTextPrimary,
                            ),
                          ),
                          if (!isSheet) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: phone ? 12.5 : 13.5,
                                color: _purchaseTextSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 3,
                    0,
                    phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 3,
                    0,
                  ),
                  child: usePhoneStepFlow
                      ? Column(
                          children: [
                            _buildPhoneStepBar(),
                            const SizedBox(height: _purchaseBaseUnit * 1.25),
                            if (_mobileStep == 0)
                              _buildGeneralSection(compact: true)
                            else ...[
                              _buildProductsSection(compact: true),
                              const SizedBox(height: _purchaseBaseUnit * 1.25),
                              _buildSummarySection(compact: true),
                            ],
                          ],
                        )
                      : compact
                      ? Column(
                          children: [
                            _buildGeneralSection(compact: true),
                            const SizedBox(height: _purchaseBaseUnit * 1.25),
                            _buildProductsSection(compact: true),
                            const SizedBox(height: _purchaseBaseUnit * 1.25),
                            _buildSummarySection(compact: true),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildGeneralSection(),
                                  const SizedBox(height: _purchaseBaseUnit * 2),
                                  _buildProductsSection(),
                                ],
                              ),
                            ),
                            const SizedBox(width: _purchaseBaseUnit * 2),
                            Expanded(flex: 2, child: _buildSummarySection()),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 3,
                  _purchaseBaseUnit * 1.25,
                  phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 3,
                  phone ? _purchaseBaseUnit * 1.5 : _purchaseBaseUnit * 2,
                ),
                child: phone
                    ? usePhoneStepFlow
                          ? Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _mobileStep == 0
                                        ? () => Navigator.of(context).pop()
                                        : () {
                                            setState(() {
                                              _mobileStep = 0;
                                            });
                                          },
                                    icon: Icon(
                                      _mobileStep == 0
                                          ? Icons.close_rounded
                                          : Icons.arrow_back_rounded,
                                      size: 18,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 42),
                                    ),
                                    label: Text(
                                      _mobileStep == 0 ? 'Annuler' : 'Retour',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _purchaseBaseUnit),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _mobileStep == 0
                                        ? _continueToProductStep
                                        : _submit,
                                    icon: Icon(
                                      _mobileStep == 0
                                          ? Icons.arrow_forward_rounded
                                          : _isEditing
                                          ? Icons.save_outlined
                                          : Icons.add_task_outlined,
                                    ),
                                    label: Text(
                                      _mobileStep == 0
                                          ? 'Continuer'
                                          : (_isEditing ? 'Modifier' : 'Creer'),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _mobileStep == 0
                                          ? _purchasePrimary
                                          : _purchaseAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 42),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 42),
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: _purchaseBaseUnit),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _submit,
                                    icon: Icon(
                                      _isEditing
                                          ? Icons.save_outlined
                                          : Icons.add_task_outlined,
                                    ),
                                    label: Text(
                                      _isEditing ? 'Modifier' : 'Creer',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _purchaseAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 42),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                    : Wrap(
                        alignment: WrapAlignment.end,
                        spacing: _purchaseBaseUnit,
                        runSpacing: _purchaseBaseUnit,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _submit,
                            icon: Icon(
                              _isEditing
                                  ? Icons.save_outlined
                                  : Icons.add_task_outlined,
                            ),
                            label: Text(_isEditing ? 'Modifier' : 'Creer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _purchaseAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: _purchaseBaseUnit * 2,
                                vertical: _purchaseBaseUnit * 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
    );

    if (isSheet) {
      return Padding(
        padding: EdgeInsets.only(
          left: _purchaseBaseUnit,
          right: _purchaseBaseUnit,
          top: _purchaseBaseUnit,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(top: false, child: surface),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(phone ? 12 : 20),
      child: surface,
    );
  }
}
