import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/services/procurement_service.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

/// Widget qui affiche la section de vue d'ensemble de l'approvisionnement.
class ProcurementOverviewSection extends StatefulWidget {
  const ProcurementOverviewSection({super.key});

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ProcurementOverviewSection> createState() =>
      _ProcurementOverviewSectionState();
}

/// Classe utilitaire pour l'etat de la section de vue d'ensemble de l'approvisionnement.
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

  Widget _buildHeroMetric({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 12),
          ],
          Text(
            label,
            style: const TextStyle(color: Color(0xD7E2E8F0), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHero({
    required int activeProducts,
    required int suppliersCount,
    required int lowStockCount,
    required int sentOrders,
    required double completedSpend,
    required int stockHealth,
  }) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C1934), Color(0xFF163985), Color(0xFF177A99)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;

          final narrative = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Orchestration achat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Un cockpit achats plus lisible, plus premium et vraiment operationnel.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Suivez les tensions de stock, le rythme des commandes fournisseurs et la valeur deja engagee, dans une interface plus affirmée et plus professionnelle.',
                style: TextStyle(
                  color: Color(0xD7F8FAFC),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHeroMetric(
                    label: 'Depenses finalisees',
                    value: formatMoney(completedSpend),
                    color: const Color(0xFFF8FAFC),
                    icon: Icons.payments_outlined,
                  ),
                  _buildHeroMetric(
                    label: 'Santé du stock',
                    value: '$stockHealth%',
                    color: const Color(0xFFCCFBF1),
                    icon: Icons.radar_outlined,
                  ),
                ],
              ),
            ],
          );

          final spotlight = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildHeroMetric(
                    label: 'Produits actifs',
                    value: '$activeProducts',
                    color: const Color(0xFFDBEAFE),
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildHeroMetric(
                    label: 'Fournisseurs',
                    value: '$suppliersCount',
                    color: const Color(0xFFCCFBF1),
                    icon: Icons.apartment_outlined,
                  ),
                  _buildHeroMetric(
                    label: 'Stock faible',
                    value: '$lowStockCount',
                    color: const Color(0xFFFEF3C7),
                    icon: Icons.warning_amber_rounded,
                  ),
                  _buildHeroMetric(
                    label: 'En reception',
                    value: '$sentOrders',
                    color: const Color(0xFFE9D5FF),
                    icon: Icons.local_shipping_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lecture rapide',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: stockHealth / 100,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7DD3FC),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lowStockCount == 0
                          ? 'Aucune alerte critique: le stock est sous controle.'
                          : '$lowStockCount article(s) demandent une attention prioritaire.',
                      style: const TextStyle(
                        color: Color(0xD7F8FAFC),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [narrative, const SizedBox(height: 20), spotlight],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: narrative),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: spotlight),
            ],
          );
        },
      ),
    );
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
    final stockHealth = activeProducts == 0
        ? 100
        : (((activeProducts - lowStockProducts.length).clamp(
                        0,
                        activeProducts,
                      ) /
                      activeProducts) *
                  100)
              .round();
    final recentOrders = [..._orders]
      ..sort((a, b) {
        final left = a.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.dateCommande ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverviewHero(
          activeProducts: activeProducts,
          suppliersCount: _suppliers.length,
          lowStockCount: lowStockProducts.length,
          sentOrders: sentOrders,
          completedSpend: completedSpend,
          stockHealth: stockHealth,
        ),
        const SizedBox(height: 20),
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
