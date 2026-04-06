import 'package:flutter/material.dart';
import 'package:invera_mobile/config/api_config.dart';
import 'package:invera_mobile/models/procurement_models.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _procurementPrimary = Color(0xFF2553D4);
const Color _procurementInk = Color(0xFF13233D);
const Color _procurementMuted = Color(0xFF607089);
const Color _procurementLine = Color(0xFFE4EBF7);
const Color _procurementMist = Color(0xFFF4F8FF);
const Color _procurementSurface = Colors.white;

const List<BoxShadow> _procurementCardShadow = [
  BoxShadow(color: Color(0x120D1B2A), blurRadius: 28, offset: Offset(0, 14)),
  BoxShadow(color: Color(0x0A0D1B2A), blurRadius: 10, offset: Offset(0, 4)),
];

/// Methode utilitaire pour le repere de section.
String _sectionMarker(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return 'A';
  return trimmed.characters.first.toUpperCase();
}

/// Widget qui affiche le panneau de chargement.
class LoadingPanel extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String message;

  const LoadingPanel({super.key, required this.message});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: _procurementSurface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _procurementLine),
          boxShadow: _procurementCardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _procurementPrimary.withValues(alpha: 0.18),
                    const Color(0xFF14B8A6).withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.8),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Chargement en cours',
              style: TextStyle(
                color: _procurementInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _procurementMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget qui affiche la carte d'erreur asynchrone.
class AsyncErrorCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const AsyncErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      title: title,
      subtitle: 'Une erreur est survenue pendant le chargement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF1F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF5C2C7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la surface de section.
class SectionSurface extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final String subtitle;
  final Widget child;

  const SectionSurface({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final marker = _sectionMarker(title);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _procurementLine),
        boxShadow: _procurementCardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -38,
            right: -26,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _procurementPrimary.withValues(alpha: 0.12),
                    const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -54,
            left: -32,
            child: Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _procurementPrimary.withValues(alpha: 0.16),
                            const Color(0xFF14B8A6).withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        marker,
                        style: const TextStyle(
                          color: _procurementPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: _procurementInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: _procurementMuted,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la carte de statistique d'information.
class InfoStatCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  const InfoStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.16)),
          boxShadow: _procurementCardShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -16,
              right: -18,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: color.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          'LIVE',
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    label,
                    style: const TextStyle(
                      color: _procurementMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _procurementInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.66),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      helper,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8798),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget qui affiche la mini metrique.
class MiniMetric extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final String value;
  final Color color;

  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.10)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF607089), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la carte de repartition des statuts.
class StatusBreakdownCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final int value;
  final Color color;

  const StatusBreakdownCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.10)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2A44),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche le panneau vide.
class EmptyPanel extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final String message;

  const EmptyPanel({super.key, required this.title, required this.message});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _procurementMist,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _procurementLine),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _procurementPrimary.withValues(alpha: 0.14),
                    const Color(0xFF14B8A6).withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome_mosaic_outlined,
                size: 30,
                color: _procurementPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _procurementInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _procurementMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget qui affiche la tuile de stock faible.
