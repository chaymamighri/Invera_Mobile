import 'package:flutter/material.dart';
import 'package:invera_mobile/config/api_config.dart';
import 'package:invera_mobile/models/procurement_models.dart';

class LoadingPanel extends StatelessWidget {
  final String message;

  const LoadingPanel({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF607089))),
        ],
      ),
    );
  }
}

class AsyncErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const AsyncErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      title: title,
      subtitle: 'Une erreur est survenue pendant le chargement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontWeight: FontWeight.w600,
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

class SectionSurface extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const SectionSurface({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2A44),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF607089), fontSize: 13),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class InfoStatCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EAF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF607089),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2A44),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    helper,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
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

class MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
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

class StatusBreakdownCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const StatusBreakdownCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
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

class EmptyPanel extends StatelessWidget {
  final String title;
  final String message;

  const EmptyPanel({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1F2A44),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF607089), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class LowStockTile extends StatelessWidget {
  final ProcurementProduct product;

  const LowStockTile({super.key, required this.product});

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

class OrderSummaryTile extends StatelessWidget {
  final ProcurementOrder order;

  const OrderSummaryTile({super.key, required this.order});

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
                  order.displayNumber,
                  style: const TextStyle(
                    color: Color(0xFF1F2A44),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.fournisseur?.displayName ?? 'Fournisseur'} • ${formatDate(order.dateCommande, withTime: true)}',
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
                label: order.statusLabel,
                color: orderStatusColor(order.statut),
              ),
              const SizedBox(height: 6),
              Text(
                formatMoney(order.totalTTC),
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

class DetailBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const DetailBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF607089), fontSize: 11.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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

class ProductCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final activeColor = product.active
        ? const Color(0xFF16A34A)
        : const Color(0xFF64748B);
    final imageUrl = product.imageUrl.trim().isNotEmpty
        ? '${ApiConfig.baseUrl}${product.imageUrl}'
        : null;

    return SectionSurface(
      title: product.displayName,
      subtitle: product.categorieLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 860;
              final info = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  DetailBadge(
                    label: 'Prix achat',
                    value: formatMoney(product.prixAchat),
                    color: const Color(0xFF2D47C8),
                  ),
                  DetailBadge(
                    label: 'Prix vente',
                    value: formatMoney(product.prixVente),
                    color: const Color(0xFF0F766E),
                  ),
                  DetailBadge(
                    label: 'Stock',
                    value: '${product.quantiteStock} ${product.unitLabel}',
                    color: productStatusColor(product.status),
                  ),
                  DetailBadge(
                    label: 'Etat',
                    value: product.active ? 'Actif' : 'Inactif',
                    color: activeColor,
                  ),
                  DetailBadge(
                    label: 'Seuil',
                    value: '${product.seuilMinimum}',
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              );

              final actions = Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: onAdjustStock,
                    icon: const Icon(Icons.inventory),
                    label: const Text('Ajuster stock'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onToggleActive,
                    icon: Icon(
                      product.active
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(product.active ? 'Desactiver' : 'Reactiver'),
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductAvatar(imageUrl: imageUrl, product: product),
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        StatusPill(
                          label: product.stockStatusLabel,
                          color: productStatusColor(product.status),
                        ),
                        if (product.remiseTemporaire != null)
                          StatusPill(
                            label:
                                'Remise ${product.remiseTemporaire!.toStringAsFixed(1)}%',
                            color: const Color(0xFF7C3AED),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    actions,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductAvatar(imageUrl: imageUrl, product: product),
                      const SizedBox(width: 14),
                      Expanded(child: info),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          StatusPill(
                            label: product.stockStatusLabel,
                            color: productStatusColor(product.status),
                          ),
                          const SizedBox(height: 10),
                          if (product.remiseTemporaire != null)
                            StatusPill(
                              label:
                                  'Remise ${product.remiseTemporaire!.toStringAsFixed(1)}%',
                              color: const Color(0xFF7C3AED),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProductAvatar extends StatelessWidget {
  final String? imageUrl;
  final ProcurementProduct product;

  const ProductAvatar({
    super.key,
    required this.imageUrl,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        product.displayName.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF2D47C8),
          fontWeight: FontWeight.w800,
          fontSize: 28,
        ),
      ),
    );

    if (imageUrl == null) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        imageUrl!,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final headerColor = orderStatusColor(order.statut);

    return SectionSurface(
      title: order.displayNumber,
      subtitle:
          '${order.fournisseur?.displayName ?? 'Fournisseur'} • ${order.itemCount} article(s)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DetailBadge(
                label: 'Date commande',
                value: formatDate(order.dateCommande, withTime: true),
                color: const Color(0xFF2D47C8),
              ),
              DetailBadge(
                label: 'Livraison prevue',
                value: formatDate(order.dateLivraisonPrevue),
                color: const Color(0xFF0F766E),
              ),
              DetailBadge(
                label: 'Total TTC',
                value: formatMoney(order.totalTTC),
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
              StatusPill(label: order.statusLabel, color: headerColor),
              if (order.dateLivraisonReelle != null)
                StatusPill(
                  label:
                      'Recue le ${formatDate(order.dateLivraisonReelle, withTime: true)}',
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
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Facturer'),
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

class OrderStatusBucket {
  final String label;
  final int count;
  final Color color;

  const OrderStatusBucket({
    required this.label,
    required this.count,
    required this.color,
  });
}
