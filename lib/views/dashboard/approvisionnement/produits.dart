import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';
import 'package:invera_mobile/widgets/approvisionnement/formulaire_produit.dart';

/// Widget qui affiche la section des produits d'approvisionnement.
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
  List<ProcurementSupplier> _suppliers = const [];
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
        _service.getSuppliers(),
        _service.getProducts(),
      ]);

      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<ProcurementCategory>;
        _suppliers = results[1] as List<ProcurementSupplier>;
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

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty ||
      _statusFilter.isNotEmpty ||
      _activityFilter != 'all' ||
      _lowStockOnly ||
      _categoryId != null;

  int get _activeFilterCount {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_statusFilter.isNotEmpty) count++;
    if (_activityFilter != 'all') count++;
    if (_lowStockOnly) count++;
    if (_categoryId != null) count++;
    return count;
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = '';
      _activityFilter = 'all';
      _lowStockOnly = false;
      _categoryId = null;
    });
  }

  ProcurementSupplier? _supplierFor(int? supplierId) {
    if (supplierId == null) return null;
    for (final supplier in _suppliers) {
      if (supplier.idFournisseur == supplierId) return supplier;
    }
    return null;
  }

  String _supplierLabelFor(ProcurementProduct product) {
    return _supplierFor(product.fournisseurId)?.displayName ??
        'Sans fournisseur';
  }

  InputDecoration _filterDecoration(String label, {bool compact = false}) {
    return InputDecoration(
      labelText: label,
      isDense: compact,
      filled: true,
      fillColor: procurementSoftBackground,
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 11 : 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        borderSide: const BorderSide(color: procurementLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        borderSide: const BorderSide(color: procurementLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        borderSide: const BorderSide(color: procurementPrimary, width: 1.3),
      ),
    );
  }

  Future<void> _openCompactFilterSheet() async {
    var draftStatus = _statusFilter;
    var draftActivity = _activityFilter;
    int? draftCategory = _categoryId;

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
                draftActivity = 'all';
                draftCategory = null;
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
                          'Filtres produits',
                          style: TextStyle(
                            color: procurementInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (draftStatus.isNotEmpty ||
                            draftActivity != 'all' ||
                            draftCategory != null)
                          TextButton(
                            onPressed: resetDraft,
                            child: const Text('Effacer'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>('proc-sheet-status-$draftStatus'),
                      initialValue: draftStatus.isEmpty ? null : draftStatus,
                      decoration: _filterDecoration(
                        'Statut stock',
                        compact: true,
                      ),
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
                        modalSetState(() {
                          draftStatus = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      key: ValueKey<String>(
                        'proc-sheet-category-${draftCategory ?? 'all'}',
                      ),
                      initialValue: draftCategory,
                      decoration: _filterDecoration('Categorie', compact: true),
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
                        modalSetState(() {
                          draftCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(
                        'proc-sheet-activity-$draftActivity',
                      ),
                      initialValue: draftActivity,
                      decoration: _filterDecoration(
                        'Etat catalogue',
                        compact: true,
                      ),
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
                        modalSetState(() {
                          draftActivity = value ?? 'all';
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
                              _activityFilter = draftActivity;
                              _categoryId = draftCategory;
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

  Future<void> _showProductDialog({ProcurementProduct? initial}) async {
    if (_categories.isEmpty) {
      showMessage(
        context,
        'Aucune categorie disponible pour enregistrer un produit.',
        error: true,
      );
      return;
    }
    if (_suppliers.isEmpty) {
      showMessage(
        context,
        'Aucun fournisseur actif disponible pour enregistrer un produit.',
        error: true,
      );
      return;
    }

    ProcurementProduct? productForDialog = initial;
    if (initial != null) {
      try {
        productForDialog = await _service.getProductById(initial.idProduit);
      } catch (error) {
        if (!mounted) return;
        showMessage(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
        return;
      }
    }

    if (!mounted) return;

    final useBottomSheet = MediaQuery.sizeOf(context).width < 600;

    final payload = useBottomSheet
        ? await showModalBottomSheet<ProductUpsertPayload>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => ProductFormDialog(
              categories: _categories,
              suppliers: _suppliers,
              initialProduct: productForDialog,
              isBottomSheet: true,
            ),
          )
        : await showDialog<ProductUpsertPayload>(
            context: context,
            barrierDismissible: false,
            builder: (_) => ProductFormDialog(
              categories: _categories,
              suppliers: _suppliers,
              initialProduct: productForDialog,
            ),
          );

    if (!mounted) return;
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
    final useBottomSheet = MediaQuery.sizeOf(context).width < 600;

    final quantity = useBottomSheet
        ? await showModalBottomSheet<int>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => StockAdjustDialog(
              initialQuantity: product.quantiteStock,
              isBottomSheet: true,
            ),
          )
        : await showDialog<int>(
            context: context,
            builder: (_) =>
                StockAdjustDialog(initialQuantity: product.quantiteStock),
          );

    if (!mounted) return;
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
    final isPhone = AdaptiveLayout.isPhone(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isPhone)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Recherche produit',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: procurementSoftBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: procurementLine),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: procurementLine),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: procurementPrimary,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _openCompactFilterSheet,
                    icon: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: _hasActiveFilters
                          ? procurementPrimary
                          : procurementMuted,
                    ),
                    label: Text(
                      _hasActiveFilters
                          ? 'Filtres ($_activeFilterCount)'
                          : 'Filtres',
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _hasActiveFilters
                          ? procurementPrimary.withValues(alpha: 0.10)
                          : procurementSoftBackground,
                      side: BorderSide(
                        color: _hasActiveFilters
                            ? procurementPrimary.withValues(alpha: 0.28)
                            : procurementLine,
                      ),
                      foregroundColor: _hasActiveFilters
                          ? procurementPrimaryDark
                          : procurementInk,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  FilterChip(
                    selected: _lowStockOnly,
                    visualDensity: VisualDensity.compact,
                    onSelected: (value) {
                      setState(() {
                        _lowStockOnly = value;
                      });
                    },
                    label: const Text('Stock faible'),
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 17,
                      color: _lowStockOnly
                          ? procurementWarning
                          : procurementMuted,
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
                      '${filteredProducts.length} produits',
                      style: const TextStyle(
                        color: procurementMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_hasActiveFilters)
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showProductDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau'),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          SectionSurface(
            title: 'Filtres catalogue',
            subtitle:
                'Recherchez rapidement par nom, categorie, statut ou stock',
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
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un produit',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: procurementSoftBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: procurementLine,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: procurementLine,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey<String>('proc-status-$_statusFilter'),
                        initialValue: _statusFilter.isEmpty
                            ? null
                            : _statusFilter,
                        decoration: _filterDecoration('Statut'),
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
                        key: ValueKey<String>(
                          'proc-category-${_categoryId ?? 'all'}',
                        ),
                        initialValue: _categoryId,
                        decoration: _filterDecoration('Categorie'),
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
                        key: ValueKey<String>('proc-activity-$_activityFilter'),
                        initialValue: _activityFilter,
                        decoration: _filterDecoration('Etat'),
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
                  onPressed: _resetFilters,
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
          _buildProductsTable(
            filteredProducts,
            compact: MediaQuery.sizeOf(context).width < 760,
          ),
      ],
    );
  }

  Widget _buildProductsTable(
    List<ProcurementProduct> products, {
    required bool compact,
  }) {
    return ColoredBox(
      color: procurementSurface,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1120),
            child: DataTable(
              headingRowHeight: compact ? 46 : 50,
              dataRowMinHeight: compact ? 74 : 82,
              dataRowMaxHeight: compact ? 88 : 98,
              horizontalMargin: compact ? 12 : 16,
              columnSpacing: compact ? 16 : 22,
              dividerThickness: 0.8,
              headingRowColor: WidgetStatePropertyAll(
                procurementSoftBackground.withValues(alpha: 0.96),
              ),
              headingTextStyle: TextStyle(
                color: procurementMuted,
                fontSize: compact ? 11.2 : 12.2,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: TextStyle(
                color: procurementInk,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
              columns: const [
                DataColumn(label: Text('PRODUIT')),
                DataColumn(label: Text('CATEGORIE')),
                DataColumn(label: Text('PRIX')),
                DataColumn(label: Text('STOCK')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ETAT')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: products.map((product) {
                final stockColor = productStatusColor(product.status);
                final activityColor = product.active
                    ? procurementAccent
                    : procurementMuted;
                final supplierLabel = _supplierLabelFor(product);
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Row(
                          children: [
                            ProductAvatar(
                              imageUrl: product.imageUrl,
                              product: product,
                              size: 42,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'ID ${product.idProduit} - ${product.unitLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: procurementMuted,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.categorieLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              supplierLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: procurementMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatMoney(product.prixAchat),
                              style: const TextStyle(
                                color: procurementPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Vente ${formatMoney(product.prixVente)}',
                              style: const TextStyle(
                                color: procurementMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productDisplayStock(product),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Seuil ${product.seuilMinimum}',
                              style: const TextStyle(
                                color: procurementMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      StatusPill(
                        label: product.stockStatusLabel,
                        color: stockColor,
                      ),
                    ),
                    DataCell(
                      StatusPill(
                        label: product.active ? 'Actif' : 'Inactif',
                        color: activityColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _showProductDialog(initial: product),
                            tooltip: 'Modifier',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _showStockDialog(product),
                            tooltip: 'Ajuster le stock',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.inventory_2_outlined),
                          ),
                          IconButton(
                            onPressed: () => _toggleProductActivation(product),
                            tooltip: product.active
                                ? 'Desactiver'
                                : 'Reactiver',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              product.active
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
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
}

/// Widget qui affiche le dialogue d'ajustement du stock.
class StockAdjustDialog extends StatefulWidget {
  final int initialQuantity;
  final bool isBottomSheet;

  const StockAdjustDialog({
    super.key,
    required this.initialQuantity,
    this.isBottomSheet = false,
  });

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
    final phone = MediaQuery.sizeOf(context).width < 560;
    final surface = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(phone ? 18 : 20),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          phone ? 18 : 24,
          phone ? 18 : 22,
          phone ? 18 : 24,
          phone ? 18 : 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ajuster le stock',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: procurementInk,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle quantite',
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'La quantite doit etre positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              phone
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            child: const Text('Enregistrer'),
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
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submit,
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          MediaQuery.viewInsetsOf(context).bottom > 0
              ? MediaQuery.viewInsetsOf(context).bottom
              : 12,
        ),
        child: SafeArea(top: false, child: surface),
      );
    }

    return AlertDialog(
      insetPadding: EdgeInsets.all(phone ? 12 : 20),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(width: 420, child: surface),
    );
  }
}
