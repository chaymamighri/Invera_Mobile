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

  const ReceptionModal({super.key, required this.order});

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: procurementAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reception de bon de commande - ${_order.numeroCommande}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: procurementInk,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: procurementMist,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: procurementLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fournisseur',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: procurementInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _order.fournisseur?.nomFournisseur ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _order.fournisseur?.email ?? '-',
                      style: const TextStyle(color: procurementMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _numeroBlController,
                onChanged: _handleNumeroBlChanged,
                decoration: InputDecoration(
                  labelText: 'Numero de bon de livraison *',
                  hintText: 'Ex: BL-2024-001',
                  errorText: _numeroBlError,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: procurementLine),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 210,
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
                              width: 90,
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
                              width: 90,
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
                              width: 100,
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
                                'Activer',
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
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                          itemBuilder: (context, index) {
                            final line = _order.lignesCommande[index];
                            final id = _lineId(line);
                            final qteRecue = _receivedQtyFor(line);
                            final ecart = line.quantite - qteRecue;
                            final estActif = !line.estInactif;
                            final estInactifEtRecu =
                                line.estInactif && qteRecue > 0;

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
                                    width: 210,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    width: 90,
                                    child: Text(
                                      '${line.quantite}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                    width: 90,
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
                                    width: 100,
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
                                                  value:
                                                      _produitsAReactiver[id] ??
                                                      false,
                                                  onChanged: (value) {
                                                    _handleReactiverChanged(
                                                      id,
                                                      value ?? false,
                                                    );
                                                  },
                                                ),
                                                Text(
                                                  (_produitsAReactiver[id] ??
                                                          false)
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
              ),

              if (_quantiteZeroError != null) ...[
                const SizedBox(height: 14),
                Container(
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
                          style: const TextStyle(
                            color: procurementDanger,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes de reception (optionnel)',
                  hintText:
                      'Ajouter des notes sur cette reception (retard, qualite, etc.)...',
                ),
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: procurementMist,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: procurementLine),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total HT recu: ${formatPrice(_totalHtReceived)}'),
                    const SizedBox(height: 4),
                    Text('Total TVA: ${formatPrice(_totalVatReceived)}'),
                    const SizedBox(height: 6),
                    Text(
                      'Total TTC recu: ${formatPrice(_totalTtcReceived)}',
                      style: const TextStyle(
                        color: procurementAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (!_toutesRecues) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: procurementWarning,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Reception partielle - certaines quantites sont differentes',
                              style: TextStyle(
                                color: procurementWarning,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}
