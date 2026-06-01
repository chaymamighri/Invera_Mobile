import 'package:flutter/material.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';

class ReceptionModalResult {
  final Map<int, int> quantitesRecues;
  final String numeroBL;
  final String? notes;
  final DateTime dateReception;
  final Map<int, bool> produitsAReactiver;

  const ReceptionModalResult({
    required this.quantitesRecues,
    required this.numeroBL,
    required this.notes,
    required this.dateReception,
    required this.produitsAReactiver,
  });
}

class ReceptionModal extends StatefulWidget {
  final ProcurementOrder order;
  final bool isBottomSheet;

  const ReceptionModal({
    super.key,
    required this.order,
    this.isBottomSheet = false,
  });

  @override
  State<ReceptionModal> createState() => _ReceptionModalState();
}

class _ReceptionModalState extends State<ReceptionModal> {
  final TextEditingController _numeroBlController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  late final Map<int, TextEditingController> _qtyControllers;
  late final Map<int, bool> _produitsAReactiver;

  String? _numeroBlError;
  String? _quantiteZeroError;
  final Map<int, String> _quantitesDepassees = {};

  ProcurementOrder get _order => widget.order;

  @override
  void initState() {
    super.initState();

    _qtyControllers = {
      for (final line in _order.lignesCommande)
        _lineId(line): TextEditingController(text: '${line.quantite}'),
    };

    _produitsAReactiver = {
      for (final line in _order.lignesCommande) _lineId(line): line.estInactif,
    };
  }

