import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

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

class _ProcurementOrderFormDialogState
    extends State<ProcurementOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _addressController;
  late DateTime _deliveryDate;

  int? _supplierId;
  bool _showInactiveProducts = false;

  final List<_PurchaseDraftLine> _lines = <_PurchaseDraftLine>[];
  int _draftLineSeed = 0;

  int? _selectedCategoryId;
  int? _selectedProductId;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _priceController = TextEditingController();

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

  List<ProcurementProduct> get _visibleProducts {
    final products = widget.products.where((product) {
      if (!_showInactiveProducts && !product.active) return false;
      if (_selectedCategoryId != null &&
          product.categorie?.idCategorie != _selectedCategoryId) {
        return false;
      }
      return true;
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

  double _getVatRateForProduct(ProcurementProduct? product) {
    final raw = product?.categorie?.tauxTVA;
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

  void _onCategoryChanged(int? categoryId) {
    final nextVisibleProducts = widget.products.where((product) {
      if (!_showInactiveProducts && !product.active) return false;
      if (categoryId != null &&
          product.categorie?.idCategorie != categoryId) {
        return false;
      }
      return true;
    }).toList();

    final stillValid = _selectedProductId != null &&
        nextVisibleProducts.any((p) => p.idProduit == _selectedProductId);

    setState(() {
      _selectedCategoryId = categoryId;
      if (!stillValid) {
        _selectedProductId = null;
        _priceController.clear();
      }
    });
  }

  void _onProductChanged(int? productId) {
    final product = _findProductById(productId);
    setState(() {
      _selectedProductId = productId;
      _priceController.text = product == null
          ? ''
          : product.prixAchat.toStringAsFixed(3);
    });
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

  double _lineSubTotal(_PurchaseDraftLine line) => line.quantity * line.unitPrice;

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
    return {
      for (final key in sortedKeys) key: data[key]!,
    };
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
      for (final line in order.lignesCommande) {
        final product = _findProductById(line.produitId);
        _lines.add(
          _newDraftLine(
            produitId: line.produitId,
            categorieId: product?.categorie?.idCategorie,
            quantite: line.quantite,
            prixUnitaire: line.prixUnitaire,
            fallbackLabel: line.produitLibelle,
            readOnly: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
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

  void _resetProductSelection() {
    setState(() {
      _selectedProductId = null;
      _quantityController.text = '1';
      _priceController.clear();
    });
  }

  void _addProduct() {
    if (_isEditing) return;

    final product = _findProductById(_selectedProductId);
    final quantity = int.tryParse(_quantityController.text);
    final unitPrice = double.tryParse(_priceController.text.replaceAll(',', '.'));

    if (_supplierId == null) {
      showMessage(
        context,
        'Veuillez d’abord selectionner un fournisseur.',
        error: true,
      );
      return;
    }

    if (product == null) {
      showMessage(context, 'Veuillez selectionner un produit.', error: true);
      return;
    }

    if (quantity == null || quantity <= 0) {
      showMessage(
        context,
        'La quantite doit etre superieure a 0.',
        error: true,
      );
      return;
    }

    if (unitPrice == null || unitPrice <= 0) {
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

    _resetProductSelection();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_supplierId == null) {
      showMessage(context, 'Veuillez selectionner un fournisseur.', error: true);
      return;
    }

    if (!_isEditing && _lines.isEmpty) {
      showMessage(
        context,
        'Veuillez ajouter au moins un article.',
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

    final payloadLines = _buildPayloadLines();
    if (payloadLines.isEmpty) {
      showMessage(
        context,
        'Veuillez ajouter au moins un produit valide a la commande.',
        error: true,
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
              style: const TextStyle(color: _purchaseTextSecondary, fontSize: 12),
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
              color: isPrimary ? _purchaseTextPrimary : _purchaseTextSecondary,
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
          Text(label, style: const TextStyle(color: _purchaseTextSecondary, fontSize: 12)),
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
        color: color.withValues(alpha: 0.10),
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

  Widget _buildAddProductPanel() {
    final visibleProducts = _visibleProducts;
    final selectedProduct = _findProductById(_selectedProductId);
    final isInactive = selectedProduct != null && !selectedProduct.active;
    final vatRate = _getVatRateForProduct(selectedProduct);

    final validSelectedProductId =
        _selectedProductId != null &&
            visibleProducts.any((p) => p.idProduit == _selectedProductId)
        ? _selectedProductId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_categoryOptions.isNotEmpty) ...[
          DropdownButtonFormField<int?>(
            key: ValueKey('category_${_selectedCategoryId ?? 'all'}'),
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Categorie',
              prefixIcon: const Icon(Icons.category_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Toutes les categories'),
              ),
              ..._categoryOptions.map(
                (category) => DropdownMenuItem<int?>(
                  value: category.idCategorie,
                  child: Text(category.displayName),
                ),
              ),
            ],
            onChanged: _onCategoryChanged,
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
        ],
        DropdownButtonFormField<int?>(
          key: ValueKey(
            'product_${_selectedCategoryId ?? 'all'}_${validSelectedProductId ?? 'none'}',
          ),
          initialValue: validSelectedProductId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Produit',
            prefixIcon: const Icon(Icons.inventory_2_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Selectionner un produit'),
            ),
            ...visibleProducts.map(
              (product) => DropdownMenuItem<int?>(
                value: product.idProduit,
                child: Text(
                  '${product.displayName} - ${formatPrice(product.prixAchat)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: _onProductChanged,
        ),
        if (selectedProduct != null) ...[
          const SizedBox(height: _purchaseBaseUnit * 1.25),
          Wrap(
            spacing: _purchaseBaseUnit,
            runSpacing: _purchaseBaseUnit,
            children: [
              _buildInfoTag(
                label: 'TVA',
                value: formatVatRate(vatRate),
                color: _purchaseWarning,
              ),
              _buildInfoTag(
                label: 'Stock',
                value:
                    '${selectedProduct.quantiteStock} ${selectedProduct.unitLabel}',
                color: const Color(0xFF0F766E),
              ),
              _buildInfoTag(
                label: 'Etat',
                value: selectedProduct.active ? 'Actif' : 'Inactif',
                color: selectedProduct.active
                    ? const Color(0xFF16A34A)
                    : _purchaseWarning,
              ),
            ],
          ),
        ],
        const SizedBox(height: _purchaseBaseUnit * 1.5),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantite',
                  prefixIcon: const Icon(Icons.tag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: _purchaseBaseUnit),
            Expanded(
              child: TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Prix unitaire',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: _purchaseBaseUnit),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: validSelectedProductId == null ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInactive
                        ? _purchaseWarning
                        : _purchasePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLineCard(int index, _PurchaseDraftLine line) {
    final product = _findProductById(line.produitId);
    final isInactive = product != null && !product.active;
    final vatRate = _lineVatRate(line);

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
              style: const TextStyle(
                color: _purchaseTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
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
              style: const TextStyle(
                color: _purchaseTextSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
      ),
    );
  }

  Widget _buildProductsSection() {
    return _buildFormSection(
      title: 'Produits',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
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
                style: TextStyle(
                  color: _purchaseTextSecondary,
                  fontSize: 12.5,
                ),
              ),
            )
          else ...[
            if (widget.products.any((p) => !p.active))
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_purchaseBaseUnit * 1.5),
                decoration: BoxDecoration(
                  color: _purchaseBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _purchaseBorderLight),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Afficher les produits inactifs',
                            style: TextStyle(
                              color: _purchaseTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Le backend peut les reactiver automatiquement a la reception.',
                            style: TextStyle(
                              color: _purchaseTextSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _showInactiveProducts,
                      onChanged: (value) {
                        final nextVisibleProducts = widget.products.where((product) {
                          if (!value && !product.active) return false;
                          if (_selectedCategoryId != null &&
                              product.categorie?.idCategorie != _selectedCategoryId) {
                            return false;
                          }
                          return true;
                        }).toList();

                        final stillValid = _selectedProductId != null &&
                            nextVisibleProducts.any(
                              (p) => p.idProduit == _selectedProductId,
                            );

                        setState(() {
                          _showInactiveProducts = value;
                          if (!stillValid) {
                            _selectedProductId = null;
                            _priceController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: _purchaseBaseUnit * 1.5),
            _buildAddProductPanel(),
          ],
          const SizedBox(height: _purchaseBaseUnit * 2),
          if (_lines.isEmpty)
            const EmptyPanel(
              title: 'Aucune ligne',
              message: 'Ajoutez au moins un produit a cette commande fournisseur.',
            )
          else
            ...List.generate(_lines.length, (index) => _buildLineCard(index, _lines[index])),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return _buildFormSection(
      title: 'Informations generales',
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _supplierId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Fournisseur',
              prefixIcon: const Icon(Icons.apartment_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            onChanged: _isEditing ? null : _onSupplierChanged,
            validator: (value) =>
                value == null ? 'Selectionnez un fournisseur' : null,
          ),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          TextFormField(
            controller: _addressController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Adresse de livraison',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              label: Text('Livraison prevue: ${formatDate(_deliveryDate)}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final supplier = _findSupplierById(_supplierId);

    return _buildFormSection(
      title: 'Resume de la commande',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryTile(
            label: 'Fournisseur',
            value: supplier?.displayName ?? '-',
          ),
          const SizedBox(height: _purchaseBaseUnit),
          _buildSummaryTile(
            label: 'Telephone',
            value: supplier?.telephone.trim().isNotEmpty == true
                ? supplier!.telephone
                : '-',
          ),
          const SizedBox(height: _purchaseBaseUnit),
          _buildSummaryTile(
            label: 'Email',
            value: supplier?.email.trim().isNotEmpty == true ? supplier!.email : '-',
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
          _buildSummaryTile(label: 'Nombre de lignes', value: '${_lines.length}'),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          _buildVatBreakdownCard(),
          if (_vatBreakdown.isNotEmpty)
            const SizedBox(height: _purchaseBaseUnit * 1.5),
          const Divider(color: _purchaseBorderLight),
          const SizedBox(height: _purchaseBaseUnit * 1.5),
          _buildAmountRow('Sous-total HT', formatPrice(_subTotalHt)),
          const SizedBox(height: _purchaseBaseUnit),
          _buildAmountRow('TVA $_vatSummaryLabel', formatPrice(_totalVat)),
          const SizedBox(height: _purchaseBaseUnit),
          _buildAmountRow('Total TTC', formatPrice(_totalTtc), isPrimary: true),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 860;

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
                          ? 'Modifier le bon de commande'
                          : 'Nouveau bon de commande',
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
                      'Workflow web',
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
                  child: compact
                      ? Column(
                          children: [
                            _buildGeneralSection(),
                            const SizedBox(height: _purchaseBaseUnit * 2),
                            _buildProductsSection(),
                            const SizedBox(height: _purchaseBaseUnit * 2),
                            _buildSummarySection(),
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
                            Expanded(
                              flex: 2,
                              child: _buildSummarySection(),
                            ),
                          ],
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
            ],
          ),
        ),
      ),
    );
  }
}
