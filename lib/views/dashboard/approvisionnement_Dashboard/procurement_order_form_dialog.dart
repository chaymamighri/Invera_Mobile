import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

const double _purchaseBaseUnit = 8.0;
const double _purchaseVatRate = 0.19;
const Color _purchasePrimary = Color(0xFF2D47C8);
const Color _purchasePrimaryDark = Color(0xFF2037A7);
const Color _purchaseAccent = Color(0xFF0CAE4A);
const Color _purchaseBackground = Color(0xFFF4F7FC);
const Color _purchaseSurface = Colors.white;
const Color _purchaseTextPrimary = Color(0xFF1F2A44);
const Color _purchaseTextSecondary = Color(0xFF607089);
const Color _purchaseBorderLight = Color(0xFFE6EAF2);
const Color _purchaseError = Color(0xFFB42318);

class ProcurementOrderDialogResult {
  final ProcurementOrderCreatePayload? createPayload;
  final ProcurementOrderUpdatePayload? updatePayload;

  const ProcurementOrderDialogResult({this.createPayload, this.updatePayload});
}

class ProcurementOrderFormDialog extends StatefulWidget {
  final List<ProcurementSupplier> suppliers;
  final List<ProcurementProduct> products;
  final ProcurementOrder? initialOrder;

  const ProcurementOrderFormDialog({
    super.key,
    required this.suppliers,
    required this.products,
    required this.initialOrder,
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

  _PurchaseDraftLine({
    required this.rowKey,
    this.categorieId,
    this.produitId,
    int quantite = 1,
    double? prixUnitaire,
    this.fallbackLabel,
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

class _ProcurementOrderFormDialogState
    extends State<ProcurementOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late DateTime _deliveryDate;

  int? _supplierId;
  bool _showInactiveProducts = false;
  final List<_PurchaseDraftLine> _lines = <_PurchaseDraftLine>[];
  int _draftLineSeed = 0;

  bool get _isEditing => widget.initialOrder != null;

  List<ProcurementCategory> get _categoryOptions {
    final categories = <int, ProcurementCategory>{};
    for (final product in widget.products) {
      final category = product.categorie;
      if (category != null) {
        categories[category.idCategorie] = category;
      }
    }

    final list = categories.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  List<ProcurementSupplier> get _supplierOptions {
    final map = <int, ProcurementSupplier>{
      for (final supplier in widget.suppliers)
        supplier.idFournisseur: supplier,
    };
    final initialSupplier = widget.initialOrder?.fournisseur;
    if (initialSupplier != null) {
      map.putIfAbsent(initialSupplier.idFournisseur, () => initialSupplier);
    }
    final suppliers = map.values.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return suppliers;
  }

  List<ProcurementProduct> get _selectableProducts {
    final products = widget.products.where((product) {
      return _showInactiveProducts || product.active;
    }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    return products;
  }

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
      return widget.products.firstWhere((p) => p.idProduit == productId);
    } catch (_) {
      return null;
    }
  }

  String _supplierOptionLabel(ProcurementSupplier supplier) {
    final contact = supplier.telephone.trim().isNotEmpty
        ? supplier.telephone.trim()
        : supplier.email.trim();
    if (contact.isEmpty) return supplier.displayName;
    return '${supplier.displayName} ($contact)';
  }

  void _onSupplierChanged(int? supplierId) {
    final previousSupplier = _findSupplierById(_supplierId);
    final nextSupplier = _findSupplierById(supplierId);
    final currentAddress = _addressController.text.trim();
    final previousAddress = previousSupplier?.adresse.trim() ?? '';
    final shouldPrefillAddress =
        currentAddress.isEmpty ||
        (previousAddress.isNotEmpty && currentAddress == previousAddress);

    setState(() {
      _supplierId = supplierId;
      if (!_isEditing &&
          nextSupplier != null &&
          shouldPrefillAddress &&
          nextSupplier.adresse.trim().isNotEmpty) {
        _addressController.text = nextSupplier.adresse.trim();
      }
    });
  }

  String _summaryAddress(ProcurementSupplier? supplier) {
    final supplierAddress = supplier?.adresse.trim() ?? '';
    if (supplierAddress.isNotEmpty) return supplierAddress;

    final typedAddress = _addressController.text.trim();
    if (typedAddress.isNotEmpty) return typedAddress;

    return '-';
  }

  _PurchaseDraftLine _newDraftLine({
    int? categorieId,
    int? produitId,
    int quantite = 1,
    double? prixUnitaire,
    String? fallbackLabel,
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
    );
  }

  List<ProcurementProduct> _availableProductsForLine(
    _PurchaseDraftLine currentLine,
  ) {
    final selected = <int>{};
    for (final line in _lines) {
      if (line.rowKey == currentLine.rowKey) continue;
      if (line.produitId != null) selected.add(line.produitId!);
    }

    return widget.products
        .where((product) {
          final matchesCategory =
              currentLine.categorieId == null ||
              product.categorie?.idCategorie == currentLine.categorieId;
          final canShow =
              _showInactiveProducts ||
              product.active ||
              product.idProduit == currentLine.produitId;
          return matchesCategory &&
              canShow &&
              (product.idProduit == currentLine.produitId ||
                  !selected.contains(product.idProduit));
        })
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  int? _firstAvailableProductId(
    List<_PurchaseDraftLine> lines, {
    int? categorieId,
  }) {
    final selected = lines.map((line) => line.produitId).whereType<int>().toSet();
    for (final product in _selectableProducts) {
      if (categorieId != null &&
          product.categorie?.idCategorie != categorieId) {
        continue;
      }
      if (!selected.contains(product.idProduit)) return product.idProduit;
    }
    return null;
  }

  ProcurementProduct? _firstAvailableProductForLine(
    _PurchaseDraftLine currentLine, {
    int? categorieId,
  }) {
    final selected = <int>{};
    for (final line in _lines) {
      if (line.rowKey == currentLine.rowKey) continue;
      if (line.produitId != null) selected.add(line.produitId!);
    }

    final products = _selectableProducts.where((product) {
      final matchesCategory =
          categorieId == null || product.categorie?.idCategorie == categorieId;
      return matchesCategory && !selected.contains(product.idProduit);
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (products.isEmpty) return null;
    return products.first;
  }

  double _lineSubTotal(_PurchaseDraftLine line) => line.quantity * line.unitPrice;

  double _lineTotalTtc(_PurchaseDraftLine line) =>
      _lineSubTotal(line) * (1 + _purchaseVatRate);

  double get _subTotalHt =>
      _lines.fold<double>(0, (sum, line) => sum + _lineSubTotal(line));

  double get _totalVat => _subTotalHt * _purchaseVatRate;

  double get _totalTtc => _subTotalHt + _totalVat;

  bool get _canAddProduct =>
      !_isEditing && _firstAvailableProductId(_lines) != null;

  @override
  void initState() {
    super.initState();
    final order = widget.initialOrder;
    _addressController = TextEditingController(
      text: order?.adresseLivraison ?? '',
    );
    _deliveryDate = order?.dateLivraisonPrevue ?? DateTime.now();
    _supplierId = order?.fournisseur?.idFournisseur;

    if (order != null && order.produits.isNotEmpty) {
      for (final line in order.produits) {
        _lines.add(
          _newDraftLine(
            produitId: line.produitId,
            quantite: line.quantite,
            prixUnitaire: line.prixUnitaire,
            fallbackLabel: line.libelle,
          ),
        );
      }
    } else {
      final firstProductId = _firstAvailableProductId(_lines);
      if (firstProductId != null) {
        _lines.add(_newDraftLine(produitId: firstProductId));
      }
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

  void _onLineProductChanged(_PurchaseDraftLine line, int? productId) {
    final product = _findProductById(productId);
    setState(() {
      line.categorieId = product?.categorie?.idCategorie;
      line.produitId = productId;
      line.prixController.text = product?.prixAchat.toStringAsFixed(3) ?? '';
    });
  }

  void _onLineCategoryChanged(_PurchaseDraftLine line, int? categorieId) {
    final currentProduct = _findProductById(line.produitId);
    final keepCurrent =
        currentProduct != null &&
        (categorieId == null ||
            currentProduct.categorie?.idCategorie == categorieId);
    final nextProduct = keepCurrent
        ? currentProduct
        : _firstAvailableProductForLine(line, categorieId: categorieId);

    setState(() {
      line.categorieId = categorieId;
      line.produitId = nextProduct?.idProduit;
      line.prixController.text = nextProduct?.prixAchat.toStringAsFixed(3) ?? '';
    });
  }

  void _addDraftLine() {
    final nextProductId = _firstAvailableProductId(_lines);
    if (nextProductId == null) return;

    setState(() {
      _lines.add(_newDraftLine(produitId: nextProductId));
    });
  }

  void _removeLine(_PurchaseDraftLine line) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines.remove(line);
    });
    line.dispose();
  }

  List<ProcurementOrderLinePayload> _buildPayloadLines() {
    final merged = <int, ProcurementOrderLinePayload>{};

    for (final line in _lines) {
      final productId = line.produitId;
      final quantity = line.quantity;
      final price = line.unitPrice;
      if (productId == null || quantity <= 0 || price <= 0) continue;

      final existing = merged[productId];
      merged[productId] = ProcurementOrderLinePayload(
        produitId: productId,
        quantite: (existing?.quantite ?? 0) + quantity,
        prixUnitaire: price,
      );
    }

    return merged.values.toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_supplierId == null) {
      showMessage(context, 'Choisissez un fournisseur.', error: true);
      return;
    }

    final payloadLines = _buildPayloadLines();
    if (!_isEditing && payloadLines.isEmpty) {
      showMessage(
        context,
        'Ajoutez au moins un produit valide a la commande.',
        error: true,
      );
      return;
    }

    if (_isEditing) {
      Navigator.pop(
        context,
        ProcurementOrderDialogResult(
          updatePayload: ProcurementOrderUpdatePayload(
            dateLivraisonPrevue: _deliveryDate,
            adresseLivraison: _addressController.text.trim(),
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

  Widget _buildFormSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_purchaseBaseUnit * 2),
      decoration: BoxDecoration(
        color: _purchaseSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purchaseBorderLight),
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
              color: _purchaseTextPrimary,
            ),
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryTile({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _purchaseBaseUnit * 1.5,
        vertical: _purchaseBaseUnit * 1.3,
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
              style: const TextStyle(
                color: _purchaseTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _purchaseTextPrimary,
                fontWeight: FontWeight.w700,
              ),
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
              color: isPrimary
                  ? _purchaseTextPrimary
                  : _purchaseTextSecondary,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              fontSize: isPrimary ? 15 : 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? _purchaseAccent : _purchaseTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: isPrimary ? 18 : 14,
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
            style: const TextStyle(
              color: _purchaseTextSecondary,
              fontSize: 12,
            ),
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

  Widget _buildInfoTag({
    required String label,
    required String value,
    Color color = _purchasePrimary,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _purchaseBaseUnit * 1.25,
        vertical: _purchaseBaseUnit,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  List<DropdownMenuItem<int>> _productMenuItems(
    _PurchaseDraftLine line,
    List<ProcurementProduct> availableProducts,
  ) {
    final items = availableProducts.map((product) {
      return DropdownMenuItem<int>(
        value: product.idProduit,
        child: Text(
          '${product.displayName} (${product.active ? 'actif' : 'inactif'})',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();

    final missingCurrent =
        line.produitId != null &&
        !availableProducts.any((product) => product.idProduit == line.produitId);
    if (missingCurrent) {
      items.insert(
        0,
        DropdownMenuItem<int>(
          value: line.produitId,
          child: Text(line.fallbackLabel ?? 'Produit #${line.produitId}'),
        ),
      );
    }

    return items;
  }

  Widget _buildDraftLineCard(int index, _PurchaseDraftLine line) {
    final availableProducts = _availableProductsForLine(line);
    final product = _findProductById(line.produitId);
    final isInactive = product != null && !product.active;

    return Container(
      key: ValueKey(line.rowKey),
      margin: EdgeInsets.only(bottom: _purchaseBaseUnit * 1.5),
      padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
      decoration: BoxDecoration(
        color: _purchaseBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purchaseBorderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ligne ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _purchaseTextPrimary,
                  ),
                ),
              ),
              if (product != null)
                StatusPill(
                  label: isInactive ? 'Inactif' : 'Actif',
                  color: isInactive
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF16A34A),
                ),
              const SizedBox(width: _purchaseBaseUnit),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: _purchaseError),
                onPressed: _isEditing || _lines.length <= 1
                    ? null
                    : () => _removeLine(line),
              ),
            ],
          ),
          DropdownButtonFormField<int?>(
            initialValue: line.categorieId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Categorie',
              prefixIcon: const Icon(Icons.category_outlined),
              helperText: _isEditing
                  ? 'Categorie conservee sur cette ligne.'
                  : 'Filtre la liste des produits de cette ligne.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Toutes les categories'),
              ),
              ..._categoryOptions.map(
                (category) => DropdownMenuItem<int?>(
                  value: category.idCategorie,
                  child: Text(
                    category.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _isEditing
                ? null
                : (value) => _onLineCategoryChanged(line, value),
          ),
          const SizedBox(height: _purchaseBaseUnit),
          DropdownButtonFormField<int>(
            key: ValueKey(
              'product_${line.rowKey}_${line.categorieId}_${line.produitId}',
            ),
            initialValue: line.produitId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Produit',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              helperText: !_isEditing && availableProducts.isEmpty
                  ? 'Aucun produit disponible pour cette categorie.'
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _productMenuItems(line, availableProducts),
            onChanged: _isEditing
                ? null
                : (value) => _onLineProductChanged(line, value),
            validator: (value) => value == null ? 'Requis' : null,
          ),
          if (product != null) ...[
            const SizedBox(height: _purchaseBaseUnit),
            Wrap(
              spacing: _purchaseBaseUnit,
              runSpacing: _purchaseBaseUnit,
              children: [
                _buildInfoTag(
                  label: 'Categorie',
                  value: product.categorieLabel,
                ),
                _buildInfoTag(
                  label: 'Stock',
                  value: '${product.quantiteStock} ${product.unitLabel}',
                  color: const Color(0xFF0F766E),
                ),
                _buildInfoTag(
                  label: 'TVA',
                  value:
                      '${(_purchaseVatRate * 100).toStringAsFixed(0)}%',
                  color: const Color(0xFFEA580C),
                ),
              ],
            ),
          ],
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.quantiteController,
                  readOnly: _isEditing,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantite',
                    prefixIcon: const Icon(Icons.tag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                child: TextFormField(
                  controller: line.prixController,
                  readOnly: _isEditing,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Prix unitaire achat',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    helperText: _isEditing
                        ? 'Prix conserve sur cette commande.'
                        : 'Prix pre-rempli depuis le catalogue, modifiable si besoin.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final parsed = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Prix invalide';
                    }
                    return null;
                  },
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
                  value: formatMoney(_lineSubTotal(line)),
                ),
              ),
              const SizedBox(width: _purchaseBaseUnit),
              Expanded(
                child: _buildMetricCard(
                  label: 'Total TTC',
                  value: formatMoney(_lineTotalTtc(line)),
                  isPrimary: true,
                ),
              ),
            ],
          ),
          if (line.quantity > 0) ...[
            const SizedBox(height: _purchaseBaseUnit),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${product?.displayName ?? line.fallbackLabel ?? 'Produit'} x${line.quantity}',
                style: const TextStyle(
                  color: _purchaseTextSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedSupplier = _findSupplierById(_supplierId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: AdaptiveLayout.dialogWidth(context, max: 980, sideMargin: 12),
        constraints: BoxConstraints(
          maxHeight: AdaptiveLayout.dialogHeight(context, ratio: 0.9),
        ),
        padding: EdgeInsets.all(_purchaseBaseUnit * 3),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing
                          ? 'Modifier la commande fournisseur'
                          : 'Nouvelle commande fournisseur',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _purchaseTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _purchaseBaseUnit * 1.5,
                      vertical: _purchaseBaseUnit,
                    ),
                    decoration: BoxDecoration(
                      color: _purchaseBackground,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _purchaseBorderLight),
                    ),
                    child: const Text(
                      'Interface unique',
                      style: TextStyle(
                        color: _purchasePrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: _purchaseBaseUnit),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: _purchaseBaseUnit * 2),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 860;

                      final leftPanel = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormSection(
                            title: 'Informations generales',
                            child: Column(
                              children: [
                                DropdownButtonFormField<int>(
                                  initialValue: _supplierId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Fournisseur',
                                    prefixIcon:
                                        const Icon(Icons.apartment_outlined),
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
                                  onChanged: _isEditing
                                      ? null
                                      : _onSupplierChanged,
                                  validator: (value) => value == null
                                      ? 'Selectionnez un fournisseur'
                                      : null,
                                ),
                                const SizedBox(height: _purchaseBaseUnit * 1.5),
                                TextFormField(
                                  controller: _addressController,
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: 'Adresse de livraison',
                                    prefixIcon:
                                        const Icon(Icons.location_on_outlined),
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
                                      'Livraison prevue: ${formatDate(_deliveryDate)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: _purchaseBaseUnit * 1.5),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(
                                    _purchaseBaseUnit * 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purchaseBackground,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _purchaseBorderLight,
                                    ),
                                  ),
                                  child: _isEditing
                                      ? const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Edition limitee',
                                              style: TextStyle(
                                                color: _purchaseTextPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Le backend permet ici la mise a jour de la date et de l\'adresse. Le fournisseur et les lignes restent en lecture seule.',
                                              style: TextStyle(
                                                color: _purchaseTextSecondary,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Afficher les produits inactifs',
                                                    style: TextStyle(
                                                      color:
                                                          _purchaseTextPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Le backend peut les reactiver automatiquement a la reception.',
                                                    style: TextStyle(
                                                      color:
                                                          _purchaseTextSecondary,
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Switch.adaptive(
                                              value: _showInactiveProducts,
                                              onChanged: (value) {
                                                setState(() {
                                                  _showInactiveProducts = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: _purchaseBaseUnit * 2),
                          _buildFormSection(
                            title: 'Produits',
                            child: Column(
                              children: [
                                if (_lines.isEmpty)
                                  const EmptyPanel(
                                    title: 'Aucune ligne',
                                    message:
                                        'Ajoutez au moins un produit a cette commande fournisseur.',
                                  )
                                else
                                  ...List.generate(
                                    _lines.length,
                                    (index) =>
                                        _buildDraftLineCard(index, _lines[index]),
                                  ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _canAddProduct ? _addDraftLine : null,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Ajouter un produit'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final rightPanel = _buildFormSection(
                        title: 'Resume de la commande',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryTile(
                              label: 'Fournisseur',
                              value: selectedSupplier?.displayName ?? '-',
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            _buildSummaryTile(
                              label: 'Telephone',
                              value: selectedSupplier?.telephone ?? '-',
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            _buildSummaryTile(
                              label: 'Email',
                              value: selectedSupplier?.email ?? '-',
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            _buildSummaryTile(
                              label: 'Adresse',
                              value: _summaryAddress(selectedSupplier),
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
                            const Divider(color: _purchaseBorderLight),
                            const SizedBox(height: _purchaseBaseUnit * 1.5),
                            _buildAmountRow(
                              'Sous-total HT',
                              formatMoney(_subTotalHt),
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            _buildAmountRow(
                              'TVA ${(100 * _purchaseVatRate).toStringAsFixed(0)}%',
                              formatMoney(_totalVat),
                            ),
                            const SizedBox(height: _purchaseBaseUnit),
                            _buildAmountRow(
                              'Total TTC',
                              formatMoney(_totalTtc),
                              isPrimary: true,
                            ),
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
                                style: TextStyle(
                                  color: _purchaseTextSecondary,
                                ),
                              )
                            else
                              ..._lines.map((line) {
                                final product = _findProductById(line.produitId);
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: _purchaseBaseUnit,
                                  ),
                                  padding: EdgeInsets.all(
                                    _purchaseBaseUnit * 1.25,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purchaseBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _purchaseBorderLight,
                                    ),
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
                                        formatMoney(_lineTotalTtc(line)),
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
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            leftPanel,
                            const SizedBox(height: _purchaseBaseUnit * 2),
                            rightPanel,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: leftPanel),
                          const SizedBox(width: _purchaseBaseUnit * 2),
                          Expanded(flex: 2, child: rightPanel),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: _purchaseBaseUnit * 2),
              Wrap(
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
                      _isEditing ? Icons.save_outlined : Icons.add_task_outlined,
                    ),
                    label: Text(_isEditing ? 'Enregistrer' : 'Creer'),
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
            ],
          ),
        ),
      ),
    );
  }
}
