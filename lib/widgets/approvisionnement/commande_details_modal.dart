import 'package:flutter/material.dart';
import 'package:invera_mobile/models/procurement_models.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/procurement_shared.dart';

class CommandeDetailsModal extends StatelessWidget {
  final ProcurementOrder order;

  const CommandeDetailsModal({
    super.key,
    required this.order,
  });

  bool get _isReceivedLike =>
      order.normalizedStatus == ProcurementOrderStatus.recue ||
      order.normalizedStatus == ProcurementOrderStatus.facturee;

  List<_ComputedOrderLine> get _computedLines {
    return order.lignesCommande.map((line) {
      final quantityUsed = _isReceivedLike ? line.quantiteRecue : line.quantite;
      final sousTotalHt = quantityUsed * line.prixUnitaire;
      final montantTva = sousTotalHt * (line.tauxTVA / 100);
      final sousTotalTtc = sousTotalHt + montantTva;

      return _ComputedOrderLine(
        line: line,
        quantityUsed: quantityUsed,
        sousTotalHt: sousTotalHt,
        montantTva: montantTva,
        sousTotalTtc: sousTotalTtc,
      );
    }).toList();
  }

  Map<double, ({double ht, double tva})> get _vatBreakdown {
    final data = <double, ({double ht, double tva})>{};

    for (final computed in _computedLines) {
      final rate = computed.line.tauxTVA;
      final existing = data[rate];
      data[rate] = (
        ht: (existing?.ht ?? 0) + computed.sousTotalHt,
        tva: (existing?.tva ?? 0) + computed.montantTva,
      );
    }

    final keys = data.keys.toList()..sort();
    return {
      for (final key in keys) key: data[key]!,
    };
  }

  double get _totalHt =>
      _computedLines.fold<double>(0, (sum, item) => sum + item.sousTotalHt);

  double get _totalTva =>
      _computedLines.fold<double>(0, (sum, item) => sum + item.montantTva);

  double get _totalTtc => _totalHt + _totalTva;

