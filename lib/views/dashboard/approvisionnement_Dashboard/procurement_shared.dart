import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/widgets/approvisionnement/procurement_user_role.dart';

const Color procurementPrimary = Color(0xFF2563EB);
const Color procurementPrimaryDark = Color(0xFF1D4ED8);
const Color procurementAccent = Color(0xFF16A34A);
const Color procurementWarning = Color(0xFFEA580C);
const Color procurementDanger = Color(0xFFDC2626);
const Color procurementPurple = Color(0xFF7C3AED);
const Color procurementInk = Color(0xFF13233D);
const Color procurementMuted = Color(0xFF607089);
const Color procurementLine = Color(0xFFE4EBF7);
const Color procurementMist = Color(0xFFF4F8FF);
const Color procurementSurface = Colors.white;
const Color procurementSoftBackground = Color(0xFFF8FAFC);

const List<BoxShadow> procurementCardShadow = [
  BoxShadow(color: Color(0x120D1B2A), blurRadius: 28, offset: Offset(0, 14)),
  BoxShadow(color: Color(0x0A0D1B2A), blurRadius: 10, offset: Offset(0, 4)),
];

abstract final class ProcurementOrderStatus {
  static const String brouillon = 'BROUILLON';
  static const String validee = 'VALIDEE';
  static const String envoyee = 'ENVOYEE';
  static const String recue = 'RECUE';
  static const String facturee = 'FACTUREE';
  static const String annulee = 'ANNULEE';
  static const String rejetee = 'REJETEE';

  static const List<String> all = <String>[
    brouillon,
    validee,
    envoyee,
    recue,
    facturee,
    annulee,
    rejetee,
  ];
}

String formatDate(DateTime? date, {bool withTime = false}) {
  if (date == null) return 'N/A';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  if (!withTime) return '$day/$month/$year';
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}

String formatPrice(num? value) {
  if (value == null) return 'N/A';
  return '${value.toStringAsFixed(3)} TND';
}

String formatMoney(double value) {
  return '${value.toStringAsFixed(3)} TND';
}

String formatVatRate(num? rate) {
  final safeRate = (rate ?? 19).toDouble();
  if (safeRate == safeRate.roundToDouble()) {
    return '${safeRate.toStringAsFixed(0)}%';
  }
  return '${safeRate.toStringAsFixed(2)}%';
}

Color orderStatusColor(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case ProcurementOrderStatus.brouillon:
      return const Color(0xFF64748B);
    case ProcurementOrderStatus.validee:
      return const Color(0xFF2563EB);
    case ProcurementOrderStatus.envoyee:
      return const Color(0xFFCA8A04);
    case ProcurementOrderStatus.recue:
      return const Color(0xFF16A34A);
    case ProcurementOrderStatus.facturee:
      return const Color(0xFF7C3AED);
    case ProcurementOrderStatus.annulee:
      return const Color(0xFFDC2626);
    case ProcurementOrderStatus.rejetee:
      return const Color(0xFFEA580C);
    default:
      return const Color(0xFF64748B);
  }
}

Color productStatusColor(String? status) {
  switch ((status ?? '').toUpperCase()) {
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

String orderStatusLabel(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case ProcurementOrderStatus.brouillon:
      return 'BROUILLON';
    case ProcurementOrderStatus.validee:
      return 'VALIDEE';
    case ProcurementOrderStatus.envoyee:
      return 'ENVOYEE';
    case ProcurementOrderStatus.recue:
      return 'RECUE';
    case ProcurementOrderStatus.facturee:
      return 'FACTUREE';
    case ProcurementOrderStatus.annulee:
      return 'ANNULEE';
    case ProcurementOrderStatus.rejetee:
      return 'REJETEE';
    default:
      return status?.toUpperCase() ?? 'INCONNU';
  }
}

String productDisplayStock(ProcurementProduct product) {
  return '${product.quantiteStock} ${product.unitLabel}';
}

String supplierOptionLabel(ProcurementSupplier supplier) {
  final phone = supplier.telephone.trim();
  final email = supplier.email.trim();
  if (phone.isNotEmpty) return '${supplier.displayName} - $phone';
  if (email.isNotEmpty) return '${supplier.displayName} - $email';
  return supplier.displayName;
}

class ProcurementOrderActionPolicy {
  static bool canDelete(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return (role == ProcurementUserRole.responsableAchat &&
            order.normalizedStatus == ProcurementOrderStatus.brouillon) ||
        (role == ProcurementUserRole.responsableAchat &&
            order.normalizedStatus == ProcurementOrderStatus.rejetee);
  }

  static bool canEdit(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.responsableAchat &&
        order.normalizedStatus == ProcurementOrderStatus.rejetee;
  }

  static bool canValidate(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.admin &&
        order.normalizedStatus == ProcurementOrderStatus.brouillon;
  }

  static bool canReject(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.admin &&
        order.normalizedStatus == ProcurementOrderStatus.brouillon;
  }

  static bool canResendAfterRejection(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.responsableAchat &&
        order.normalizedStatus == ProcurementOrderStatus.rejetee;
  }

  static bool canSend(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.responsableAchat &&
        order.normalizedStatus == ProcurementOrderStatus.validee;
  }

  static bool canReceive(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.responsableAchat &&
        order.normalizedStatus == ProcurementOrderStatus.envoyee;
  }

  static bool canInvoice(
    ProcurementOrder order,
    ProcurementUserRole role, {
    required bool showArchives,
  }) {
    if (showArchives) return false;
    return role == ProcurementUserRole.responsableAchat &&
        (order.normalizedStatus == ProcurementOrderStatus.recue ||
            order.normalizedStatus == ProcurementOrderStatus.facturee);
  }

  static bool canRestore({
    required bool showArchives,
  }) {
    return showArchives;
  }
}

class LoadingPanel extends StatelessWidget {
  final String message;

  const LoadingPanel({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          color: procurementSurface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: procurementLine),
          boxShadow: procurementCardShadow,
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
                    procurementPrimary.withValues(alpha: 0.18),
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
                color: procurementInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: procurementMuted),
            ),
          ],
        ),
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

  String _sectionMarker(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) return 'A';
    return trimmed.characters.first.toUpperCase();
  }

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
        border: Border.all(color: procurementLine),
        boxShadow: procurementCardShadow,
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
                    procurementPrimary.withValues(alpha: 0.12),
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
                            procurementPrimary.withValues(alpha: 0.16),
                            const Color(0xFF14B8A6).withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        marker,
                        style: const TextStyle(
                          color: procurementPrimary,
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
                              color: procurementInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: procurementMuted,
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

class EmptyPanel extends StatelessWidget {
  final String title;
  final String message;

  const EmptyPanel({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: procurementMist,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: procurementLine),
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
                    procurementPrimary.withValues(alpha: 0.14),
                    const Color(0xFF14B8A6).withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 30,
                color: procurementPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: procurementInk,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: procurementMuted,
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

class DetailBadge extends StatelessWidget {
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
              color: procurementMuted,
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

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color == Colors.white ? procurementInk : color;
    final bgColor = color == Colors.white
        ? Colors.white
        : color.withValues(alpha: 0.10);
    final borderColor = color == Colors.white
        ? Colors.white
        : color.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ProcurementStatusBadge extends StatelessWidget {
  final String status;

  const ProcurementStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: orderStatusLabel(status),
      color: orderStatusColor(status),
    );
  }
}

class ProcurementRoleSwitchCard extends StatelessWidget {
  final ProcurementUserRole currentRole;
  final ValueChanged<ProcurementUserRole> onChanged;

  const ProcurementRoleSwitchCard({
    super.key,
    required this.currentRole,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      title: 'Vue utilisateur',
      subtitle: 'Simulation temporaire du role comme sur le web',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ChoiceChip(
            label: const Text('Responsable achat'),
            selected: currentRole == ProcurementUserRole.responsableAchat,
            onSelected: (_) =>
                onChanged(ProcurementUserRole.responsableAchat),
          ),
          ChoiceChip(
            label: const Text('Admin'),
            selected: currentRole == ProcurementUserRole.admin,
            onSelected: (_) => onChanged(ProcurementUserRole.admin),
          ),
        ],
      ),
    );
  }
}

