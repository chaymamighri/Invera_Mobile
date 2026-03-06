import 'package:flutter/material.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/models/commande_model.dart';
import 'package:invera_mobile/services/client_service.dart';
import 'package:invera_mobile/services/commande_service.dart';

// ---------- THEME CONSTANTS ----------
const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _accent = Color(0xFF0CAE4A);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _borderLight = Color(0xFFE6EAF2);
const Color _success = Color(0xFF0CAE4A);
const Color _error = Color(0xFFB42318);
const double _baseUnit = 8.0;

// ---------- REUSABLE WIDGETS ----------
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toUpperCase();
    late Color bg, fg;
    if (normalized == 'CONFIRMEE') {
      bg = const Color(0xFFE9F8EF);
      fg = const Color(0xFF11853F);
    } else if (normalized == 'ANNULEE') {
      bg = const Color(0xFFFFE8E8);
      fg = const Color(0xFFB42318);
    } else {
      bg = const Color(0xFFEFF4FF);
      fg = _primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  String _displayStatus(String raw) {
    final norm = raw.trim().toUpperCase();
    if (norm == 'EN_ATTENTE') return 'En attente';
    if (norm == 'CONFIRMEE') return 'Confirmée';
    if (norm == 'ANNULEE') return 'Annulée';
    return raw;
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: _textSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------- MAIN SECTION ----------
class CommercialCommandesSection extends StatefulWidget {
  const CommercialCommandesSection({super.key});

  @override
  State<CommercialCommandesSection> createState() => _CommercialCommandesSectionState();
}

class _CommercialCommandesSectionState extends State<CommercialCommandesSection> {
  final CommandeService _commandeService = CommandeService();
  final ClientService _clientService = ClientService();

  List<CommandeModel> _commandes = [];
  List<ClientModel> _clients = [];
  List<ProduitOption> _produits = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  String _statusFilter = 'TOUS';
  int _draftLineSeed = 0;
  bool _useGrid = false;

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
        _commandes = results[0] as List<CommandeModel>;
        _clients = results[1] as List<ClientModel>;
        _produits = results[2] as List<ProduitOption>;
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
    if (showBusy && mounted) setState(() => _isBusy = true);

    try {
      final statut = _statusFilter == 'TOUS' ? null : _statusFilter;
      final data = await _commandeService.getCommandes(statut: statut);
      if (!mounted) return;
      setState(() => _commandes = data);
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (showBusy && mounted) setState(() => _isBusy = false);
    }
  }

  // CRUD operations (simplified, same as before)
  Future<void> _onCreate() async {
    // ... (identical to previous version, omitted for brevity)
  }

  Future<void> _onEdit(CommandeModel cmd) async {
    // ... (identical)
  }

  Future<void> _onCancel(CommandeModel cmd) async {
    // ... (identical)
  }

  Future<void> _onDetails(CommandeModel cmd) async {
    // ... (identical)
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? _error : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _setFilter(String status) {
    setState(() => _statusFilter = status);
    _reloadCommandes(showBusy: true);
  }

  // ---------- UI ----------
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
            Icon(Icons.error_outline, color: _error, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: _error)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadInitialData, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return Container(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            commandes: _commandes,
            isBusy: _isBusy,
            statusFilter: _statusFilter,
            onFilterChanged: _setFilter,
            onRefresh: () => _reloadCommandes(showBusy: true),
            onCreate: _onCreate,
            useGrid: _useGrid,
            onToggleView: () => setState(() => _useGrid = !_useGrid),
          ),
          if (_isBusy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _commandes.isEmpty
                ? _EmptyState(isBusy: _isBusy, onCreate: _onCreate)
                : _CommandesList(
                    commandes: _commandes,
                    isBusy: _isBusy,
                    useGrid: _useGrid,
                    onDetails: _onDetails,
                    onEdit: _onEdit,
                    onCancel: _onCancel,
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- DECOUPAGE ----------
class _Header extends StatelessWidget {
  final List<CommandeModel> commandes;
  final bool isBusy;
  final String statusFilter;
  final void Function(String) onFilterChanged;
  final VoidCallback onRefresh;
  final VoidCallback onCreate;
  final bool useGrid;
  final VoidCallback onToggleView;

  const _Header({
    required this.commandes,
    required this.isBusy,
    required this.statusFilter,
    required this.onFilterChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.useGrid,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final pending = commandes.where((c) => c.statut.toUpperCase() == 'EN_ATTENTE').length;
    final confirmed = commandes.where((c) => c.statut.toUpperCase() == 'CONFIRMEE').length;
    final cancelled = commandes.where((c) => c.statut.toUpperCase() == 'ANNULEE').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_primary, _primaryDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Gestion des commandes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary),
                ),
              ),
              _CountPill(count: commandes.length),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: isBusy ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryCard(
                label: 'Total',
                value: commandes.length.toString(),
                color: _primary,
                icon: Icons.shopping_bag_outlined,
                onTap: () => onFilterChanged('TOUS'),
              ),
              _SummaryCard(
                label: 'En attente',
                value: pending.toString(),
                color: _primary,
                icon: Icons.timelapse_outlined,
                onTap: () => onFilterChanged('EN_ATTENTE'),
              ),
              _SummaryCard(
                label: 'Confirmées',
                value: confirmed.toString(),
                color: _success,
                icon: Icons.verified_outlined,
                onTap: () => onFilterChanged('CONFIRMEE'),
              ),
              _SummaryCard(
                label: 'Annulées',
                value: cancelled.toString(),
                color: _error,
                icon: Icons.cancel_outlined,
                onTap: () => onFilterChanged('ANNULEE'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              if (isCompact) {
                return Column(
                  children: [
                    _StatusFilter(
                      statuses: const ['TOUS', 'EN_ATTENTE', 'CONFIRMEE', 'ANNULEE'],
                      currentFilter: statusFilter,
                      onChanged: onFilterChanged,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CreateOrderButton(onPressed: onCreate, isBusy: isBusy),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(useGrid ? Icons.view_list : Icons.grid_view),
                          onPressed: onToggleView,
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: _StatusFilter(
                        statuses: const ['TOUS', 'EN_ATTENTE', 'CONFIRMEE', 'ANNULEE'],
                        currentFilter: statusFilter,
                        onChanged: onFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _CreateOrderButton(onPressed: onCreate, isBusy: isBusy),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(useGrid ? Icons.view_list : Icons.grid_view),
                      onPressed: onToggleView,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Text('$count', style: TextStyle(color: _primary, fontWeight: FontWeight.w800)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 130),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _textPrimary)),
                Text(label, style: TextStyle(color: _textSecondary, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final List<String> statuses;
  final String currentFilter;
  final void Function(String) onChanged;

  const _StatusFilter({
    required this.statuses,
    required this.currentFilter,
    required this.onChanged,
  });

  String _display(String s) {
    if (s == 'TOUS') return 'Tous';
    if (s == 'EN_ATTENTE') return 'En attente';
    if (s == 'CONFIRMEE') return 'Confirmée';
    if (s == 'ANNULEE') return 'Annulée';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: statuses.map((s) => ButtonSegment(value: s, label: Text(_display(s)))).toList(),
      selected: {currentFilter},
      onSelectionChanged: (Set<String> newSelection) => onChanged(newSelection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primary;
          return _surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return _textPrimary;
        }),
      ),
    );
  }
}

class _CreateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isBusy;
  const _CreateOrderButton({required this.onPressed, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isBusy ? null : onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Nouvelle commande'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onCreate;
  const _EmptyState({required this.isBusy, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: _textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Aucune commande disponible',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première commande en cliquant sur le bouton ci-dessous.',
              style: TextStyle(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Créer une commande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandesList extends StatelessWidget {
  final List<CommandeModel> commandes;
  final bool isBusy;
  final bool useGrid;
  final Future<void> Function(CommandeModel) onDetails;
  final Future<void> Function(CommandeModel) onEdit;
  final Future<void> Function(CommandeModel) onCancel;

  const _CommandesList({
    required this.commandes,
    required this.isBusy,
    required this.useGrid,
    required this.onDetails,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (useGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemCount: commandes.length,
        itemBuilder: (context, index) => _OrderCard(
          commande: commandes[index],
          isBusy: isBusy,
          grid: true,
          onDetails: onDetails,
          onEdit: onEdit,
          onCancel: onCancel,
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commandes.length,
        itemExtent: 200, // hauteur approximative d'une carte en mode liste
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OrderCard(
            commande: commandes[index],
            isBusy: isBusy,
            grid: false,
            onDetails: onDetails,
            onEdit: onEdit,
            onCancel: onCancel,
          ),
        ),
      );
    }
  }
}

class _OrderCard extends StatelessWidget {
  final CommandeModel commande;
  final bool isBusy;
  final bool grid;
  final Future<void> Function(CommandeModel) onDetails;
  final Future<void> Function(CommandeModel) onEdit;
  final Future<void> Function(CommandeModel) onCancel;

  const _OrderCard({
    required this.commande,
    required this.isBusy,
    required this.grid,
    required this.onDetails,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _borderLight),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onDetails(commande),
        hoverColor: _primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      commande.referenceCommandeClient,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusChip(status: commande.statut),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoBadge(label: 'Client', value: commande.client?.fullName ?? '-'),
                  _InfoBadge(label: 'Date', value: commande.dateCommandeFormatted),
                  _InfoBadge(label: 'Total', value: '${commande.total.toStringAsFixed(2)} DT'),
                ],
              ),
              const SizedBox(height: 12),
              // Product preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _productsPreview(commande),
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!grid) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => onDetails(commande),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Détails'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: (!isBusy && commande.canEdit) ? () => onEdit(commande) : null,
                      icon: Icon(Icons.edit_outlined, color: _primary),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: (!isBusy && commande.canCancel) ? () => onCancel(commande) : null,
                      icon: Icon(Icons.cancel_outlined, color: _error),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(foregroundColor: _error),
                    ),
                  ],
                ),
              ] else ...[
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      tooltip: 'Détails',
                      onPressed: () => onDetails(commande),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: (!isBusy && commande.canEdit) ? () => onEdit(commande) : null,
                      icon: Icon(Icons.edit_outlined, color: _primary),
                    ),
                    IconButton(
                      tooltip: 'Annuler',
                      onPressed: (!isBusy && commande.canEdit) ? () => onCancel(commande) : null,
                      icon: Icon(Icons.cancel_outlined, color: _error),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _productsPreview(CommandeModel cmd) {
    if (cmd.produits.isEmpty) return 'Aucun produit';
    final names = cmd.produits.map((p) => p.libelle).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names[0]} + ${names[1]} + ${names.length - 2} autres';
  }
}