  _ReceptionStatus _receptionStatusFor(ProcurementOrderLine line) {
    final quantiteRecue = line.quantiteRecue;
    final quantiteCommandee = line.quantite;

    if (quantiteRecue <= 0) {
      return const _ReceptionStatus(
        label: 'Non recu',
        color: procurementDanger,
      );
    }

    if (quantiteRecue == quantiteCommandee) {
      return const _ReceptionStatus(
        label: 'Recu complet',
        color: procurementAccent,
      );
    }

    return _ReceptionStatus(
      label: 'Partiel ($quantiteRecue/$quantiteCommandee)',
      color: procurementWarning,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 820),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Commande ${order.referenceCommande}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            StatusPill(
                              label: orderStatusLabel(order.statut),
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.partenaireNom,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        DetailBadge(
                          label: 'Date commande',
                          value: formatDate(order.dateCommande, withTime: true),
                          color: procurementPrimary,
                        ),
                        DetailBadge(
                          label: 'Livraison prevue',
                          value: formatDate(order.dateLivraisonPrevue),
                          color: procurementWarning,
                        ),
                        if (order.dateLivraisonReelle != null)
                          DetailBadge(
                            label: 'Livraison reelle',
                            value: formatDate(
                              order.dateLivraisonReelle,
                              withTime: true,
                            ),
                            color: procurementAccent,
                          ),
                        if (order.numeroBL?.trim().isNotEmpty == true)
                          DetailBadge(
                            label: 'Numero BL',
                            value: order.numeroBL!,
                            color: procurementAccent,
                          ),
                        DetailBadge(
                          label: 'Statut',
                          value: orderStatusLabel(order.statut),
                          color: orderStatusColor(order.statut),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionCard(
                      title: 'Informations fournisseur',
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 14,
                        children: [
                          _InfoField(
                            label: 'Nom',
                            value: order.fournisseur?.nomFournisseur ?? 'N/A',
                          ),
                          _InfoField(
                            label: 'Email',
                            value: order.fournisseur?.email ?? 'N/A',
                          ),
                          _InfoField(
                            label: 'Telephone',
                            value: order.fournisseur?.telephone ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Adresse de livraison',
                      child: Text(
                        order.adresseLivraison.trim().isEmpty
                            ? 'Non specifiee'
                            : order.adresseLivraison,
                        style: const TextStyle(
                          color: procurementInk,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (order.motifRejet?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Motif du rejet',
                        child: Text(
                          order.motifRejet!,
                          style: const TextStyle(
                            color: procurementDanger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Detail des articles',
                      child: _computedLines.isEmpty
                          ? const EmptyPanel(
                              title: 'Aucune ligne',
                              message: 'Cette commande ne contient aucun produit.',
                            )
                          : Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: procurementLine),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Produit',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Qté cmd',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Qté recue',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Prix unit.',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'TVA',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Total HT',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Total TTC',
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: procurementMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                for (final computed in _computedLines) ...[
                                  _OrderLineRow(
                                    computed: computed,
                                    showReceptionStatus: _isReceivedLike,
                                    receptionStatus: _receptionStatusFor(
                                      computed.line,
                                    ),
                                  ),
                                  if (computed != _computedLines.last)
                                    const Divider(
                                      color: Color(0xFFE6EAF2),
                                      height: 18,
                                    ),
                                ],
                              ],
                            ),
                    ),
                    if (_vatBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Detail de la TVA',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _vatBreakdown.entries.map((entry) {
                            return DetailBadge(
                              label: 'TVA ${formatVatRate(entry.key)}',
                              value:
                                  '${formatPrice(entry.value.tva)} • Base ${formatPrice(entry.value.ht)}',
                              color: procurementPrimary,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: procurementMist,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: procurementLine),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total HT: ${formatPrice(_totalHt)}',
                              style: const TextStyle(color: procurementMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TVA: ${formatPrice(_totalTva)}',
                              style: const TextStyle(color: procurementMuted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Total TTC: ${formatPrice(_totalTtc)}',
                              style: const TextStyle(
                                color: procurementInk,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
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

class _ComputedOrderLine {
  final ProcurementOrderLine line;
  final int quantityUsed;
  final double sousTotalHt;
  final double montantTva;
  final double sousTotalTtc;

  const _ComputedOrderLine({
    required this.line,
    required this.quantityUsed,
    required this.sousTotalHt,
    required this.montantTva,
    required this.sousTotalTtc,
  });
}

class _ReceptionStatus {
  final String label;
  final Color color;

  const _ReceptionStatus({
    required this.label,
    required this.color,
  });
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: procurementLine),
        boxShadow: procurementCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: procurementInk,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String label;
  final String value;

  const _InfoField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: procurementMuted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? 'N/A' : value,
            style: const TextStyle(
              color: procurementInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineRow extends StatelessWidget {
  final _ComputedOrderLine computed;
  final bool showReceptionStatus;
  final _ReceptionStatus receptionStatus;

  const _OrderLineRow({
    required this.computed,
    required this.showReceptionStatus,
    required this.receptionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final line = computed.line;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.produitLibelle,
                  style: const TextStyle(
                    color: procurementInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                if (line.produitReference.trim().isNotEmpty &&
                    line.produitReference.trim() != '-')
                  Text(
                    'Ref: ${line.produitReference}',
                    style: const TextStyle(
                      color: procurementMuted,
                      fontSize: 12,
                    ),
                  ),
                if (line.categorieNom.trim().isNotEmpty &&
                    line.categorieNom.trim() != '-')
                  Text(
                    line.categorieNom,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                if (showReceptionStatus) ...[
                  const SizedBox(height: 6),
                  StatusPill(
                    label: receptionStatus.label,
                    color: receptionStatus.color,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${line.quantite}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: procurementInk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              showReceptionStatus ? '${line.quantiteRecue}' : '-',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: showReceptionStatus ? procurementInk : procurementMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              formatPrice(line.prixUnitaire),
              textAlign: TextAlign.end,
              style: const TextStyle(color: procurementInk),
            ),
          ),
          Expanded(
            child: Text(
              formatVatRate(line.tauxTVA),
              textAlign: TextAlign.end,
              style: const TextStyle(color: procurementInk),
            ),
          ),
          Expanded(
            child: Text(
              formatPrice(computed.sousTotalHt),
              textAlign: TextAlign.end,
              style: const TextStyle(color: procurementInk),
            ),
          ),
          Expanded(
            child: Text(
              formatPrice(computed.sousTotalTtc),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: procurementPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}