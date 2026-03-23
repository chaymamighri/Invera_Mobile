import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/services/procurement_service.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

class ProcurementProductsSection extends StatefulWidget {
  const ProcurementProductsSection({super.key});

  @override
  State<ProcurementProductsSection> createState() =>
      _ProcurementProductsSectionState();
}

class _ProcurementProductsSectionState
    extends State<ProcurementProductsSection> {
  final ProcurementService _service = ProcurementService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ProcurementCategory> _categories = const [];
  List<ProcurementProduct> _products = const [];

  String _statusFilter = '';
  String _activityFilter = 'all';
  bool _lowStockOnly = false;
  int? _categoryId;

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
      final results = await Future.wait([
        _service.getCategories(),
        _service.getProducts(),
      ]);

      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<ProcurementCategory>;
        _products = results[1] as List<ProcurementProduct>;
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

  List<ProcurementProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.displayName.toLowerCase().contains(query) ||
          product.categorieLabel.toLowerCase().contains(query) ||
          product.unitLabel.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter.isEmpty ||
          product.status.toUpperCase() == _statusFilter;
      final matchesActivity =
          _activityFilter == 'all' ||
          (_activityFilter == 'active' && product.active) ||
          (_activityFilter == 'inactive' && !product.active);
      final matchesCategory =
          _categoryId == null || product.categorie?.idCategorie == _categoryId;
      final matchesLowStock = !_lowStockOnly || product.isLowStock;
      return matchesQuery &&
          matchesStatus &&
          matchesActivity &&
          matchesCategory &&
          matchesLowStock;
    }).toList();

    filtered.sort((a, b) {
      if (a.active != b.active) return a.active ? -1 : 1;
      if (a.isLowStock != b.isLowStock) return a.isLowStock ? -1 : 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return filtered;
  }

  Future<void> _showProductDialog({ProcurementProduct? initial}) async {
    if (_categories.isEmpty) {
      showMessage(
        context,
        'Aucune categorie disponible pour enregistrer un produit.',
        error: true,
      );
      return;
    }

    final payload = await showDialog<ProductUpsertPayload>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ProductFormDialog(categories: _categories, initialProduct: initial),
    );

    if (payload == null) return;

    try {
      if (initial == null) {
        final created = await _service.createProduct(payload);
        if (!mounted) return;
        setState(() {
          _products = [created, ..._products];
        });
        showMessage(context, 'Produit cree avec succes.');
      } else {
        final updated = await _service.updateProduct(
          initial.idProduit,
          payload,
        );
        if (!mounted) return;
        setState(() {
          _products = [
            for (final product in _products)
              if (product.idProduit == updated.idProduit) updated else product,
          ];
        });
        showMessage(context, 'Produit mis a jour avec succes.');
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

  Future<void> _showStockDialog(ProcurementProduct product) async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (_) => StockAdjustDialog(initialQuantity: product.quantiteStock),
    );

    if (quantity == null) return;

    try {
      final updated = await _service.updateProductStock(
        product.idProduit,
        quantity,
      );
      if (!mounted) return;
      setState(() {
        _products = [
          for (final item in _products)
            if (item.idProduit == updated.idProduit) updated else item,
        ];
      });
      showMessage(context, 'Stock ajuste avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _toggleProductActivation(ProcurementProduct product) async {
    final activate = !product.active;
    final confirmed = await showConfirmationDialog(
      context,
      title: activate ? 'Reactiver le produit' : 'Desactiver le produit',
      message: activate
          ? 'Voulez-vous reactiver ${product.displayName} ?'
          : 'Voulez-vous desactiver ${product.displayName} ?',
      confirmLabel: activate ? 'Reactiver' : 'Desactiver',
      confirmColor: activate ? const Color(0xFF16A34A) : Colors.red,
    );

    if (confirmed != true) return;

    try {
      final updated = activate
          ? await _service.reactivateProduct(product.idProduit)
          : await () async {
              await _service.deleteProduct(product.idProduit);
              return product.copyWith(active: false);
            }();

      if (!mounted) return;
      setState(() {
        _products = [
          for (final item in _products)
            if (item.idProduit == product.idProduit) updated else item,
        ];
      });
      showMessage(
        context,
        activate
            ? 'Produit reactive avec succes.'
            : 'Produit desactive avec succes.',
      );
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
      return const LoadingPanel(message: 'Chargement des produits...');
    }

    if (_error != null) {
      return AsyncErrorCard(
        title: 'Impossible de charger les produits',
        message: _error!,
        onRetry: _loadData,
      );
    }

    final filteredProducts = _filteredProducts;
    final activeCount = _products.where((product) => product.active).length;
    final inactiveCount = _products.where((product) => !product.active).length;
    final lowStockCount = _products
        .where((product) => product.active && product.isLowStock)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            InfoStatCard(
              label: 'Produits total',
              value: '${_products.length}',
              helper: '$activeCount actif(s)',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF2D47C8),
            ),
            InfoStatCard(
              label: 'Stock faible',
              value: '$lowStockCount',
              helper: 'Surveillance requise',
              icon: Icons.priority_high_rounded,
              color: const Color(0xFFEA580C),
            ),
            InfoStatCard(
              label: 'Inactifs',
              value: '$inactiveCount',
              helper: 'Reactives a la reception si besoin',
              icon: Icons.pause_circle_outline,
              color: const Color(0xFF64748B),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionSurface(
          title: 'Filtres catalogue',
          subtitle: 'Recherchez rapidement par nom, categorie, statut ou stock',
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
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un produit',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter.isEmpty
                          ? null
                          : _statusFilter,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'EN_STOCK',
                          child: Text('En stock'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'FAIBLE',
                          child: Text('Stock faible'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'CRITIQUE',
                          child: Text('Stock critique'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'RUPTURE',
                          child: Text('Rupture'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value ?? '';
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<int?>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Categorie'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Toutes'),
                        ),
                        ..._categories.map(
                          (category) => DropdownMenuItem<int?>(
                            value: category.idCategorie,
                            child: Text(category.displayName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _categoryId = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      initialValue: _activityFilter,
                      decoration: const InputDecoration(labelText: 'Etat'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('Tous'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'active',
                          child: Text('Actifs'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'inactive',
                          child: Text('Inactifs'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _activityFilter = value ?? 'all';
                        });
                      },
                    ),
                  ),
                  FilterChip(
                    selected: _lowStockOnly,
                    onSelected: (value) {
                      setState(() {
                        _lowStockOnly = value;
                      });
                    },
                    label: const Text('Stock faible'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau produit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _statusFilter = '';
                    _activityFilter = 'all';
                    _lowStockOnly = false;
                    _categoryId = null;
                  });
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Reinitialiser les filtres'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (filteredProducts.isEmpty)
          const EmptyPanel(
            title: 'Aucun produit trouve',
            message:
                'Essayez de modifier les filtres ou ajoutez un nouveau produit.',
          )
        else
          Column(
            children: [
              for (final product in filteredProducts) ...[
                ProductCard(
                  product: product,
                  onEdit: () => _showProductDialog(initial: product),
                  onAdjustStock: () => _showStockDialog(product),
                  onToggleActive: () => _toggleProductActivation(product),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class ProductFormDialog extends StatefulWidget {
  final List<ProcurementCategory> categories;
  final ProcurementProduct? initialProduct;

  const ProductFormDialog({
    super.key,
    required this.categories,
    required this.initialProduct,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _discountController;

  int? _categoryId;
  String _unit = 'PIECE';
  bool _active = true;

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.displayName ?? '');
    _salePriceController = TextEditingController(
      text: product != null ? product.prixVente.toStringAsFixed(3) : '',
    );
    _purchasePriceController = TextEditingController(
      text: product != null ? product.prixAchat.toStringAsFixed(3) : '',
    );
    _stockController = TextEditingController(
      text: product != null ? '${product.quantiteStock}' : '0',
    );
    _thresholdController = TextEditingController(
      text: product != null ? '${product.seuilMinimum}' : '10',
    );
    _discountController = TextEditingController(
      text: product?.remiseTemporaire?.toStringAsFixed(1) ?? '',
    );

    _categoryId =
        product?.categorie?.idCategorie ??
        (widget.categories.isNotEmpty
            ? widget.categories.first.idCategorie
            : null);
    _unit = product?.uniteMesure.toUpperCase() ?? 'PIECE';
    _active = product?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) return;

    final payload = ProductUpsertPayload(
      libelle: _nameController.text.trim(),
      prixVente: double.parse(_salePriceController.text.replaceAll(',', '.')),
      prixAchat: double.parse(
        _purchasePriceController.text.replaceAll(',', '.'),
      ),
      categorieId: _categoryId!,
      quantiteStock: int.parse(_stockController.text),
      seuilMinimum: int.parse(_thresholdController.text),
      uniteMesure: _unit,
      remiseTemporaire: _discountController.text.trim().isEmpty
          ? null
          : double.parse(_discountController.text.replaceAll(',', '.')),
      active: _active,
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: Text(_isEditing ? 'Modifier le produit' : 'Nouveau produit'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Libelle'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Saisissez le libelle du produit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Categorie'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.idCategorie,
                          child: Text(category.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prix achat',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Prix achat invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prix vente',
                        ),
                        validator: (value) {
                          final parsed = double.tryParse(
                            (value ?? '').replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Prix vente invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantite stock',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Stock invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seuil minimum',
                        ),
                        validator: (value) {
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Seuil invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Unite de mesure',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'PIECE',
                            child: Text('Piece'),
                          ),
                          DropdownMenuItem(
                            value: 'KILOGRAMME',
                            child: Text('Kilogramme'),
                          ),
                          DropdownMenuItem(
                            value: 'GRAMME',
                            child: Text('Gramme'),
                          ),
                          DropdownMenuItem(
                            value: 'LITRE',
                            child: Text('Litre'),
                          ),
                          DropdownMenuItem(
                            value: 'MILLILITRE',
                            child: Text('Millilitre'),
                          ),
                          DropdownMenuItem(
                            value: 'METRE',
                            child: Text('Metre'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _unit = value ?? 'PIECE';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Remise temporaire (%)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed < 0) {
                            return 'Remise invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _active,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produit actif'),
                  subtitle: const Text(
                    'Les produits inactifs peuvent etre reactives plus tard.',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Note: l\'upload d\'image n\'est pas encore disponible dans cette version Flutter. Le reste du cycle produit est gere.',
                  style: TextStyle(color: Color(0xFF607089), fontSize: 12),
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

class StockAdjustDialog extends StatefulWidget {
  final int initialQuantity;

  const StockAdjustDialog({super.key, required this.initialQuantity});

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.initialQuantity}',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, int.parse(_quantityController.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajuster le stock'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nouvelle quantite'),
          validator: (value) {
            final parsed = int.tryParse(value ?? '');
            if (parsed == null || parsed < 0) {
              return 'La quantite doit etre positive';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Enregistrer')),
      ],
    );
  }
}
