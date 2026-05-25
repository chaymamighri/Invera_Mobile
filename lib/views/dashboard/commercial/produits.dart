import 'package:flutter/material.dart';
import 'package:invera_mobile/config/api.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart'
    show ProductAvatar, formatMoney, productStatusColor;

const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _accent = Color(0xFF0CAE4A);
const Color _warning = Color(0xFFCA8A04);
const Color _danger = Color(0xFFB42318);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _borderLight = Color(0xFFE6EAF2);

/// Widget qui affiche la consultation du catalogue produits cote vente.
class CommercialProductsSection extends StatefulWidget {
  const CommercialProductsSection({super.key});

  @override
  State<CommercialProductsSection> createState() =>
      _CommercialProductsSectionState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface.
class _CommercialProductsSectionState extends State<CommercialProductsSection> {
  final ProcurementService _service = ProcurementService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<ProcurementCategory> _categories = const [];
  List<ProcurementProduct> _products = const [];

  String _statusFilter = '';
  String _activityFilter = 'active';
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

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final products = await _service.getProducts();

      if (!mounted) return;
      setState(() {
        _products = products;
        _categories = _deriveCategories(products);
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

  List<ProcurementCategory> _deriveCategories(
    List<ProcurementProduct> products,
  ) {
    final byId = <int, ProcurementCategory>{};

    for (final product in products) {
      final category = product.categorie;
      if (category == null) continue;
      byId[category.idCategorie] = category;
    }

    final categories = byId.values.toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return categories;
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

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = '';
      _activityFilter = 'active';
      _lowStockOnly = false;
      _categoryId = null;
    });
  }

