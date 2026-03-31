import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/services/procurement_service.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

class ProcurementOverviewSection extends StatefulWidget {
  const ProcurementOverviewSection({super.key});

  @override
  State<ProcurementOverviewSection> createState() =>
      _ProcurementOverviewSectionState();
}

class _ProcurementOverviewSectionState
    extends State<ProcurementOverviewSection> {
  final ProcurementService _service = ProcurementService();

  bool _loading = true;
  String? _error;
  List<ProcurementProduct> _products = const [];
  List<ProcurementSupplier> _suppliers = const [];
  List<ProcurementOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getProducts(),
        _service.getSuppliers(activeOnly: true),
        _service.getOrders(),
      ]);

      if (!mounted) return;
      setState(() {
        _products = results[0] as List<ProcurementProduct>;
        _suppliers = results[1] as List<ProcurementSupplier>;
        _orders = results[2] as List<ProcurementOrder>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingPanel(message: 'Chargement des statistiques...');
    }

    if (_error != null) {
      return AsyncErrorCard(
        title: 'Impossible de charger le dashboard achat',
        message: _error!,
        onRetry: _loadData,
      );
    }

    final activeProducts = _products.where((product) => product.active).length;
    final inactiveProducts = _products
        .where((product) => !product.active)
        .length;
    final lowStockProducts =
        _products
            .where((product) => product.active && product.isLowStock)
            .toList()
          ..sort((a, b) => a.quantiteStock.compareTo(b.quantiteStock));
    final pendingOrders = _orders.where((order) {
      final status = order.statut.toUpperCase();
      return status == 'BROUILLON' || status == 'VALIDEE';
    }).length;
    final sentOrders = _orders
        .where((order) => order.statut.toUpperCase() == 'ENVOYEE')
        .length;
    final completedSpend = _orders
        .where((order) {
          final status = order.statut.toUpperCase();
          return status == 'RECUE' || status == 'FACTUREE';
        })
        .fold<double>(0, (sum, order) => sum + order.total);
    final recentOrders = [..._orders]
      ..sort((a, b) {
        final left = a.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            InfoStatCard(
              label: 'Produits actifs',
              value: '$activeProducts',
              helper: '$inactiveProducts produit(s) inactif(s)',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF2D47C8),
            ),
            InfoStatCard(
              label: 'Stock faible',
              value: '${lowStockProducts.length}',
              helper: 'Articles a reapprovisionner',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEA580C),
            ),
            InfoStatCard(
              label: 'Fournisseurs actifs',
              value: '${_suppliers.length}',
              helper: 'Disponibles pour vos commandes',
              icon: Icons.apartment_outlined,
              color: const Color(0xFF0F766E),
            ),
            InfoStatCard(
              label: 'Commandes en attente',
              value: '$pendingOrders',
              helper: '$sentOrders envoyee(s) a receptionner',
              icon: Icons.shopping_cart_checkout_outlined,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final left = SectionSurface(
              title: 'Receptions a suivre',
              subtitle: 'Les produits a stock faible et leurs seuils minimum',
              child: lowStockProducts.isEmpty
                  ? const EmptyPanel(
                      title: 'Aucun produit critique',
                      message:
                          'Les niveaux de stock sont au-dessus des seuils minimum.',
                    )
                  : Column(
                      children: [
                        for (final product in lowStockProducts.take(6))
                          LowStockTile(product: product),
                      ],
                    ),
            );
            final right = SectionSurface(
              title: 'Dernieres commandes fournisseurs',
              subtitle: 'Commandes recentes et progression des statuts',
              child: recentOrders.isEmpty
                  ? const EmptyPanel(
                      title: 'Aucune commande',
                      message:
                          'Commencez par creer un bon de commande fournisseur.',
                    )
                  : Column(
                      children: [
                        for (final order in recentOrders.take(6))
                          OrderSummaryTile(order: order),
                      ],
                    ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 16),
                  Expanded(child: right),
                ],
              );
            }

            return Column(children: [left, const SizedBox(height: 16), right]);
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final left = SectionSurface(
              title: 'Depenses fournisseurs',
              subtitle: 'Montants finalises sur les commandes recues',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMoney(completedSpend),
                    style: const TextStyle(
                      color: Color(0xFF1F2A44),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      MiniMetric(
                        label: 'Recues',
                        value:
                            '${_orders.where((o) => o.statut.toUpperCase() == 'RECUE').length}',
                        color: const Color(0xFF16A34A),
                      ),
                      MiniMetric(
                        label: 'Facturees',
                        value:
                            '${_orders.where((o) => o.statut.toUpperCase() == 'FACTUREE').length}',
                        color: const Color(0xFF7C3AED),
                      ),
                      MiniMetric(
                        label: 'Annulees',
                        value:
                            '${_orders.where((o) => o.statut.toUpperCase() == 'ANNULEE').length}',
                        color: const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final right = SectionSurface(
              title: 'Repartition des statuts',
              subtitle: 'Photographie instantanee des commandes achats',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final bucket in orderStatusBuckets(_orders))
                    StatusBreakdownCard(
                      label: bucket.label,
                      value: bucket.count,
                      color: bucket.color,
                    ),
                ],
              ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 16),
                  Expanded(child: right),
                ],
              );
            }

            return Column(children: [left, const SizedBox(height: 16), right]);
          },
        ),
      ],
    );
  }
}
