import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/services/client_service.dart';

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

// ---------- HELPER WIDGETS ----------
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _baseUnit * 1.5, vertical: _baseUnit),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _baseUnit * 1.5, vertical: _baseUnit),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- MAIN SECTION ----------
class CommercialClientsSection extends StatefulWidget {
  const CommercialClientsSection({super.key});

  @override
  State<CommercialClientsSection> createState() => _CommercialClientsSectionState();
}

class _CommercialClientsSectionState extends State<CommercialClientsSection>
    with TickerProviderStateMixin {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  List<ClientModel> _clients = [];
  List<String> _clientTypes = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  String _query = '';
  String? _selectedType;
  Timer? _searchDebounce;

  // Sorting
  bool _sortAscending = true;
  int _sortColumnIndex = 0; // 0 = name, 1 = type, 2 = phone, 3 = email

  // Animation controllers for hover effects (optional, can be omitted)
  late AnimationController _hoverController;
  final Map<int, AnimationController> _rowHoverControllers = {};

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _clientService.getClients(),
        _clientService.getClientTypes(),
      ]);

      if (!mounted) return;
      setState(() {
        _clients = (results[0] as List<ClientModel>);
        _clientTypes = (results[1] as List<String>)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _isLoading = false;
        _sortClients(); // apply default sort
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadClients({bool showBusy = false}) async {
    if (showBusy && mounted) setState(() => _isBusy = true);

    try {
      final clients = await _clientService.getClients(query: _composeQuery());
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _sortClients();
      });
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (showBusy && mounted) setState(() => _isBusy = false);
    }
  }

  String _composeQuery() {
    final q = _query.trim();
    final t = (_selectedType ?? '').trim();
    if (q.isEmpty && t.isEmpty) return '';
    if (q.isEmpty) return t;
    if (t.isEmpty) return q;
    return '$q $t';
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _query = _searchController.text.trim();
      _loadClients(showBusy: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _query = '';
    _loadClients(showBusy: true);
  }

  void _onSelectType(String? type) {
    setState(() => _selectedType = type);
    _loadClients(showBusy: true);
  }

  // Sorting logic
  void _sortClients() {
    switch (_sortColumnIndex) {
      case 0: // name
        _clients.sort((a, b) => _sortAscending
            ? a.nom.compareTo(b.nom)
            : b.nom.compareTo(a.nom));
        break;
      case 1: // type
        _clients.sort((a, b) {
          final at = a.typeClient ?? '';
          final bt = b.typeClient ?? '';
          return _sortAscending ? at.compareTo(bt) : bt.compareTo(at);
        });
        break;
      case 2: // phone
        _clients.sort((a, b) => _sortAscending
            ? a.telephone.compareTo(b.telephone)
            : b.telephone.compareTo(a.telephone));
        break;
      case 3: // email
        _clients.sort((a, b) {
          final ae = a.email ?? '';
          final be = b.email ?? '';
          return _sortAscending ? ae.compareTo(be) : be.compareTo(ae);
        });
        break;
    }
  }

  void _onSort(int columnIndex) {
    if (_sortColumnIndex == columnIndex) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumnIndex = columnIndex;
      _sortAscending = true;
    }
    _sortClients();
    setState(() {});
  }

  // CRUD operations (unchanged from original but with improved UI feedback)
  Future<void> _onCreateClient() async {
    final payload = await _openClientForm();
    if (payload == null) return;

    setState(() => _isBusy = true);
    try {
      final exists = await _clientService.checkTelephoneExists(payload.telephone);
      if (exists) {
        _showMessage('Ce numéro est déjà utilisé.', isError: true);
        return;
      }
      await _clientService.createClient(payload);
      await _loadClients();
      _showMessage('Client créé avec succès');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onEditClient(ClientModel client) async {
    final payload = await _openClientForm(initialClient: client);
    if (payload == null) return;

    setState(() => _isBusy = true);
    try {
      await _clientService.updateClient(client.id, payload);
      await _loadClients();
      _showMessage('Client modifié');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onDeleteClient(ClientModel client) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer client'),
        content: Text('Confirmer la suppression de "${client.nom}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isBusy = true);
    try {
      await _clientService.deleteClient(client.id);
      await _loadClients();
      _showMessage('Client supprimé');
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // Improved client form (dialog or bottom sheet based on screen size)
  Future<NouveauClientPayload?> _openClientForm({ClientModel? initialClient}) {
    final isEditing = initialClient != null;
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: initialClient?.nom ?? '');
    final telCtrl = TextEditingController(text: initialClient?.telephone ?? '');
    final emailCtrl = TextEditingController(text: initialClient?.email ?? '');
    final addrCtrl = TextEditingController(text: initialClient?.adresse ?? '');
    final typeCtrl = TextEditingController(
      text: initialClient?.typeClient ?? (_clientTypes.isNotEmpty ? _clientTypes.first : ''),
    );

    // Decide on presentation: bottom sheet for small screens, dialog for larger
    final isSmall = MediaQuery.of(context).size.width < 600;

    Widget buildForm() {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nomCtrl, 'Nom', Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Requis' : null),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(telCtrl, 'Téléphone', Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Requis' : null),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(emailCtrl, 'Email', Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Requis';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Invalide';
                  return null;
                }),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(addrCtrl, 'Adresse', Icons.location_on_outlined,
                maxLines: 2, validator: (v) => v!.isEmpty ? 'Requis' : null),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(typeCtrl, 'Type client', Icons.category_outlined,
                validator: (v) {
                  if (v!.isEmpty) return 'Requis';
                  if (_clientTypes.isNotEmpty) {
                    final allowed = _clientTypes.map((e) => e.trim().toUpperCase()).toSet();
                    if (!allowed.contains(v.trim().toUpperCase())) {
                      return 'Utilisez: ${allowed.join(', ')}';
                    }
                  }
                  return null;
                }),
            if (_clientTypes.isNotEmpty) ...[
              SizedBox(height: _baseUnit * 2),
              Wrap(
                spacing: _baseUnit,
                runSpacing: _baseUnit,
                children: _clientTypes.map((type) {
                  final isSelected = typeCtrl.text.trim().toUpperCase() == type.trim().toUpperCase();
                  return ChoiceChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) {
                      typeCtrl.text = type.trim().toUpperCase();
                      formKey.currentState?.validate();
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      );
    }

    Future<NouveauClientPayload?> showDialogOrSheet() {
      if (isSmall) {
        return showModalBottomSheet<NouveauClientPayload>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: _baseUnit * 2,
              right: _baseUnit * 2,
              top: _baseUnit * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? 'Modifier client' : 'Nouveau client',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: _baseUnit * 2),
                buildForm(),
                SizedBox(height: _baseUnit * 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(
                          ctx,
                          NouveauClientPayload(
                            nom: nomCtrl.text,
                            telephone: telCtrl.text,
                            email: emailCtrl.text,
                            adresse: addrCtrl.text,
                            typeClient: typeCtrl.text.trim().toUpperCase(),
                          ),
                        );
                      },
                      child: Text(isEditing ? 'Modifier' : 'Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return showDialog<NouveauClientPayload>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isEditing ? 'Modifier client' : 'Nouveau client'),
            content: SizedBox(width: 560, child: SingleChildScrollView(child: buildForm())),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(
                    ctx,
                    NouveauClientPayload(
                      nom: nomCtrl.text,
                      telephone: telCtrl.text,
                      email: emailCtrl.text,
                      adresse: addrCtrl.text,
                      typeClient: typeCtrl.text.trim().toUpperCase(),
                    ),
                  );
                },
                child: Text(isEditing ? 'Modifier' : 'Créer'),
              ),
            ],
          ),
        );
      }
    }

    return showDialogOrSheet().whenComplete(() {
      nomCtrl.dispose();
      telCtrl.dispose();
      emailCtrl.dispose();
      addrCtrl.dispose();
      typeCtrl.dispose();
    });
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error),
        ),
      ),
      validator: validator,
    );
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
            const SizedBox(height: _baseUnit * 2),
            Text(_errorMessage!, style: const TextStyle(color: _error)),
            const SizedBox(height: _baseUnit * 2),
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
          _buildHeader(),
          if (_isBusy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _clients.isEmpty ? _buildEmptyState() : _buildClientList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(_baseUnit * 2),
      padding: EdgeInsets.all(_baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
                child: const Icon(Icons.people_alt_outlined, color: Colors.white),
              ),
              const SizedBox(width: _baseUnit * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des clients',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recherchez, ajoutez, modifiez et supprimez vos clients.',
                      style: TextStyle(color: _textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _buildCountPill(_clients.length),
              const SizedBox(width: _baseUnit),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isBusy ? null : () => _loadClients(showBusy: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: _baseUnit * 2),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;
              if (isCompact) {
                return Column(
                  children: [
                    _buildSearchBar(fullWidth: true),
                    const SizedBox(height: _baseUnit),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _onCreateClient,
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau client'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildSearchBar(fullWidth: false)),
                    const SizedBox(width: _baseUnit * 1.5),
                    SizedBox(
                      width: 190,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _onCreateClient,
                        icon: const Icon(Icons.add),
                        label: const Text('Nouveau client'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          if (_clientTypes.isNotEmpty) ...[
            const SizedBox(height: _baseUnit * 2),
            _buildTypeChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildCountPill(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _baseUnit * 1.5, vertical: _baseUnit),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _primary.withOpacity(0.3)),
      ),
      child: Text(
        '$count',
        style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSearchBar({required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 340,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher (nom, téléphone, email...)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(icon: const Icon(Icons.close), onPressed: _clearSearch),
          filled: true,
          fillColor: _background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: _borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: _borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChips() {
    return Wrap(
      spacing: _baseUnit,
      runSpacing: _baseUnit,
      children: [
        ChoiceChip(
          label: const Text('Tous'),
          selected: _selectedType == null,
          onSelected: (_) => _onSelectType(null),
        ),
        ..._clientTypes.map(
          (t) => ChoiceChip(
            label: Text(t),
            selected: _selectedType == t,
            onSelected: (_) => _onSelectType(t),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(_baseUnit * 4),
        margin: EdgeInsets.all(_baseUnit * 2),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 64, color: _textSecondary),
            const SizedBox(height: _baseUnit * 2),
            Text(
              _query.isEmpty && _selectedType == null
                  ? 'Aucun client disponible'
                  : 'Aucun client trouvé',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary),
            ),
            const SizedBox(height: _baseUnit),
            Text(
              'Essayez un autre mot-clé ou ajoutez un nouveau client.',
              style: TextStyle(color: _textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: _baseUnit * 2),
            if (_query.isEmpty)
              ElevatedButton.icon(
                onPressed: _isBusy ? null : _onCreateClient,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un client'),
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

  Widget _buildClientList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return _buildCards();
        } else {
          return _buildTable();
        }
      },
    );
  }

  Widget _buildTable() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: _baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sortable header
          Container(
            padding: EdgeInsets.symmetric(horizontal: _baseUnit * 2, vertical: _baseUnit * 1.5),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _buildSortableHeader('Nom', 0, flex: 2),
                _buildSortableHeader('Téléphone', 2, flex: 2),
                _buildSortableHeader('Email', 3, flex: 3),
                _buildSortableHeader('Type', 1, flex: 2),
                Expanded(flex: 4, child: _buildSortableHeader('Adresse', -1, disableSort: true)),
                const SizedBox(width: 120, child: _TableHeader('Actions')),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderLight),
          Expanded(
            child: ListView.separated(
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: _borderLight),
              itemBuilder: (context, index) {
                final client = _clients[index];
                return MouseRegion(
                  onEnter: (_) => _setHover(index, true),
                  onExit: (_) => _setHover(index, false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _rowHoverControllers[index]?.value == 1.0
                        ? _primary.withOpacity(0.03)
                        : Colors.transparent,
                    child: ListTile(
                      onTap: _isBusy ? null : () => _onEditClient(client),
                      contentPadding: EdgeInsets.symmetric(horizontal: _baseUnit * 2, vertical: _baseUnit),
                      title: Row(
                        children: [
                          Expanded(flex: 2, child: Text(client.nom, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(flex: 2, child: Text(client.telephone, style: TextStyle(color: _textSecondary))),
                          Expanded(flex: 3, child: Text(client.email ?? '-', style: TextStyle(color: _textSecondary))),
                          Expanded(flex: 2, child: _StatusChip(label: client.typeClient ?? '-', color: _primary)),
                          Expanded(flex: 4, child: Text(client.adresse ?? '-', style: TextStyle(color: _textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Modifier',
                                  onPressed: _isBusy ? null : () => _onEditClient(client),
                                  icon: Icon(Icons.edit_outlined, color: _primary),
                                ),
                                IconButton(
                                  tooltip: 'Supprimer',
                                  onPressed: _isBusy ? null : () => _onDeleteClient(client),
                                  icon: Icon(Icons.delete_outline, color: _error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortableHeader(String label, int columnIndex, {int flex = 1, bool disableSort = false}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: disableSort ? null : () => _onSort(columnIndex),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: _textSecondary)),
            if (!disableSort && _sortColumnIndex == columnIndex)
              Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: _primary),
          ],
        ),
      ),
    );
  }

  void _setHover(int index, bool hovering) {
    _rowHoverControllers.putIfAbsent(index, () {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
      if (hovering) c.forward(); else c.reverse();
      return c;
    });
    if (hovering) {
      _rowHoverControllers[index]!.forward();
    } else {
      _rowHoverControllers[index]!.reverse();
    }
  }

  Widget _buildCards() {
    return ListView.builder(
      padding: EdgeInsets.all(_baseUnit * 2),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return Card(
          margin: EdgeInsets.only(bottom: _baseUnit * 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderLight),
          ),
          child: Padding(
            padding: EdgeInsets.all(_baseUnit * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(client.nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    _StatusChip(label: client.typeClient ?? '-', color: _primary),
                  ],
                ),
                const SizedBox(height: _baseUnit * 1.5),
                _InfoBadge(label: 'Tél', value: client.telephone),
                const SizedBox(height: _baseUnit),
                _InfoBadge(label: 'Email', value: client.email ?? '-'),
                const SizedBox(height: _baseUnit),
                _InfoBadge(label: 'Adresse', value: client.adresse ?? '-'),
                const SizedBox(height: _baseUnit * 1.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _onEditClient(client),
                      icon: Icon(Icons.edit_outlined, color: _primary),
                      label: const Text('Modifier'),
                    ),
                    const SizedBox(width: _baseUnit),
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _onDeleteClient(client),
                      icon: Icon(Icons.delete_outline, color: _error),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(foregroundColor: _error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _hoverController.dispose();
    for (var c in _rowHoverControllers.values) c.dispose();
    super.dispose();
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, color: _textSecondary),
    );
  }
}