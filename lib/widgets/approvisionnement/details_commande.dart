import 'package:flutter/material.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';

class CommandeDetailsModal extends StatelessWidget {
  final ProcurementOrder order;
  final bool isBottomSheet;

  const CommandeDetailsModal({
    super.key,
    required this.order,
    this.isBottomSheet = false,
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
    return {for (final key in keys) key: data[key]!};
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

  Widget _buildHeader(BuildContext context, bool phone) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        phone ? 16 : 22,
        phone ? 16 : 20,
        phone ? 8 : 12,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: phone ? 44 : 50,
            height: phone ? 44 : 50,
            decoration: BoxDecoration(
              color: procurementPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: procurementPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.referenceCommande,
                  style: TextStyle(
                    fontSize: phone ? 18 : 22,
                    fontWeight: FontWeight.w800,
                    color: procurementInk,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ProcurementStatusBadge(status: order.statut),
                    Text(
                      order.partenaireNom,
                      style: const TextStyle(
                        color: procurementMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, color: procurementMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaStrip(bool phone) {
    final chips = <Widget>[
      _MetaPill(
        label: 'Date commande',
        value: formatDate(order.dateCommande, withTime: true),
      ),
      _MetaPill(
        label: 'Livraison prevue',
        value: formatDate(order.dateLivraisonPrevue),
      ),
      if (order.dateLivraisonReelle != null)
        _MetaPill(
          label: 'Livraison reelle',
          value: formatDate(order.dateLivraisonReelle, withTime: true),
          tint: procurementAccent.withValues(alpha: 0.10),
        ),
      if (order.numeroBL?.trim().isNotEmpty == true)
        _MetaPill(
          label: 'Numero BL',
          value: order.numeroBL!,
          tint: procurementSoftBackground,
        ),
    ];

    if (phone) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              chips[i],
              if (i != chips.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }

    return Wrap(spacing: 10, runSpacing: 10, children: chips);
  }

  Widget _buildInfoSection(bool phone) {
    return _SectionCard(
      title: 'Fournisseur',
      child: Column(
        children: [
          _InfoRow(
            label: 'Nom',
            value: order.fournisseur?.nomFournisseur ?? 'N/A',
          ),
          _InfoRow(label: 'Email', value: order.fournisseur?.email ?? 'N/A'),
          _InfoRow(
            label: 'Telephone',
            value: order.fournisseur?.telephone ?? 'N/A',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(bool phone) {
    return _SectionCard(
      title: 'Livraison',
      child: Column(
        children: [
          _InfoRow(
            label: 'Adresse',
            value: order.adresseLivraison.trim().isEmpty
                ? 'Non specifiee'
                : order.adresseLivraison,
          ),
          _InfoRow(
            label: 'Date prevue',
            value: formatDate(order.dateLivraisonPrevue),
          ),
          if (order.dateLivraisonReelle != null)
            _InfoRow(
              label: 'Date reelle',
              value: formatDate(order.dateLivraisonReelle, withTime: true),
            ),
          _InfoRow(
            label: 'Statut',
            value: orderStatusLabel(order.statut),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRejectAlert() {
    if (order.motifRejet?.trim().isEmpty != false) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motif du rejet',
            style: TextStyle(
              color: procurementDanger,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.motifRejet!,
            style: const TextStyle(
              color: procurementDanger,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLineCard(_ComputedOrderLine computed) {
    final line = computed.line;
    final receptionStatus = _receptionStatusFor(line);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: procurementSoftBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: procurementLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.produitLibelle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: procurementInk,
                      ),
                    ),
                    if (line.produitReference.trim().isNotEmpty &&
                        line.produitReference.trim() != '-') ...[
                      const SizedBox(height: 3),
                      Text(
                        'Ref: ${line.produitReference}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: procurementMuted,
                        ),
                      ),
                    ],
                    if (line.categorieNom.trim().isNotEmpty &&
                        line.categorieNom.trim() != '-') ...[
                      const SizedBox(height: 2),
                      Text(
                        line.categorieNom,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isReceivedLike) ...[
                const SizedBox(width: 10),
                StatusPill(
                  label: receptionStatus.label,
                  color: receptionStatus.color,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(label: 'Qte cmd', value: '${line.quantite}'),
              if (_isReceivedLike)
                _MetaPill(label: 'Qte recu', value: '${line.quantiteRecue}'),
              _MetaPill(label: 'Prix', value: formatPrice(line.prixUnitaire)),
              _MetaPill(label: 'TVA', value: formatVatRate(line.tauxTVA)),
            ],
          ),
          const SizedBox(height: 12),
          _AmountRow(
            label: 'Total HT',
            value: formatPrice(computed.sousTotalHt),
          ),
          const SizedBox(height: 6),
          _AmountRow(
            label: 'Total TTC',
            value: formatPrice(computed.sousTotalTtc),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLinesTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                  'Qte cmd',
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
                  'Qte recu',
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
          _DesktopOrderLineRow(
            computed: computed,
            showReceptionStatus: _isReceivedLike,
            receptionStatus: _receptionStatusFor(computed.line),
          ),
          if (computed != _computedLines.last)
            const Divider(color: Color(0xFFE6EAF2), height: 18),
        ],
      ],
    );
  }

  Widget _buildLinesSection(bool phone) {
    return _SectionCard(
      title: 'Articles',
      child: _computedLines.isEmpty
          ? const EmptyPanel(
              title: 'Aucune ligne',
              message: 'Cette commande ne contient aucun produit.',
            )
          : phone
          ? Column(
              children: [
                for (var i = 0; i < _computedLines.length; i++) ...[
                  _buildPhoneLineCard(_computedLines[i]),
                  if (i != _computedLines.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            )
          : _buildDesktopLinesTable(),
    );
  }

  Widget _buildVatSection() {
    if (_vatBreakdown.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'TVA',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _vatBreakdown.entries.map((entry) {
          return _MetaPill(
            label: 'TVA ${formatVatRate(entry.key)}',
            value:
                '${formatPrice(entry.value.tva)} • Base ${formatPrice(entry.value.ht)}',
            tint: procurementPrimary.withValues(alpha: 0.08),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return _SectionCard(
      title: 'Totaux',
      child: Column(
        children: [
          _AmountRow(label: 'Total HT', value: formatPrice(_totalHt)),
          const SizedBox(height: 6),
          _AmountRow(label: 'TVA', value: formatPrice(_totalTva)),
          const SizedBox(height: 8),
          _AmountRow(
            label: 'Total TTC',
            value: formatPrice(_totalTtc),
            emphasize: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool phone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(phone ? 16 : 24, 12, phone ? 16 : 24, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: procurementLine)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: phone
            ? OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              )
            : TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = isBottomSheet || MediaQuery.sizeOf(context).width < 600;

    final surface = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: phone ? double.infinity : 1040,
        maxHeight: phone ? MediaQuery.sizeOf(context).height * 0.94 : 820,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildHeader(context, phone),
          const Divider(height: 1, color: procurementLine),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                phone ? 16 : 24,
                16,
                phone ? 16 : 24,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaStrip(phone),
                  const SizedBox(height: 14),
                  if (phone) ...[
                    _buildInfoSection(phone),
                    const SizedBox(height: 12),
                    _buildDeliverySection(phone),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInfoSection(phone)),
                        const SizedBox(width: 14),
                        Expanded(child: _buildDeliverySection(phone)),
                      ],
                    ),
                  if (order.motifRejet?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 12),
                    _buildRejectAlert(),
                  ],
                  const SizedBox(height: 12),
                  _buildLinesSection(phone),
                  if (_vatBreakdown.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildVatSection(),
                  ],
                  const SizedBox(height: 12),
                  _buildTotalsSection(),
                ],
              ),
            ),
          ),
          _buildFooter(context, phone),
        ],
      ),
    );

    if (isBottomSheet) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: SafeArea(top: false, child: surface),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: surface,
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

  const _ReceptionStatus({required this.label, required this.color});
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: procurementSoftBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: procurementLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: procurementMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trim().isEmpty ? 'N/A' : value,
              style: const TextStyle(
                color: procurementInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? tint;

  const _MetaPill({required this.label, required this.value, this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint ?? procurementSoftBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: procurementLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: procurementMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: procurementInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasize ? procurementInk : procurementMuted,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? procurementPrimary : procurementInk,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 17 : 14,
          ),
        ),
      ],
    );
  }
}

class _DesktopOrderLineRow extends StatelessWidget {
  final _ComputedOrderLine computed;
  final bool showReceptionStatus;
  final _ReceptionStatus receptionStatus;

  const _DesktopOrderLineRow({
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