  @override
  void dispose() {
    _numeroBlController.dispose();
    _notesController.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _lineId(ProcurementOrderLine line) =>
      line.idLigneCommandeFournisseur ?? line.produitId;

  int _receivedQtyFor(ProcurementOrderLine line) {
    return int.tryParse(_qtyControllers[_lineId(line)]?.text ?? '') ?? 0;
  }

  bool get _hasAtLeastOneReceivedProduct {
    return _order.lignesCommande.any((line) => _receivedQtyFor(line) > 0);
  }

  void _handleNumeroBlChanged(String value) {
    setState(() {
      _numeroBlError = value.trim().isEmpty
          ? 'Le numero de bon de livraison est obligatoire'
          : null;
    });
  }

  void _handleQuantityChanged(ProcurementOrderLine line, String value) {
    final quantite = int.tryParse(value) ?? 0;
    final lineId = _lineId(line);

    setState(() {
      if (quantite > line.quantite) {
        _quantitesDepassees[lineId] =
            'La quantite ne peut pas depasser ${line.quantite}';
      } else {
        _quantitesDepassees.remove(lineId);
      }

      _quantiteZeroError = _hasAtLeastOneReceivedProduct
          ? null
          : 'Veuillez saisir au moins un produit recu (quantite > 0)';
    });
  }

  void _handleReactiverChanged(int lineId, bool checked) {
    setState(() {
      _produitsAReactiver[lineId] = checked;
    });
  }

  double get _totalHtReceived {
    double total = 0;
    for (final line in _order.lignesCommande) {
      total += _receivedQtyFor(line) * line.prixUnitaire;
    }
    return total;
  }

  double get _totalVatReceived {
    double total = 0;
    for (final line in _order.lignesCommande) {
      final ht = _receivedQtyFor(line) * line.prixUnitaire;
      total += ht * (line.tauxTVA / 100);
    }
    return total;
  }

  double get _totalTtcReceived => _totalHtReceived + _totalVatReceived;

  bool get _toutesRecues {
    return _order.lignesCommande.every(
      (line) => _receivedQtyFor(line) == line.quantite,
    );
  }

  void _submit() {
    bool hasError = false;
    String? numeroBlError;
    String? quantiteZeroError;
    final quantitesDepassees = <int, String>{};

    if (_numeroBlController.text.trim().isEmpty) {
      numeroBlError = 'Le numero de bon de livraison est obligatoire';
      hasError = true;
    }

    if (!_hasAtLeastOneReceivedProduct) {
      quantiteZeroError =
          'Veuillez saisir au moins un produit recu (quantite > 0)';
      hasError = true;
    }

    for (final line in _order.lignesCommande) {
      final id = _lineId(line);
      final qteRecue = _receivedQtyFor(line);

      if (qteRecue > line.quantite) {
        quantitesDepassees[id] =
            'La quantite ne peut pas depasser ${line.quantite}';
        hasError = true;
      }
    }

    setState(() {
      _numeroBlError = numeroBlError;
      _quantiteZeroError = quantiteZeroError;
      _quantitesDepassees
        ..clear()
        ..addAll(quantitesDepassees);
    });

    if (hasError) return;

    final quantitesRecues = <int, int>{
      for (final line in _order.lignesCommande)
        _lineId(line): _receivedQtyFor(line),
    };

    final produitsAReactiverMap = <int, bool>{};
    for (final line in _order.lignesCommande) {
      final id = _lineId(line);
      final qteRecue = quantitesRecues[id] ?? 0;
      if (line.estInactif &&
          qteRecue > 0 &&
          (_produitsAReactiver[id] ?? false)) {
        produitsAReactiverMap[id] = true;
      }
    }

    Navigator.pop(
      context,
      ReceptionModalResult(
        quantitesRecues: quantitesRecues,
        numeroBL: _numeroBlController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        dateReception: DateTime.now(),
        produitsAReactiver: produitsAReactiverMap,
      ),
    );
  }

  Widget _buildHeader(bool phone) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        phone ? 16 : 22,
        phone ? 16 : 20,
        phone ? 8 : 14,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: phone ? 42 : 48,
            height: phone ? 42 : 48,
            decoration: BoxDecoration(
              color: procurementAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: procurementAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reception de commande',
                  style: TextStyle(
                    fontSize: phone ? 18 : 21,
                    fontWeight: FontWeight.w800,
                    color: procurementInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _order.numeroCommande,
                  style: TextStyle(
                    fontSize: phone ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: procurementPrimary,
                  ),
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

  Widget _buildSupplierCard(bool phone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(phone ? 14 : 16),
      decoration: BoxDecoration(
        color: procurementMist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: procurementLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fournisseur',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: procurementMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _order.fournisseur?.nomFournisseur ?? '-',
            style: TextStyle(
              fontSize: phone ? 16 : 17,
              fontWeight: FontWeight.w700,
              color: procurementInk,
            ),
          ),
          if (_order.fournisseur?.email.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              _order.fournisseur!.email,
              style: const TextStyle(color: procurementMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner(bool phone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(phone ? 12 : 14),
      decoration: BoxDecoration(
        color: procurementSoftBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: procurementLine),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: procurementPrimary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les quantites validees seront ajoutees automatiquement au stock apres confirmation de la reception.',
              style: TextStyle(
                color: procurementMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLineCard(ProcurementOrderLine line) {
    final id = _lineId(line);
    final qteRecue = _receivedQtyFor(line);
    final ecart = line.quantite - qteRecue;
    final estInactifEtRecu = line.estInactif && qteRecue > 0;
    final ecartColor = ecart == 0
        ? procurementMuted
        : ecart > 0
        ? procurementWarning
        : procurementPrimary;
    final ecartLabel = ecart == 0
        ? '0'
        : ecart > 0
        ? '-$ecart'
        : '+${ecart.abs()}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estInactifEtRecu
            ? const Color(0xFFFFFBEB)
            : procurementSoftBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: estInactifEtRecu ? const Color(0xFFFED7AA) : procurementLine,
        ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
              const SizedBox(width: 10),
              StatusPill(
                label: line.estInactif ? 'Inactif' : 'Actif',
                color: line.estInactif ? procurementWarning : procurementAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReceptionMetaPill(label: 'Cmd', value: '${line.quantite}'),
              _ReceptionMetaPill(
                label: 'Prix',
                value: formatPrice(line.prixUnitaire),
              ),
              _ReceptionMetaPill(
                label: 'TVA',
                value: formatVatRate(line.tauxTVA),
              ),
              _ReceptionMetaPill(
                label: 'Ecart',
                value: ecartLabel,
                color: ecartColor.withValues(alpha: 0.12),
                textColor: ecartColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyControllers[id],
            keyboardType: TextInputType.number,
            onChanged: (value) => _handleQuantityChanged(line, value),
            decoration: InputDecoration(
              labelText: 'Quantite recuee',
              hintText: '0',
              isDense: true,
              errorText: _quantitesDepassees[id],
            ),
          ),
          if (estInactifEtRecu) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _produitsAReactiver[id] ?? false,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) {
                      _handleReactiverChanged(id, value ?? false);
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      (_produitsAReactiver[id] ?? false)
                          ? 'Le produit sera reactive'
                          : 'Reactiver ce produit a la reception',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: procurementMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLinesTable() {
    return SizedBox(
      height: 350,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: procurementLine),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      'Produit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      'Cmd',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(
                      'Prix unit.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Recu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 86,
                    child: Text(
                      'Ecart',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: procurementMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Reactiver',
                      textAlign: TextAlign.center,
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
            Expanded(
              child: ListView.separated(
                itemCount: _order.lignesCommande.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (context, index) {
                  final line = _order.lignesCommande[index];
                  final id = _lineId(line);
                  final qteRecue = _receivedQtyFor(line);
                  final ecart = line.quantite - qteRecue;
                  final estActif = !line.estInactif;
                  final estInactifEtRecu = line.estInactif && qteRecue > 0;

                  return Container(
                    color: estInactifEtRecu
                        ? const Color(0xFFFFFBEB)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.produitLibelle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: procurementInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Ref: ${line.produitReference}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: procurementMuted,
                                ),
                              ),
                              if (line.categorieNom.trim().isNotEmpty)
                                Text(
                                  line.categorieNom,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 86,
                          child: Text(
                            '${line.quantite}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(formatPrice(line.prixUnitaire)),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _qtyControllers[id],
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                _handleQuantityChanged(line, value),
                            decoration: InputDecoration(
                              isDense: true,
                              errorText: _quantitesDepassees[id],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 86,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              ecart == 0
                                  ? '0'
                                  : ecart > 0
                                  ? '-$ecart'
                                  : '+${ecart.abs()}',
                              style: TextStyle(
                                color: ecart == 0
                                    ? procurementMuted
                                    : ecart > 0
                                    ? procurementWarning
                                    : procurementPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 96,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StatusPill(
                              label: estActif ? 'Actif' : 'Inactif',
                              color: estActif
                                  ? procurementAccent
                                  : procurementWarning,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: estInactifEtRecu
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _produitsAReactiver[id] ?? false,
                                        onChanged: (value) {
                                          _handleReactiverChanged(
                                            id,
                                            value ?? false,
                                          );
                                        },
                                      ),
                                      Text(
                                        (_produitsAReactiver[id] ?? false)
                                            ? 'Oui'
                                            : 'Non',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: procurementMuted,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinesSection(bool phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Produits a recevoir',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: procurementInk,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: procurementSoftBackground,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: procurementLine),
              ),
              child: Text(
                '${_order.lignesCommande.length} ligne(s)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: procurementMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (phone)
          Column(
            children: [
              for (var i = 0; i < _order.lignesCommande.length; i++) ...[
                _buildPhoneLineCard(_order.lignesCommande[i]),
                if (i != _order.lignesCommande.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          )
        else
          _buildDesktopLinesTable(),
      ],
    );
  }

  Widget _buildValidationError() {
    if (_quantiteZeroError == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: procurementDanger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _quantiteZeroError!,
              style: const TextStyle(color: procurementDanger, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool phone) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(phone ? 14 : 16),
      decoration: BoxDecoration(
        color: procurementMist,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: procurementLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Synthese reception',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: procurementInk,
            ),
          ),
          const SizedBox(height: 12),
          _ReceptionSummaryRow(
            label: 'Total HT recu',
            value: formatPrice(_totalHtReceived),
          ),
          const SizedBox(height: 6),
          _ReceptionSummaryRow(
            label: 'Total TVA',
            value: formatPrice(_totalVatReceived),
          ),
          const SizedBox(height: 8),
          _ReceptionSummaryRow(
            label: 'Total TTC recu',
            value: formatPrice(_totalTtcReceived),
            emphasize: true,
          ),
          if (!_toutesRecues) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: procurementWarning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reception partielle detectee. Certaines quantites recues sont differentes de la commande.',
                      style: TextStyle(
                        color: procurementWarning,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(bool phone) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        phone ? 16 : 22,
        12,
        phone ? 16 : 22,
        phone ? 16 : 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: procurementLine)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: phone
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
                  child: FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmer'),
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
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmer la reception'),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone =
        widget.isBottomSheet || MediaQuery.sizeOf(context).width < 600;

    final surface = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: phone ? double.infinity : 980,
        maxHeight: phone ? MediaQuery.sizeOf(context).height * 0.94 : 780,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(phone ? 24 : 26),
      ),
      child: Column(
        children: [
          _buildHeader(phone),
          const Divider(height: 1, color: procurementLine),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                phone ? 16 : 22,
                16,
                phone ? 16 : 22,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSupplierCard(phone),
                  const SizedBox(height: 12),
                  _buildInfoBanner(phone),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _numeroBlController,
                    onChanged: _handleNumeroBlChanged,
                    decoration: InputDecoration(
                      labelText: 'Numero de bon de livraison *',
                      hintText: 'Ex: BL-2026-001',
                      errorText: _numeroBlError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLinesSection(phone),
                  const SizedBox(height: 14),
                  _buildValidationError(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes de reception (optionnel)',
                      hintText:
                          'Retard, qualite, quantites partielles ou autres remarques...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCard(phone),
                ],
              ),
            ),
          ),
          _buildFooter(phone),
        ],
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          10,
          10,
          MediaQuery.viewInsetsOf(context).bottom > 0
              ? MediaQuery.viewInsetsOf(context).bottom
              : 10,
        ),
        child: SafeArea(top: false, child: surface),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: surface,
    );
  }
}

class _ReceptionMetaPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final Color? textColor;

  const _ReceptionMetaPill({
    required this.label,
    required this.value,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final background = color ?? Colors.white;
    final foreground = textColor ?? procurementInk;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
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
            style: TextStyle(
              fontSize: 12.5,
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceptionSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _ReceptionSummaryRow({
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
            color: emphasize ? procurementAccent : procurementInk,
            fontWeight: FontWeight.w800,
            fontSize: emphasize ? 17 : 14,
          ),
        ),
      ],
    );
  }
}
