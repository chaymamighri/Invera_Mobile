import 'package:flutter/material.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';

class CommercialCommandesSection extends StatefulWidget {
  const CommercialCommandesSection({super.key});

  @override
  State<CommercialCommandesSection> createState() => _CommercialCommandesSectionState();
}

class _CommercialCommandesSectionState extends State<CommercialCommandesSection> {
  final CommandeService _commandeService = CommandeService();
  final ClientService _clientService = ClientService();

  final List<CommandeModel> _commandes = [];
  final List<ClientModel> _clients = [];
  final List<ProduitOption> _produits = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  String _statusFilter = 'TOUS';
  int _draftLineSeed = 0;

  static const List<String> _statuses = ['TOUS', 'EN_ATTENTE', 'CONFIRMEE', 'ANNULEE'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _commandeService.getCommandes(),
        _clientService.getClients(),
        _commandeService.getProduits(),
      ]);
      if (!mounted) return;

      setState(() {
        _commandes
          ..clear()
          ..addAll(results[0] as List<CommandeModel>);
        _clients
          ..clear()
          ..addAll(results[1] as List<ClientModel>);
        _produits
          ..clear()
          ..addAll(results[2] as List<ProduitOption>);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reloadCommandes({bool showBusy = false}) async {
    if (showBusy && mounted) {
      setState(() => _isBusy = true);
    }

    try {
      final statut = _statusFilter == 'TOUS' ? null : _statusFilter;
      final data = await _commandeService.getCommandes(statut: statut);
      if (!mounted) return;

      setState(() {
        _commandes
          ..clear()
          ..addAll(data);
      });
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (showBusy && mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _onCreate() async {
    final result = await _openCommandeForm();
    if (result == null) return;

    setState(() => _isBusy = true);
    try {
      final created = await _commandeService.createCommande(
        CommandeCreatePayload(
          clientId: result.clientId,
          produits: result.produits,
          remiseTotale: result.remiseTotale,
        ),
      );
      await _reloadCommandes();
      _showMessage('Commande creee: ${created.referenceCommandeClient}');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _onEdit(CommandeModel commande) async {
    if (!commande.canEdit) {
      _showMessage('Seules les commandes EN_ATTENTE sont modifiables.', isError: true);
      return;
    }

    final result = await _openCommandeForm(initialCommande: commande);
    if (result == null) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.updateCommande(
        commande.idCommandeClient,
        CommandeUpdatePayload(
          clientId: result.clientId,
          clientAdresse: result.clientAdresse,
          clientTelephone: result.clientTelephone,
          clientEmail: result.clientEmail,
          produits: result.produits,
        ),
      );
      await _reloadCommandes();
      _showMessage('Commande modifiee');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _onCancel(CommandeModel commande) async {
    if (!commande.canCancel) {
      _showMessage('Commande deja annulee.', isError: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Annuler commande'),
          content: Text('Annuler ${commande.referenceCommandeClient} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _isBusy = true);
    try {
      await _commandeService.rejeterCommande(commande.idCommandeClient);
      await _reloadCommandes();
      _showMessage('Commande annulee');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _onDetails(CommandeModel commande) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Details ${commande.referenceCommandeClient}'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _metaBadge('Client', commande.client?.fullName ?? '-'),
                      _metaBadge('Date', commande.dateCommandeFormatted),
                      _metaBadge('Statut', commande.statutDisplay),
                      _metaBadge('Total', '${commande.total.toStringAsFixed(2)} DT'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'Produits',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (commande.produits.isEmpty)
                    const Text('- Aucun produit')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF4F7FC)),
                        columns: const [
                          DataColumn(label: Text('Produit')),
                          DataColumn(label: Text('Qte')),
                          DataColumn(label: Text('PU')),
                          DataColumn(label: Text('Sous-total')),
                        ],
                        rows: commande.produits
                            .map(
                              (p) => DataRow(
                                cells: [
                                  DataCell(Text(p.libelle)),
                                  DataCell(Text('${p.quantite}')),
                                  DataCell(Text(p.prixUnitaire.toStringAsFixed(2))),
                                  DataCell(Text(p.sousTotal.toStringAsFixed(2))),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ],
        );
      },
    );
  }

  Future<_CommandeFormResult?> _openCommandeForm({CommandeModel? initialCommande}) async {
    final formKey = GlobalKey<FormState>();
    final isEdit = initialCommande != null;
    int? selectedClientId = initialCommande?.client?.idClient;
    final removedLines = <_DraftLine>[];

    final remiseController = TextEditingController(
      text: (initialCommande?.tauxRemise ?? 0).toStringAsFixed(2),
    );

    final lines = <_DraftLine>[
      if (isEdit && initialCommande.produits.isNotEmpty)
        ...initialCommande.produits.map(
          (p) => _newDraftLine(
            produitId: p.produitId,
            quantite: p.quantite,
            fallbackPrix: p.prixUnitaire,
          ),
        )
      else
        _newDraftLine(produitId: _firstAvailableProduitId(const <_DraftLine>[])),
    ];

    final result = await showDialog<_CommandeFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final remiseValue = double.tryParse(
                  remiseController.text.trim().replaceAll(',', '.'),
                ) ??
                0;
            final draftSubTotal = _draftSubTotal(lines);
            final draftTotal = _draftTotalAfterRemise(lines, remiseValue);
            final canAddLine = _firstAvailableProduitId(lines) != null;

            return AlertDialog(
              title: Text(isEdit ? 'Modifier commande' : 'Nouvelle commande'),
              content: SizedBox(
                width: 860,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                key: ValueKey('client-${selectedClientId ?? 0}-${isEdit ? 1 : 0}'),
                                initialValue: selectedClientId,
                                decoration: const InputDecoration(
                                  labelText: 'Client',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: _clients
                                    .map(
                                      (c) => DropdownMenuItem<int>(
                                        value: c.id,
                                        child: Text('${c.nom} (${c.telephone})'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: isEdit ? null : (v) => setModal(() => selectedClientId = v),
                                validator: (v) => v == null || v <= 0 ? 'Client requis' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 190,
                              child: TextFormField(
                                controller: remiseController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Remise (%)',
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                onChanged: (_) => setModal(() {}),
                                validator: (value) {
                                  final val = double.tryParse(
                                    (value ?? '').trim().replaceAll(',', '.'),
                                  );
                                  if (val == null) return 'Valeur invalide';
                                  if (val < 0 || val > 100) return '0 a 100';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDE6FF)),
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _metaBadge('Sous-total', '${draftSubTotal.toStringAsFixed(2)} DT'),
                              _metaBadge('Remise', '${remiseValue.toStringAsFixed(2)} %'),
                              _metaBadge('Total estime', '${draftTotal.toStringAsFixed(2)} DT'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Lignes produits',
                            style: TextStyle(
                              color: Colors.blueGrey[900],
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(lines.length, (index) {
                          final line = lines[index];
                          final availableProducts = _availableProductsForLine(lines, line);
                          final dropdownValue = availableProducts.any((p) => p.idProduit == line.produitId)
                              ? line.produitId
                              : null;
                          final hasAnyOption = availableProducts.isNotEmpty;
                          final lineTotal = _lineSubTotal(line);

                          return Container(
                            key: ValueKey(line.rowKey),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    key: ValueKey('prod-${line.rowKey}-${dropdownValue ?? 0}'),
                                    initialValue: dropdownValue,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Produit',
                                      isDense: true,
                                      prefixIcon: Icon(Icons.inventory_2_outlined),
                                    ),
                                    items: availableProducts
                                        .map(
                                          (p) => DropdownMenuItem<int>(
                                            value: p.idProduit,
                                            child: Text(
                                              '${p.libelle} | stock ${p.quantiteStock}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: hasAnyOption
                                        ? (v) {
                                            setModal(() => line.produitId = v);
                                          }
                                        : null,
                                    validator: (v) => v == null || v <= 0 ? 'Produit requis' : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    controller: line.quantiteController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Qte',
                                      isDense: true,
                                    ),
                                    onChanged: (_) => setModal(() {}),
                                    validator: (v) {
                                      final qty = int.tryParse((v ?? '').trim());
                                      if (qty == null || qty <= 0) return 'Qte';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 110,
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Sous-total',
                                      isDense: true,
                                    ),
                                    child: Text('${lineTotal.toStringAsFixed(2)} DT'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  tooltip: 'Supprimer ligne',
                                  onPressed: lines.length <= 1
                                      ? null
                                      : () {
                                          final removed = lines.removeAt(index);
                                          removedLines.add(removed);
                                          setModal(() {});
                                        },
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: !canAddLine
                                ? null
                                : () {
                                    final nextProduitId = _firstAvailableProduitId(lines);
                                    if (nextProduitId == null) return;

                                    lines.add(_newDraftLine(produitId: nextProduitId));
                                    setModal(() {});
                                  },
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter produit'),
                          ),
                        ),
                        if (!canAddLine)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tous les produits disponibles sont deja selectionnes.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (selectedClientId == null || selectedClientId! <= 0) {
                      _showMessage('Client requis.', isError: true);
                      return;
                    }
                    if (!_hasUniqueProducts(lines)) {
                      _showMessage('Chaque produit ne peut etre selectionne qu une seule fois.', isError: true);
                      return;
                    }

                    final produits = _buildProduitPayload(lines);
                    if (produits.isEmpty) {
                      _showMessage('Ajoutez au moins un produit valide.', isError: true);
                      return;
                    }

                    ClientModel? selectedClient;
                    for (final c in _clients) {
                      if (c.id == selectedClientId) {
                        selectedClient = c;
                        break;
                      }
                    }

                    final remise = double.tryParse(
                          remiseController.text.trim().replaceAll(',', '.'),
                        ) ??
                        0;

                    Navigator.pop(
                      dialogContext,
                      _CommandeFormResult(
                        clientId: selectedClientId!,
                        produits: produits,
                        remiseTotale: remise,
                        clientAdresse: selectedClient?.adresse,
                        clientTelephone: selectedClient?.telephone,
                        clientEmail: selectedClient?.email,
                      ),
                    );
                  },
                  child: Text(isEdit ? 'Modifier' : 'Creer'),
                ),
              ],
            );
          },
        );
      },
    );

    for (final line in lines) {
      line.dispose();
    }
    for (final line in removedLines) {
      line.dispose();
    }
    remiseController.dispose();

    return result;
  }

  _DraftLine _newDraftLine({
    int? produitId,
    int quantite = 1,
    double? fallbackPrix,
  }) {
    _draftLineSeed += 1;
    return _DraftLine(
      rowKey: 'line_$_draftLineSeed',
      produitId: produitId,
      quantite: quantite,
      fallbackPrix: fallbackPrix,
    );
  }

  List<ProduitOption> _availableProductsForLine(List<_DraftLine> lines, _DraftLine currentLine) {
    final selectedOnOtherLines = <int>{};
    for (final line in lines) {
      if (line.rowKey == currentLine.rowKey) continue;
      final id = line.produitId;
      if (id != null && id > 0) {
        selectedOnOtherLines.add(id);
      }
    }

    return _produits.where((p) {
      if (currentLine.produitId == p.idProduit) return true;
      return !selectedOnOtherLines.contains(p.idProduit);
    }).toList();
  }

  bool _hasUniqueProducts(List<_DraftLine> lines) {
    final used = <int>{};
    for (final line in lines) {
      final id = line.produitId;
      if (id == null || id <= 0) continue;
      if (!used.add(id)) {
        return false;
      }
    }
    return true;
  }

  int? _firstAvailableProduitId(List<_DraftLine> lines) {
    final used = <int>{};
    for (final line in lines) {
      final id = line.produitId;
      if (id != null && id > 0) {
        used.add(id);
      }
    }

    for (final p in _produits) {
      if (!used.contains(p.idProduit)) return p.idProduit;
    }

    return null;
  }

  double _lineSubTotal(_DraftLine line) {
    final qty = int.tryParse(line.quantiteController.text.trim()) ?? 0;
    if (qty <= 0) return 0;

    final produit = _findProduitById(line.produitId);
    final prix = produit?.prixVente ?? line.fallbackPrix ?? 0;
    return qty * prix;
  }

  double _draftSubTotal(List<_DraftLine> lines) {
    var total = 0.0;
    for (final line in lines) {
      total += _lineSubTotal(line);
    }
    return total;
  }

  double _draftTotalAfterRemise(List<_DraftLine> lines, double remisePercent) {
    final normalized = remisePercent.clamp(0, 100);
    final sub = _draftSubTotal(lines);
    return sub * (1 - (normalized / 100));
  }

  ProduitOption? _findProduitById(int? produitId) {
    if (produitId == null || produitId <= 0) return null;

    for (final p in _produits) {
      if (p.idProduit == produitId) return p;
    }
    return null;
  }

  List<CommandeProduitPayload> _buildProduitPayload(List<_DraftLine> lines) {
    final merged = <int, CommandeProduitPayload>{};

    for (final line in lines) {
      final produitId = line.produitId;
      final qty = int.tryParse(line.quantiteController.text.trim());
      if (produitId == null || produitId <= 0 || qty == null || qty <= 0) {
        continue;
      }

      final produit = _findProduitById(produitId);
      final prix = produit?.prixVente ?? line.fallbackPrix;

      if (merged.containsKey(produitId)) {
        final existing = merged[produitId]!;
        merged[produitId] = CommandeProduitPayload(
          produitId: produitId,
          quantite: existing.quantite + qty,
          prixUnitaire: existing.prixUnitaire ?? prix,
        );
      } else {
        merged[produitId] = CommandeProduitPayload(
          produitId: produitId,
          quantite: qty,
          prixUnitaire: prix,
        );
      }
    }

    return merged.values.toList();
  }

  String _displayStatus(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'EN_ATTENTE') return 'En attente';
    if (normalized == 'CONFIRMEE') return 'Confirmee';
    if (normalized == 'ANNULEE') return 'Annulee';
    return raw;
  }

  _StatusStyle _statusStyle(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'CONFIRMEE') {
      return const _StatusStyle(
        background: Color(0xFFE9F8EF),
        foreground: Color(0xFF11853F),
      );
    }
    if (normalized == 'ANNULEE') {
      return const _StatusStyle(
        background: Color(0xFFFFE8E8),
        foreground: Color(0xFFB42318),
      );
    }
    return const _StatusStyle(
      background: Color(0xFFEFF4FF),
      foreground: Color(0xFF2D47C8),
    );
  }

  Widget _buildStatusChip(String rawStatus) {
    final style = _statusStyle(rawStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _displayStatus(rawStatus),
        style: TextStyle(
          color: style.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _metaBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _productsPreview(CommandeModel commande) {
    if (commande.produits.isEmpty) return '- Aucun produit';

    final names = commande.produits.map((p) => p.libelle).toList();
    if (names.length <= 2) {
      return names.join(' + ');
    }
    return '${names[0]} + ${names[1]} + ${names.length - 2} autres';
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2A44),
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final pending = _commandes.where((c) => c.statut.toUpperCase() == 'EN_ATTENTE').length;
    final confirmed = _commandes.where((c) => c.statut.toUpperCase() == 'CONFIRMEE').length;
    final cancelled = _commandes.where((c) => c.statut.toUpperCase() == 'ANNULEE').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 920;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryCard(
                        label: 'Total',
                        value: '${_commandes.length}',
                        color: const Color(0xFF2D47C8),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      _summaryCard(
                        label: 'En attente',
                        value: '$pending',
                        color: const Color(0xFF2D47C8),
                        icon: Icons.timelapse_outlined,
                      ),
                      _summaryCard(
                        label: 'Confirmees',
                        value: '$confirmed',
                        color: const Color(0xFF11853F),
                        icon: Icons.verified_outlined,
                      ),
                      _summaryCard(
                        label: 'Annulees',
                        value: '$cancelled',
                        color: const Color(0xFFB42318),
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatusFilter()),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Actualiser',
                        onPressed: _isBusy ? null : () => _reloadCommandes(showBusy: true),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _onCreate,
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle commande'),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _summaryCard(
                        label: 'Total',
                        value: '${_commandes.length}',
                        color: const Color(0xFF2D47C8),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      _summaryCard(
                        label: 'En attente',
                        value: '$pending',
                        color: const Color(0xFF2D47C8),
                        icon: Icons.timelapse_outlined,
                      ),
                      _summaryCard(
                        label: 'Confirmees',
                        value: '$confirmed',
                        color: const Color(0xFF11853F),
                        icon: Icons.verified_outlined,
                      ),
                      _summaryCard(
                        label: 'Annulees',
                        value: '$cancelled',
                        color: const Color(0xFFB42318),
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: _buildStatusFilter()),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _isBusy ? null : () => _reloadCommandes(showBusy: true),
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle commande'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      key: ValueKey('status-filter-$_statusFilter'),
      initialValue: _statusFilter,
      decoration: const InputDecoration(
        isDense: true,
        labelText: 'Filtre statut',
        prefixIcon: Icon(Icons.filter_alt_outlined),
      ),
      items: _statuses
          .map(
            (e) => DropdownMenuItem<String>(
              value: e,
              child: Text(e == 'TOUS' ? 'Tous' : _displayStatus(e)),
            ),
          )
          .toList(),
      onChanged: _isBusy
          ? null
          : (v) {
              setState(() => _statusFilter = v ?? 'TOUS');
              _reloadCommandes(showBusy: true);
            },
    );
  }

  Widget _buildCommandeCard(CommandeModel commande) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    commande.referenceCommandeClient,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Color(0xFF1F2A44),
                    ),
                  ),
                ),
                _buildStatusChip(commande.statut),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metaBadge('Client', commande.client?.fullName ?? '-'),
                _metaBadge('Date', commande.dateCommandeFormatted),
                _metaBadge('Lignes', '${commande.produits.length}'),
                _metaBadge('Total', '${commande.total.toStringAsFixed(2)} DT'),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _productsPreview(commande),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _onDetails(commande),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Details'),
                ),
                OutlinedButton.icon(
                  onPressed: (_isBusy || !commande.canEdit) ? null : () => _onEdit(commande),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                OutlinedButton.icon(
                  onPressed: (_isBusy || !commande.canCancel) ? null : () => _onCancel(commande),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF0CAE4A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (_isBusy) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 10),
        Expanded(
          child: _commandes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_cart_outlined, size: 52, color: Color(0xFF607089)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune commande disponible',
                        style: TextStyle(color: Color(0xFF607089), fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isBusy ? null : _onCreate,
                        icon: const Icon(Icons.add),
                        label: const Text('Creer une commande'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _commandes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _buildCommandeCard(_commandes[index]),
                ),
        ),
      ],
    );
  }
}

class _DraftLine {
  final String rowKey;
  int? produitId;
  final TextEditingController quantiteController;
  final double? fallbackPrix;

  _DraftLine({
    required this.rowKey,
    this.produitId,
    int quantite = 1,
    this.fallbackPrix,
  }) : quantiteController = TextEditingController(text: '$quantite');

  void dispose() => quantiteController.dispose();
}

class _CommandeFormResult {
  final int clientId;
  final List<CommandeProduitPayload> produits;
  final double remiseTotale;
  final String? clientAdresse;
  final String? clientTelephone;
  final String? clientEmail;

  _CommandeFormResult({
    required this.clientId,
    required this.produits,
    required this.remiseTotale,
    this.clientAdresse,
    this.clientTelephone,
    this.clientEmail,
  });
}

class _StatusStyle {
  final Color background;
  final Color foreground;

  const _StatusStyle({
    required this.background,
    required this.foreground,
  });
}
