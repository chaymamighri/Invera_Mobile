import 'package:flutter/material.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/facture.dart';
import 'package:invera_mobile/services/factures.dart';
import 'package:printing/printing.dart';

const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _borderLight = Color(0xFFE6EAF2);

/// Widget qui affiche les factures generees.
class CommercialFacturesGenereesSection extends StatefulWidget {
  const CommercialFacturesGenereesSection({super.key});

  @override
  State<CommercialFacturesGenereesSection> createState() =>
      _CommercialFacturesGenereesSectionState();
}

class _CommercialFacturesGenereesSectionState
    extends State<CommercialFacturesGenereesSection> {
  final FactureService _factureService = FactureService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  String _query = '';
  List<FactureModel> _factures = <FactureModel>[];

  @override
  void initState() {
    super.initState();
    _loadFactures(showLoader: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFactures({required bool showLoader}) async {
    setState(() {
      if (showLoader) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
    });

    try {
      final data = await _factureService.getAllFactures();
      data.sort((a, b) {
        final ad = DateTime.tryParse(a.dateFactureDisplay);
        final bd = DateTime.tryParse(b.dateFactureDisplay);
        if (ad != null && bd != null) return bd.compareTo(ad);
        return b.idFactureClient.compareTo(a.idFactureClient);
      });

      if (!mounted) return;
      setState(() {
        _factures = data;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _refreshing = false;
      });
    }
  }

  List<FactureModel> get _visibleFactures {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return _factures;

    return _factures.where((facture) {
      final haystack = [
        facture.referenceFactureClient,
        facture.statut,
        facture.dateFactureDisplay,
        facture.commandeId?.toString() ?? '',
        facture.clientId?.toString() ?? '',
        _formatAmount(facture.montantTotal),
      ].join(' ').toLowerCase();
      return haystack.contains(term);
    }).toList();
  }

  double get _visibleTotal {
    return _visibleFactures.fold<double>(
      0,
      (sum, facture) => sum + facture.montantTotal,
    );
  }

  String _formatAmount(double value) {
    return '${value.toStringAsFixed(2)} DT';
  }

  Color _statusColor(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized.contains('PAYE') && !normalized.contains('NON')) {
      return const Color(0xFF0CAE4A);
    }
    if (normalized.contains('NON') || normalized.contains('ATTENTE')) {
      return const Color(0xFFD97706);
    }
    if (normalized.contains('ANNU')) {
      return const Color(0xFFB42318);
    }
    return _primary;
  }

  String _displayStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'PAYE') return 'Payee';
    if (normalized == 'NON_PAYE' || normalized == 'IMPAYEE') {
      return 'Non payee';
    }
    if (normalized == 'EN_ATTENTE') return 'En attente';
    return status.trim().isEmpty ? 'Inconnue' : status;
  }

  bool _isPaid(String status) => status.trim().toUpperCase() == 'PAYE';

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  Future<void> _markFacturePayee(FactureModel facture) async {
    try {
      final updated = await _factureService.markFacturePayee(
        facture.idFactureClient,
        commandeId: facture.commandeId,
      );
      if (!mounted) return;
      final nextFacture = updated ?? facture.copyWith(statut: 'PAYE');
      setState(() {
        _factures = _factures.map((item) {
          return item.idFactureClient == facture.idFactureClient
              ? nextFacture
              : item;
        }).toList();
      });
      _showMessage(
        'Facture ${nextFacture.referenceFactureClient} marquee comme payee.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Mise a jour impossible: ${error.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _exportFacturePdf(FactureModel facture) async {
    try {
      final pdfBytes = await _factureService.downloadFacturePdf(
        facture.idFactureClient,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: '${facture.referenceFactureClient}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Export PDF impossible: ${error.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  void _showFactureDetails(FactureModel facture) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final compact = AdaptiveSurface.isCompact(ctx, breakpoint: 720);
        FactureModel currentFacture = facture;
        bool updating = false;

        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> handlePay() async {
              if (updating || _isPaid(currentFacture.statut)) return;
              modalSetState(() => updating = true);
              try {
                final updated = await _factureService.markFacturePayee(
                  currentFacture.idFactureClient,
                  commandeId: currentFacture.commandeId,
                );
                if (!mounted || !context.mounted) return;
                final nextFacture =
                    updated ?? currentFacture.copyWith(statut: 'PAYE');
                setState(() {
                  _factures = _factures.map((item) {
                    return item.idFactureClient == nextFacture.idFactureClient
                        ? nextFacture
                        : item;
                  }).toList();
                });
                modalSetState(() {
                  currentFacture = nextFacture;
                  updating = false;
                });
              } catch (error) {
                if (!mounted || !context.mounted) return;
                modalSetState(() => updating = false);
                _showMessage(
                  'Mise a jour impossible: ${error.toString().replaceFirst('Exception: ', '')}',
                  isError: true,
                );
              }
            }

            return Dialog(
              insetPadding: EdgeInsets.all(compact ? 10 : 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 20 : 24),
              ),
              child: Container(
                width: AdaptiveLayout.dialogWidth(
                  ctx,
                  max: compact ? 520 : 640,
                  sideMargin: compact ? 10 : 18,
                ),
                padding: EdgeInsets.all(compact ? 14 : 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                currentFacture.referenceFactureClient,
                                style: TextStyle(
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBadge(
                                _displayStatus(currentFacture.statut),
                                _statusColor(currentFacture.statut),
                                _statusColor(
                                  currentFacture.statut,
                                ).withValues(alpha: 0.12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildFactureDetailRow(
                      label: 'Client',
                      value: currentFacture.clientNomComplet ?? '-',
                    ),
                    _buildFactureDetailRow(
                      label: 'Type client',
                      value: currentFacture.clientType ?? '-',
                    ),
                    _buildFactureDetailRow(
                      label: 'Commande',
                      value:
                          currentFacture.commandeReference ??
                          (currentFacture.commandeId == null
                              ? '-'
                              : '#${currentFacture.commandeId}'),
                    ),
                    _buildFactureDetailRow(
                      label: 'Date facture',
                      value: currentFacture.dateFactureDisplay,
                    ),
                    _buildFactureDetailRow(
                      label: 'Montant',
                      value: _formatAmount(currentFacture.montantTotal),
                      isLast: true,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Fermer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _exportFacturePdf(currentFacture),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF'),
                        ),
                        if (!_isPaid(currentFacture.statut))
                          ElevatedButton.icon(
                            onPressed: updating ? null : handlePay,
                            icon: updating
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              updating
                                  ? 'Mise a jour...'
                                  : 'Marquer comme payee',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CAE4A),
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildCountPill(int count, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withValues(alpha: 0.28)),
      ),
      child: Text(
        compact ? '$count' : '$count factures',
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required String tooltip,
    required VoidCallback? onPressed,
    required Widget icon,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      icon: icon,
      style: IconButton.styleFrom(
        foregroundColor: _primary,
        backgroundColor: _background,
        side: const BorderSide(color: _borderLight),
      ),
    );
  }

  Widget _buildSearchField({required bool compact}) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        isDense: true,
        hintText: compact
            ? 'Rechercher facture'
            : 'Rechercher facture, statut, commande...',
        prefixIcon: Icon(Icons.search, size: compact ? 19 : 22),
        suffixIcon: _query.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Vider',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: _background,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 13,
          vertical: compact ? 10 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildHeader(List<FactureModel> visible) {
    final compactPage = AdaptiveSurface.isCompact(context, breakpoint: 430);
    final refreshIcon = _refreshing
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          )
        : const Icon(Icons.refresh, size: 18.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(compactPage ? 12 : 18),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(compactPage ? 14 : 20),
            border: Border.all(color: _borderLight),
            boxShadow: AdaptiveSurface.shadow(
              context,
              breakpoint: 430,
              compactBlur: 8,
              compactOffsetY: 4,
              regularBlur: 14,
              regularOffsetY: 6,
              compactColor: const Color(0x08000000),
              regularColor: const Color(0x0A000000),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final subtitle = Text(
                compact
                    ? 'Recherche rapide des factures generees.'
                    : 'Liste des factures generees a partir des ventes validees.',
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: compactPage ? 11.6 : 12.4,
                  fontWeight: FontWeight.w500,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compactPage) ...[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Factures',
                              style: TextStyle(
                                fontSize: compactPage ? 15.5 : 18,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            subtitle,
                          ],
                        ),
                      ),
                      _buildCountPill(visible.length, compact: compactPage),
                      SizedBox(width: compactPage ? 4 : 8),
                      _buildHeaderIconButton(
                        tooltip: 'Actualiser',
                        onPressed: _refreshing
                            ? null
                            : () => _loadFactures(showLoader: false),
                        icon: refreshIcon,
                      ),
                    ],
                  ),
                  SizedBox(height: compactPage ? 10 : 14),
                  _buildSearchField(compact: compactPage),
                  const SizedBox(height: 8),
                  Text(
                    'Montant visible: ${_formatAmount(_visibleTotal)}',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: compactPage ? 11.5 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFacturesList(List<FactureModel> visible) {
    final compact = AdaptiveSurface.isCompact(context, breakpoint: 430);
    final useTable = AdaptiveSurface.isCompact(context, breakpoint: 920);
    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 20 : 28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(compact ? 14 : 16),
          border: Border.all(color: _borderLight),
        ),
        child: const Text(
          'Aucune facture ne correspond aux filtres actifs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    if (useTable) {
      return _buildFacturesTable(visible, compact: compact);
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: _borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(compact ? 10 : 12),
        itemCount: visible.length,
        separatorBuilder: (_, __) => SizedBox(height: compact ? 8 : 10),
        itemBuilder: (context, index) => _buildFactureCard(visible[index]),
      ),
    );
  }

  Widget _buildFacturesTable(
    List<FactureModel> visible, {
    required bool compact,
  }) {
    return ColoredBox(
      color: _surface,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1080),
            child: DataTable(
              headingRowHeight: compact ? 48 : 52,
              dataRowMinHeight: compact ? 62 : 68,
              dataRowMaxHeight: compact ? 76 : 82,
              horizontalMargin: compact ? 10 : 14,
              columnSpacing: compact ? 16 : 22,
              dividerThickness: 0.8,
              headingRowColor: WidgetStatePropertyAll(
                _background.withValues(alpha: 0.92),
              ),
              headingTextStyle: TextStyle(
                color: _textSecondary,
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
              ),
              dataTextStyle: TextStyle(
                color: _textPrimary,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
              columns: const [
                DataColumn(label: Text('N FACTURE')),
                DataColumn(label: Text('CLIENT')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('COMMANDE')),
                DataColumn(label: Text('MONTANT')),
                DataColumn(label: Text('STATUT')),
                DataColumn(label: Text('ACTION')),
              ],
              rows: visible.map((facture) {
                final canMarkPayee = !_isPaid(facture.statut);
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          facture.referenceFactureClient,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 170,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              facture.clientNomComplet ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if ((facture.clientType ?? '').trim().isNotEmpty)
                              Text(
                                facture.clientType!,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(facture.dateFactureDisplay)),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          facture.commandeReference ??
                              (facture.commandeId == null
                                  ? '-'
                                  : '#${facture.commandeId}'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(_formatAmount(facture.montantTotal))),
                    DataCell(
                      _buildBadge(
                        _displayStatus(facture.statut),
                        _statusColor(facture.statut),
                        _statusColor(facture.statut).withValues(alpha: 0.12),
                      ),
                    ),
                    DataCell(
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'Details facture',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showFactureDetails(facture),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Exporter PDF',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _exportFacturePdf(facture),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                              size: 18,
                            ),
                          ),
                          if (canMarkPayee)
                            FilledButton.tonal(
                              onPressed: () => _markFacturePayee(facture),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                              ),
                              child: const Text('Payer'),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFactureCard(FactureModel facture) {
    final statusColor = _statusColor(facture.statut);
    final compact = AdaptiveSurface.isCompact(context, breakpoint: 430);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: _borderLight),
        boxShadow: AdaptiveSurface.shadow(
          context,
          breakpoint: 430,
          compactBlur: 9,
          compactOffsetY: 4,
          regularBlur: 14,
          regularOffsetY: 6,
          compactColor: const Color(0x08000000),
          regularColor: const Color(0x08000000),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: const Icon(Icons.description_outlined, color: _primary),
              ),
              SizedBox(width: compact ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facture.referenceFactureClient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: compact ? 3 : 4),
                    Text(
                      facture.dateFactureDisplay,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              _buildBadge(
                facture.statut,
                statusColor,
                statusColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 14),
          Wrap(
            spacing: compact ? 6 : 8,
            runSpacing: compact ? 6 : 8,
            children: [
              _InfoTile(
                icon: Icons.payments_outlined,
                label: 'Montant',
                value: _formatAmount(facture.montantTotal),
              ),
              _InfoTile(
                icon: Icons.shopping_cart_outlined,
                label: 'Commande',
                value: facture.commandeId == null
                    ? '-'
                    : '#${facture.commandeId}',
              ),
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Client',
                value: facture.clientId == null ? '-' : '#${facture.clientId}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFactureDetailRow({
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _loadFactures(showLoader: true),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    final visible = _visibleFactures;
    final compact = AdaptiveSurface.isCompact(context, breakpoint: 430);

    return RefreshIndicator(
      onRefresh: () => _loadFactures(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(visible),
            if (_refreshing) ...[
              SizedBox(height: compact ? 8 : 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            SizedBox(height: compact ? 10 : 12),
            _buildFacturesList(visible),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final compact = AdaptiveSurface.isCompact(context, breakpoint: 430);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