class LowStockTile extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementProduct product;

  const LowStockTile({super.key, required this.product});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: productStatusColor(product.status).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: productStatusColor(product.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.quantiteStock} ${product.unitLabel} • seuil ${product.seuilMinimum}',
                  style: const TextStyle(
                    color: Color(0xFF607089),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          StatusPill(
            label: product.stockStatusLabel,
            color: productStatusColor(product.status),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la tuile recapitulative de commande.
class OrderSummaryTile extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementOrder order;

  const OrderSummaryTile({super.key, required this.order});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.referenceCommande,
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.partenaireNom} | ${order.dateCommandeFormatted}',
                  style: const TextStyle(
                    color: Color(0xFF607089),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(
                label: order.statutDisplay,
                color: orderStatusColor(order.statut),
              ),
              const SizedBox(height: 6),
              Text(
                formatMoney(order.total),
                style: const TextStyle(
                  color: Color(0xFF1F2A44),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche le badge de detail.
class DetailBadge extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final String value;
  final Color color;
  final bool dense;

  const DetailBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.dense = false,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 11 : 13,
        vertical: dense ? 9 : 11,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(dense ? 14 : 16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF607089),
              fontSize: dense ? 10.8 : 11.5,
            ),
          ),
          SizedBox(height: dense ? 1 : 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 13 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche la pastille de statut.
class StatusPill extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Widget qui affiche la carte produit.
class ProductCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementProduct product;
  final VoidCallback onEdit;
  final VoidCallback onAdjustStock;
  final VoidCallback onToggleActive;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onAdjustStock,
    required this.onToggleActive,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final activeColor = product.active
        ? const Color(0xFF3F7A51)
        : const Color(0xFF6B7280);
    final stockColor = productStatusColor(product.status);
    final imageUrl = ApiConfig.resolveMediaUrl(product.imageUrl);
    final toggleLabel = product.active ? 'Desactiver' : 'Reactiver';
    final priceRows = <({String label, String value, Color? color})>[
      (
        label: 'Prix achat',
        value: formatMoney(product.prixAchat),
        color: const Color(0xFF1E3A5F),
      ),
      (
        label: 'Prix vente',
        value: formatMoney(product.prixVente),
        color: const Color(0xFF1E3A5F),
      ),
      if (product.categorie != null)
        (label: 'TVA', value: product.categorie!.vatLabel, color: null),
      if (product.remiseTemporaire != null)
        (
          label: 'Remise active',
          value: '${product.remiseTemporaire!.toStringAsFixed(1)}%',
          color: const Color(0xFF8A5A20),
        ),
    ];
    final stockRows = <({String label, String value, Color? color})>[
      (
        label: 'Stock disponible',
        value: '${product.quantiteStock} ${product.unitLabel}',
        color: null,
      ),
      (
        label: 'Seuil minimum',
        value: '${product.seuilMinimum} ${product.unitLabel}',
        color: null,
      ),
      (
        label: 'Etat du stock',
        value: product.stockStatusLabel,
        color: stockColor.withValues(alpha: 0.95),
      ),
      (
        label: 'Catalogue',
        value: product.active ? 'Actif' : 'Inactif',
        color: activeColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final avatarSize = compact ? 92.0 : 110.0;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(compact ? 16 : 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4F8FF), Color(0xFFFFFFFF)],
                  ),
                ),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductAvatar(
                                imageUrl: imageUrl,
                                product: product,
                                size: avatarSize,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _procurementInk,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      product.categorieLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF526071),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Produit #${product.idProduit}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ProductSoftTag(
                                label: product.stockStatusLabel,
                                color: stockColor,
                              ),
                              _ProductSoftTag(
                                label: product.active ? 'Actif' : 'Inactif',
                                color: activeColor,
                              ),
                              _ProductSoftTag(
                                label: product.unitLabel,
                                color: const Color(0xFF506074),
                              ),
                              if (product.remiseTemporaire != null)
                                _ProductSoftTag(
                                  label:
                                      'Remise ${product.remiseTemporaire!.toStringAsFixed(1)}%',
                                  color: const Color(0xFF8A5A20),
                                ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProductAvatar(
                            imageUrl: imageUrl,
                            product: product,
                            size: avatarSize,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _procurementInk,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${product.categorieLabel} | Produit #${product.idProduit}',
                                  style: const TextStyle(
                                    color: Color(0xFF5B6776),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _ProductSoftTag(
                                      label: product.stockStatusLabel,
                                      color: stockColor,
                                    ),
                                    _ProductSoftTag(
                                      label: product.active
                                          ? 'Catalogue actif'
                                          : 'Catalogue inactif',
                                      color: activeColor,
                                    ),
                                    _ProductSoftTag(
                                      label:
                                          '${product.quantiteStock} ${product.unitLabel}',
                                      color: const Color(0xFF506074),
                                    ),
                                    if (product.remiseTemporaire != null)
                                      _ProductSoftTag(
                                        label:
                                            'Remise ${product.remiseTemporaire!.toStringAsFixed(1)}%',
                                        color: const Color(0xFF8A5A20),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  compact ? 16 : 18,
                  compact ? 16 : 20,
                  compact ? 14 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (compact) ...[
                      _ProductSpecPanel(
                        title: 'Tarification',
                        tint: const Color(0xFFF7FAFE),
                        rows: priceRows,
                      ),
                      const SizedBox(height: 12),
                      _ProductSpecPanel(
                        title: 'Inventaire',
                        tint: const Color(0xFFF9FAFB),
                        rows: stockRows,
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ProductSpecPanel(
                              title: 'Tarification',
                              tint: const Color(0xFFF7FAFE),
                              rows: priceRows,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ProductSpecPanel(
                              title: 'Inventaire',
                              tint: const Color(0xFFF9FAFB),
                              rows: stockRows,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProductActionButton(
                            label: 'Ajuster stock',
                            icon: Icons.inventory_2_outlined,
                            onPressed: onAdjustStock,
                          ),
                          _ProductActionButton(
                            label: 'Modifier',
                            icon: Icons.edit_outlined,
                            onPressed: onEdit,
                          ),
                          _ProductActionButton(
                            label: toggleLabel,
                            icon: product.active
                                ? Icons.pause_circle_outline
                                : Icons.play_circle_outline,
                            onPressed: onToggleActive,
                            foregroundColor: activeColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget qui affiche l'etiquette legere du produit.
class _ProductSoftTag extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final Color color;

  const _ProductSoftTag({required this.label, required this.color});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Widget qui affiche le panneau de specifications du produit.
class _ProductSpecPanel extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String title;
  final Color tint;
  final List<({String label, String value, Color? color})> rows;

  const _ProductSpecPanel({
    required this.title,
    required this.tint,
    required this.rows,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            _ProductSpecRow(
              label: rows[i].label,
              value: rows[i].value,
              valueColor: rows[i].color,
            ),
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFFE5E7EB), height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

/// Widget qui affiche la ligne de specifications du produit.
class _ProductSpecRow extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final String value;
  final Color? valueColor;

  const _ProductSpecRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1F2937),
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche le bouton d'action produit.
class _ProductActionButton extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? foregroundColor;

  const _ProductActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.foregroundColor,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: (foregroundColor ?? const Color(0xFF334155)).withValues(
            alpha: 0.14,
          ),
        ),
        backgroundColor: (foregroundColor ?? const Color(0xFF334155))
            .withValues(alpha: 0.04),
        foregroundColor: foregroundColor ?? const Color(0xFF334155),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        iconSize: 16,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Widget qui affiche l'avatar du produit.
class ProductAvatar extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final String? imageUrl;
  final ProcurementProduct product;
  final double size;

  const ProductAvatar({
    super.key,
    required this.imageUrl,
    required this.product,
    this.size = 68,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final radius = size <= 70 ? 18.0 : 20.0;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F1FF), Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        product.displayName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: const Color(0xFF39567A),
          fontWeight: FontWeight.w800,
          fontSize: size <= 70 ? 28 : 32,
        ),
      ),
    );

    if (imageUrl == null) return fallback;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

/// Widget qui affiche la carte de commande.
class OrderCard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementOrder order;
  final bool receptionMode;
  final bool showArchived;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onValidate;
  final VoidCallback? onSend;
  final VoidCallback? onReceive;
  final VoidCallback? onInvoice;
  final VoidCallback? onCancel;

  const OrderCard({
    super.key,
    required this.order,
    required this.receptionMode,
    required this.showArchived,
    required this.onView,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onValidate,
    this.onSend,
    this.onReceive,
    this.onInvoice,
    this.onCancel,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final headerColor = orderStatusColor(order.statut);
    final invoiceButtonLabel = order.statut.toUpperCase() == 'FACTUREE'
        ? 'PDF facture'
        : 'Facturer';
    final invoiceButtonIcon = order.statut.toUpperCase() == 'FACTUREE'
        ? Icons.picture_as_pdf_outlined
        : Icons.receipt_long_outlined;

    return SectionSurface(
      title: order.referenceCommande,
      subtitle: '${order.partenaireNom} | ${order.itemCount} article(s)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DetailBadge(
                label: 'Date commande',
                value: order.dateCommandeFormatted,
                color: const Color(0xFF2D47C8),
              ),
              DetailBadge(
                label: 'Livraison prevue',
                value: order.dateLivraisonPrevueFormatted,
                color: const Color(0xFF0F766E),
              ),
              DetailBadge(
                label: 'Total TTC',
                value: formatMoney(order.total),
                color: const Color(0xFF7C3AED),
              ),
              DetailBadge(
                label: 'TVA',
                value: '${order.tauxTVA.toStringAsFixed(0)}%',
                color: const Color(0xFFEA580C),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StatusPill(label: order.statutDisplay, color: headerColor),
              if (order.dateLivraisonReelle != null)
                StatusPill(
                  label: 'Recue le ${order.dateLivraisonReelleFormatted}',
                  color: const Color(0xFF16A34A),
                ),
              if (showArchived)
                const StatusPill(label: 'Archivee', color: Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.adresseLivraison.trim().isEmpty
                ? 'Aucune adresse de livraison renseignee'
                : order.adresseLivraison,
            style: const TextStyle(color: Color(0xFF607089), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Details'),
              ),
              if (onEdit != null)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
              if (onValidate != null)
                FilledButton.tonalIcon(
                  onPressed: onValidate,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Valider'),
                ),
              if (onSend != null)
                FilledButton.tonalIcon(
                  onPressed: onSend,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Envoyer'),
                ),
              if (onReceive != null)
                FilledButton.icon(
                  onPressed: onReceive,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: Text(receptionMode ? 'Receptionner' : 'Recevoir'),
                ),
              if (onInvoice != null)
                FilledButton.tonalIcon(
                  onPressed: onInvoice,
                  icon: Icon(invoiceButtonIcon),
                  label: Text(invoiceButtonLabel),
                ),
              if (onCancel != null)
                OutlinedButton.icon(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                ),
              if (onDelete != null)
                OutlinedButton.icon(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                ),
              if (onRestore != null)
                FilledButton.tonalIcon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Restaurer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Affiche le dialogue de confirmation.
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

/// Affiche le message.
void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error
          ? const Color(0xFFB91C1C)
          : const Color(0xFF1F7A3E),
    ),
  );
}

/// Formate date pour l'affichage.
String formatDate(DateTime? date, {bool withTime = false}) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  if (!withTime) return '$day/$month/$year';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

/// Formate money pour l'affichage.
String formatMoney(num value) => '${value.toStringAsFixed(3)} DT';

Color productStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'EN_STOCK':
      return const Color(0xFF16A34A);
    case 'FAIBLE':
      return const Color(0xFFCA8A04);
    case 'CRITIQUE':
      return const Color(0xFFEA580C);
    case 'RUPTURE':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF64748B);
  }
}

Color orderStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'BROUILLON':
      return const Color(0xFF64748B);
    case 'VALIDEE':
      return const Color(0xFF2563EB);
    case 'ENVOYEE':
      return const Color(0xFFEA580C);
    case 'RECUE':
      return const Color(0xFF16A34A);
    case 'FACTUREE':
      return const Color(0xFF7C3AED);
    case 'ANNULEE':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF64748B);
  }
}

List<OrderStatusBucket> orderStatusBuckets(List<ProcurementOrder> orders) {
  final data = <OrderStatusBucket>[
    OrderStatusBucket(
      label: 'Brouillon',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'BROUILLON')
          .length,
      color: orderStatusColor('BROUILLON'),
    ),
    OrderStatusBucket(
      label: 'Validee',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'VALIDEE')
          .length,
      color: orderStatusColor('VALIDEE'),
    ),
    OrderStatusBucket(
      label: 'Envoyee',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'ENVOYEE')
          .length,
      color: orderStatusColor('ENVOYEE'),
    ),
    OrderStatusBucket(
      label: 'Recue',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'RECUE')
          .length,
      color: orderStatusColor('RECUE'),
    ),
    OrderStatusBucket(
      label: 'Facturee',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'FACTUREE')
          .length,
      color: orderStatusColor('FACTUREE'),
    ),
    OrderStatusBucket(
      label: 'Annulee',
      count: orders
          .where((order) => order.statut.toUpperCase() == 'ANNULEE')
          .length,
      color: orderStatusColor('ANNULEE'),
    ),
  ];

  return data.where((bucket) => bucket.count > 0).toList();
}

/// Classe utilitaire pour le groupe de statuts de commande.
class OrderStatusBucket {
  // Configuration, dependances et etat local de l'interface.
  final String label;
  final int count;
  final Color color;

  const OrderStatusBucket({
    required this.label,
    required this.count,
    required this.color,
  });
}