  Future<void> _showProductDetails(ProcurementProduct product) async {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useBottomSheet = screenWidth < 720;

    if (useBottomSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: _ProductDetailsSheet(product: product),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _ProductDetailsSheet(product: product, dialogMode: true),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = AdaptiveLayout.isPhone(context);
    final horizontalPadding = AdaptiveLayout.horizontalPadding(
      context,
      phone: 12,
      tablet: 14,
      desktop: 16,
    );
    final verticalPadding = isPhone ? 12.0 : 16.0;

    if (_loading) {
      return const Center(child: _LoadingStateCard());
    }

    if (_error != null) {
      return Center(
        child: _ErrorStateCard(message: _error!, onRetry: _loadData),
      );
    }

    final filteredProducts = _filteredProducts;
    final totalProducts = _products.length;
    final activeProducts = _products.where((product) => product.active).length;
    final lowStockProducts = _products
        .where((product) => product.isLowStock)
        .length;

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          verticalPadding,
          horizontalPadding,
          isPhone ? 18 : 24,
        ),
        children: [
          _SalesPanel(
            title: 'Catalogue produits',
            subtitle:
                'Consultez les produits disponibles pour preparer les ventes, verifier les stocks et confirmer les prix.',
            trailing: const _TopLabel(
              label: 'Lecture seule',
              color: _accent,
              icon: Icons.visibility_outlined,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _TopLabel(
                  label: 'Produits du catalogue central',
                  color: _primary,
                  icon: Icons.layers_outlined,
                ),
                _TopLabel(
                  label: 'Consultez sans modifier',
                  color: _textSecondary,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1080
                  ? 3
                  : (constraints.maxWidth >= 560 ? 2 : 1);
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _StatCard(
                      label: 'Produits visibles',
                      value: '$totalProducts',
                      note: '${filteredProducts.length} apres filtrage',
                      color: _primary,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatCard(
                      label: 'Produits actifs',
                      value: '$activeProducts',
                      note: 'prets pour la vente',
                      color: _accent,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _StatCard(
                      label: 'Stock sensible',
                      value: '$lowStockProducts',
                      note: 'surveillez les disponibilites',
                      color: _warning,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _SalesPanel(
            title: 'Filtres catalogue',
            subtitle:
                'Gardez une interface compacte sur mobile et affinez rapidement la consultation.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isPhoneWidth = width < 560;
                    final double fieldWidth;

                    if (isPhoneWidth) {
                      fieldWidth = width;
                    } else if (width < 900) {
                      fieldWidth = (width - 12) / 2;
                    } else {
                      fieldWidth = (width - 36) / 4;
                    }

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: isPhoneWidth ? width : width,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Recherche',
                              hintText: 'Nom, categorie ou unite',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: _background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: _borderLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey<String>('status-$_statusFilter'),
                            initialValue: _statusFilter.isEmpty
                                ? null
                                : _statusFilter,
                            decoration: _inputDecoration('Statut stock'),
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
                          width: fieldWidth,
                          child: DropdownButtonFormField<int?>(
                            key: ValueKey<String>(
                              'category-${_categoryId ?? 'all'}',
                            ),
                            initialValue: _categoryId,
                            decoration: _inputDecoration('Categorie'),
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
                          width: fieldWidth,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey<String>('activity-$_activityFilter'),
                            initialValue: _activityFilter,
                            decoration: _inputDecoration('Etat catalogue'),
                            items: const [
                              DropdownMenuItem<String>(
                                value: 'active',
                                child: Text('Actifs'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'all',
                                child: Text('Tous'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'inactive',
                                child: Text('Inactifs'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _activityFilter = value ?? 'active';
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      selected: _lowStockOnly,
                      onSelected: (value) {
                        setState(() {
                          _lowStockOnly = value;
                        });
                      },
                      label: const Text('Stock faible uniquement'),
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: _lowStockOnly ? _warning : _textSecondary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Reinitialiser'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _loadData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filteredProducts.isEmpty)
            const _EmptyProductsState()
          else
            Column(
              children: [
                for (final product in filteredProducts) ...[
                  _ProductCatalogCard(
                    product: product,
                    onViewDetails: () => _showProductDetails(product),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

/// Widget qui affiche un panneau harmonise avec le dashboard commercial.
class _SalesPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _SalesPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withValues(alpha: 0.14),
                        _accent.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: trailing!),
            ],
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withValues(alpha: 0.14),
                        _accent.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          SizedBox(height: compact ? 14 : 16),
          child,
        ],
      ),
    );
  }
}

/// Widget qui affiche une statistique du catalogue.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 21 : 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              color: _textSecondary,
              fontSize: compact ? 12 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche un libelle decoratif.
class _TopLabel extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TopLabel({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 430;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche une carte produit en lecture seule.
class _ProductCatalogCard extends StatelessWidget {
  final ProcurementProduct product;
  final VoidCallback onViewDetails;

  const _ProductCatalogCard({
    required this.product,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final stockColor = productStatusColor(product.status);
    final activityColor = product.active ? _accent : _textSecondary;
    final imageUrl = ApiConfig.resolveMediaUrl(product.imageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final ultraCompact = constraints.maxWidth < 380;
          final metricColumns = ultraCompact
              ? 1
              : (constraints.maxWidth < 520 ? 2 : 4);
          final metricSpacing = 10.0;
          final metricWidth =
              (constraints.maxWidth - metricSpacing * (metricColumns - 1)) /
              metricColumns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductAvatar(
                    imageUrl: imageUrl,
                    product: product,
                    size: ultraCompact ? 54 : (compact ? 62 : 72),
                  ),
                  SizedBox(width: ultraCompact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: ultraCompact ? 15.5 : 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.categorieLabel,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: ultraCompact ? 12 : 13,
                          ),
                        ),
                        SizedBox(height: ultraCompact ? 8 : 10),
                        Wrap(
                          spacing: ultraCompact ? 6 : 8,
                          runSpacing: ultraCompact ? 6 : 8,
                          children: [
                            _TopLabel(
                              label: product.stockStatusLabel,
                              color: stockColor,
                              icon: Icons.local_shipping_outlined,
                            ),
                            _TopLabel(
                              label: product.active ? 'Actif' : 'Inactif',
                              color: activityColor,
                              icon: product.active
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.pause_circle_outline_rounded,
                            ),
                            if (product.remiseTemporaire != null)
                              _TopLabel(
                                label:
                                    'Remise ${product.remiseTemporaire!.toStringAsFixed(1)}%',
                                color: _warning,
                                icon: Icons.percent_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 12),
                    FilledButton.tonalIcon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Details'),
                    ),
                  ],
                ],
              ),
              SizedBox(height: ultraCompact ? 12 : 14),
              Wrap(
                spacing: metricSpacing,
                runSpacing: metricSpacing,
                children: [
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Prix vente',
                      value: formatMoney(product.prixVente),
                      color: _primary,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Stock',
                      value: '${product.quantiteStock}',
                      color: stockColor,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Unite',
                      value: product.unitLabel,
                      color: _primaryDark,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: _MetricTile(
                      label: 'Seuil min.',
                      value: '${product.seuilMinimum}',
                      color: _accent,
                    ),
                  ),
                ],
              ),
              if (compact) ...[
                const SizedBox(height: 12),
                if (ultraCompact)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Voir details'),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onViewDetails,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Voir details'),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Widget qui affiche une tuile metrique.
class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la fiche detaillee d'un produit.
class _ProductDetailsSheet extends StatelessWidget {
  final ProcurementProduct product;
  final bool dialogMode;

  const _ProductDetailsSheet({required this.product, this.dialogMode = false});

  @override
  Widget build(BuildContext context) {
    final stockColor = productStatusColor(product.status);
    final imageUrl = ApiConfig.resolveMediaUrl(product.imageUrl);
    final category = product.categorie;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 430;
    final details = <({String label, String value, Color color})>[
      (
        label: 'Prix vente',
        value: formatMoney(product.prixVente),
        color: _primary,
      ),
      (
        label: 'Prix achat',
        value: formatMoney(product.prixAchat),
        color: _primaryDark,
      ),
      (
        label: 'Stock disponible',
        value: '${product.quantiteStock} ${product.unitLabel}',
        color: stockColor,
      ),
      (
        label: 'Seuil minimum',
        value: '${product.seuilMinimum} ${product.unitLabel}',
        color: _accent,
      ),
      (
        label: 'Etat du stock',
        value: product.stockStatusLabel,
        color: stockColor,
      ),
      (
        label: 'Catalogue',
        value: product.active ? 'Actif' : 'Inactif',
        color: product.active ? _accent : _textSecondary,
      ),
      (label: 'Categorie', value: product.categorieLabel, color: _primaryDark),
      (label: 'TVA', value: category?.vatLabel ?? '0%', color: _warning),
      if (product.remiseTemporaire != null)
        (
          label: 'Remise active',
          value: '${product.remiseTemporaire!.toStringAsFixed(1)}%',
          color: _warning,
        ),
    ];

    final radius = dialogMode
        ? BorderRadius.circular(24)
        : const BorderRadius.vertical(top: Radius.circular(28));

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: radius,
        border: Border.all(color: _borderLight),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 18,
            compact ? 14 : 18,
            compact ? 14 : 18,
            compact ? 18 : 22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (compact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductAvatar(
                      imageUrl: imageUrl,
                      product: product,
                      size: 68,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.displayName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.categorieLabel,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TopLabel(
                          label: product.stockStatusLabel,
                          color: stockColor,
                          icon: Icons.inventory_outlined,
                        ),
                        _TopLabel(
                          label: product.active ? 'Actif' : 'Inactif',
                          color: product.active ? _accent : _textSecondary,
                          icon: Icons.sell_outlined,
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductAvatar(
                      imageUrl: imageUrl,
                      product: product,
                      size: 78,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.displayName,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.categorieLabel,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TopLabel(
                                label: product.stockStatusLabel,
                                color: stockColor,
                                icon: Icons.inventory_outlined,
                              ),
                              _TopLabel(
                                label: product.active ? 'Actif' : 'Inactif',
                                color: product.active
                                    ? _accent
                                    : _textSecondary,
                                icon: Icons.sell_outlined,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              SizedBox(height: compact ? 14 : 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 520 ? 2 : 1;
                  final spacing = 10.0;
                  final itemWidth =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final detail in details)
                        SizedBox(
                          width: itemWidth,
                          child: _MetricTile(
                            label: detail.label,
                            value: detail.value,
                            color: detail.color,
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (category != null &&
                  category.description.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description categorie',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.description,
                        style: const TextStyle(
                          color: _textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: compact ? 14 : 18),
              SizedBox(
                width: compact ? double.infinity : null,
                child: Align(
                  alignment: compact ? Alignment.center : Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget qui affiche un etat vide.
class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _primary,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucun produit a afficher',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Essayez de modifier les filtres ou actualisez le catalogue pour recuperer les produits les plus recents.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche un chargement centre.
class _LoadingStateCard extends StatelessWidget {
  const _LoadingStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Chargement du catalogue',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nous recuperons les produits pour la consultation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche un etat d'erreur.
class _ErrorStateCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorStateCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _danger),
          ),
          const SizedBox(height: 14),
          const Text(
            'Impossible de charger les produits',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: _textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}
