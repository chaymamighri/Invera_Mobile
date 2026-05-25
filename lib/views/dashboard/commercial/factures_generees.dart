import 'package:flutter/material.dart';
import 'package:invera_mobile/models/facture.dart';
import 'package:invera_mobile/services/factures.dart';

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

  Widget _buildHeader(List<FactureModel> visible) {
    final refreshButton = OutlinedButton.icon(
      onPressed: _refreshing ? null : () => _loadFactures(showLoader: false),
      icon: _refreshing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh, color: Colors.white),
      label: const Text('Actualiser'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x80FFFFFF)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primary, _primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3A2D47C8),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Factures',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Liste des factures generees a partir des ventes validees.',
                    style: TextStyle(color: Color(0xFFE3EBFF), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        '${visible.length} factures',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                      _buildBadge(
                        'Montant visible: ${_formatAmount(_visibleTotal)}',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    refreshButton,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 16),
                  refreshButton,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Rechercher facture, statut, commande...',
            prefixIcon: const Icon(Icons.search),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFacturesList(List<FactureModel> visible) {
    if (visible.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight),
        ),
        child: const Text(
          'Aucune facture ne correspond aux filtres actifs.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSecondary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildFactureCard(visible[index]),
      ),
    );
  }

  Widget _buildFactureCard(FactureModel facture) {
    final statusColor = _statusColor(facture.statut);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined, color: _primary),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
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
              const SizedBox(width: 8),
              _buildBadge(
                facture.statut,
                statusColor,
                statusColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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

    return RefreshIndicator(
      onRefresh: () => _loadFactures(showLoader: false),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(visible),
            if (_refreshing) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
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