class ProductAvatar extends StatelessWidget {
  final String? imageUrl;
  final dynamic product;
  final double size;

  const ProductAvatar({
    super.key,
    required this.imageUrl,
    required this.product,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF1F5F9),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    return const Center(
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey),
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
    final stockColor = productStatusColor(product.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: procurementCardShadow,
      ),
      child: Row(
        children: [
          ProductAvatar(
            imageUrl: product.imageUrl,
            product: product,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: procurementInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.categorieLabel,
                  style: const TextStyle(color: procurementMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: product.stockStatusLabel,
                      color: stockColor,
                    ),
                    StatusPill(
                      label: product.active ? 'Actif' : 'Inactif',
                      color: product.active
                          ? procurementAccent
                          : procurementMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  formatMoney(product.prixVente),
                  style: const TextStyle(
                    color: procurementPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: onAdjustStock,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            onPressed: onToggleActive,
            icon: Icon(
              product.active ? Icons.visibility : Icons.visibility_off,
            ),
          ),
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
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: procurementSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: procurementLine),
        boxShadow: procurementCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: procurementInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(color: procurementMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class LowStockTile extends StatelessWidget {
  final ProcurementProduct product;

  const LowStockTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final color = productStatusColor(product.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: procurementMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: procurementLine),
      ),
      child: Row(
        children: [
          ProductAvatar(
            imageUrl: product.imageUrl,
            product: product,
            size: 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(
                    color: procurementInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.categorieLabel,
                  style: const TextStyle(
                    color: procurementMuted,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(
                      label: product.stockStatusLabel,
                      color: color,
                    ),
                    StatusPill(
                      label:
                          'Stock ${product.quantiteStock}/${product.seuilMinimum}',
                      color: procurementWarning,
                    ),
                  ],
                ),
              ],
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: procurementMist,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: procurementLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: orderStatusColor(order.statut).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: orderStatusColor(order.statut),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.referenceCommande,
                  style: const TextStyle(
                    color: procurementInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  order.partenaireNom,
                  style: const TextStyle(
                    color: procurementMuted,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ProcurementStatusBadge(status: order.statut),
                    StatusPill(
                      label: formatDate(order.dateCommande),
                      color: procurementPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatMoney(order.totalTTC),
            style: const TextStyle(
              color: procurementPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: procurementMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBucket {
  final String label;
  final int count;
  final Color color;

  const StatusBucket({
    required this.label,
    required this.count,
    required this.color,
  });
}

List<StatusBucket> orderStatusBuckets(List<ProcurementOrder> orders) {
  final counts = <String, int>{
    for (final status in ProcurementOrderStatus.all) status: 0,
  };

  for (final order in orders) {
    final normalized = order.normalizedStatus;
    counts[normalized] = (counts[normalized] ?? 0) + 1;
  }

  return ProcurementOrderStatus.all
      .map(
        (status) => StatusBucket(
          label: orderStatusLabel(status),
          count: counts[status] ?? 0,
          color: orderStatusColor(status),
        ),
      )
      .toList();
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
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: procurementMuted, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
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