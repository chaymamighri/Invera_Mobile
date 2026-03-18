import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_globals.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
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
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
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
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
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
  State<CommercialClientsSection> createState() =>
      _CommercialClientsSectionState();
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
            .map((e) => ClientType.normalize(e, fallbackToDefault: true))
            .where(ClientType.isAllowed)
            .toSet()
            .toList();
        _clientTypes.sort(
          (a, b) =>
              ClientType.sortWeight(a).compareTo(ClientType.sortWeight(b)),
        );
        if (_clientTypes.isEmpty) {
          _clientTypes = List<String>.from(ClientType.allowedValues);
        }
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
      final textQuery = _query.trim();
      final clients = await _clientService.getClients(
        query: textQuery.isEmpty ? null : textQuery,
      );

      final selectedType = ClientType.normalize(_selectedType);
      final filtered = selectedType.isEmpty
          ? clients
          : clients.where((client) {
              final clientType = ClientType.normalize(
                client.typeClient,
                fallbackToDefault: true,
              );
              return clientType == selectedType;
            }).toList();

      if (!mounted) return;
      setState(() {
        _clients = filtered;
        _sortClients();
      });
    } catch (e) {
      if (mounted) _showMessage(e.toString(), isError: true);
    } finally {
      if (showBusy && mounted) setState(() => _isBusy = false);
    }
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
        _clients.sort(
          (a, b) =>
              _sortAscending ? a.nom.compareTo(b.nom) : b.nom.compareTo(a.nom),
        );
        break;
      case 1: // type
        _clients.sort((a, b) {
          final at = ClientType.sortWeight(a.typeClient);
          final bt = ClientType.sortWeight(b.typeClient);
          return _sortAscending ? at.compareTo(bt) : bt.compareTo(at);
        });
        break;
      case 2: // phone
        _clients.sort(
          (a, b) => _sortAscending
              ? a.telephone.compareTo(b.telephone)
              : b.telephone.compareTo(a.telephone),
        );
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
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);

    setState(() => _isBusy = true);
    try {
      final exists = await _clientService.checkTelephoneExists(
        payload.telephone,
      );
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
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);

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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
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
    {
      final useBottomSheet = MediaQuery.of(context).size.width < 600;

      if (useBottomSheet) {
        return showModalBottomSheet<NouveauClientPayload>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _ClientFormSurface(
            initialClient: initialClient,
            clientTypes: _clientTypes,
            isBottomSheet: true,
          ),
        );
      }

      return showDialog<NouveauClientPayload>(
        context: context,
        builder: (_) => _ClientFormSurface(
          initialClient: initialClient,
          clientTypes: _clientTypes,
          isBottomSheet: false,
        ),
      );
    }

    /*
    final isEditing = initialClient != null;
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: initialClient?.nom ?? '');
    final telCtrl = TextEditingController(text: initialClient?.telephone ?? '');
    final emailCtrl = TextEditingController(text: initialClient?.email ?? '');
    final addrCtrl = TextEditingController(text: initialClient?.adresse ?? '');
    var selectedClientType = isEditing
        ? ClientType.normalize(
            initialClient?.typeClient,
            fallbackToDefault: true,
          )
        : ClientType.particulier;

    // Decide on presentation: bottom sheet for small screens, dialog for larger
    final isSmall = MediaQuery.of(context).size.width < 600;

    Widget buildForm(StateSetter setModalState) {
      return Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              nomCtrl,
              'Nom',
              Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(
              telCtrl,
              'Téléphone',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(
              emailCtrl,
              'Email',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) return 'Requis';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                  return 'Invalide';
                return null;
              },
            ),
            SizedBox(height: _baseUnit * 1.5),
            _buildTextField(
              addrCtrl,
              'Adresse',
              Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            SizedBox(height: _baseUnit * 1.5),
            if (isEditing) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Type client',
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: _baseUnit),
              Wrap(
                spacing: _baseUnit,
                runSpacing: _baseUnit,
                children:
                    (_clientTypes.isEmpty
                            ? ClientType.allowedValues
                            : _clientTypes)
                        .map((type) {
                  final normalizedType = ClientType.normalize(
                    type,
                    fallbackToDefault: true,
                  );
                  return ChoiceChip(
                    label: Text(ClientType.label(normalizedType)),
                    selected: selectedClientType == normalizedType,
                    onSelected: (_) {
                      setModalState(() {
                        selectedClientType = normalizedType;
                      });
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: _baseUnit),
              Text(
                'Un client est cree comme Particulier par defaut. Ici vous pouvez le faire evoluer vers VIP, Fidel ou Entreprise.',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(_baseUnit * 1.5),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderLight),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, color: _primary),
                    SizedBox(width: _baseUnit),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Type client initial',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Particulier',
                            style: TextStyle(color: _textSecondary),
                          ),
                        ],
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

    Future<NouveauClientPayload?> showDialogOrSheet() {
      if (isSmall) {
        return showModalBottomSheet<NouveauClientPayload>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: _baseUnit * 2,
              right: _baseUnit * 2,
              top: _baseUnit * 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Modifier client' : 'Nouveau client',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: _baseUnit * 2),
                buildForm(setModalState),
                SizedBox(height: _baseUnit * 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler'),
                    ),
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
                            typeClient: selectedClientType,
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
        ),
        );
      } else {
        return showDialog<NouveauClientPayload>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) => AlertDialog(
            title: Text(isEditing ? 'Modifier client' : 'Nouveau client'),
            content: SizedBox(
              width: AdaptiveLayout.dialogWidth(ctx, max: 560, sideMargin: 16),
              child: SingleChildScrollView(child: buildForm(setModalState)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
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
                      typeClient: selectedClientType,
                    ),
                  );
                },
                child: Text(isEditing ? 'Modifier' : 'Créer'),
              ),
            ],
          ),
        ),
      );
      }
    }

    return showDialogOrSheet().whenComplete(() {
      nomCtrl.dispose();
      telCtrl.dispose();
      emailCtrl.dispose();
      addrCtrl.dispose();
    });
    */
  }

  String _clientTypeLabel(String? raw) {
    return ClientType.label(raw, fallbackToDefault: true);
  }

  Color _clientTypeColor(String? raw) {
    switch (ClientType.normalize(raw, fallbackToDefault: true)) {
      case ClientType.vip:
        return const Color(0xFF7C3AED);
      case ClientType.fidel:
        return _accent;
      case ClientType.entreprise:
        return const Color(0xFFEA580C);
      case ClientType.particulier:
      default:
        return _primary;
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    final messenger = appScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? _error : _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Réessayer'),
            ),
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
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: _baseUnit * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des clients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
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
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSearch,
                ),
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
            label: Text(ClientType.label(t)),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
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
            padding: EdgeInsets.symmetric(
              horizontal: _baseUnit * 2,
              vertical: _baseUnit * 1.5,
            ),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _buildSortableHeader('Nom', 0, flex: 2),
                _buildSortableHeader('Téléphone', 2, flex: 2),
                _buildSortableHeader('Email', 3, flex: 3),
                _buildSortableHeader('Type', 1, flex: 2),
                Expanded(
                  flex: 4,
                  child: _buildSortableHeader('Adresse', -1, disableSort: true),
                ),
                const SizedBox(width: 120, child: _TableHeader('Actions')),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderLight),
          Expanded(
            child: ListView.separated(
              itemCount: _clients.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: _borderLight),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: _baseUnit * 2,
                        vertical: _baseUnit,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              client.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              client.telephone,
                              style: TextStyle(color: _textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              client.email ?? '-',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _StatusChip(
                              label: _clientTypeLabel(client.typeClient),
                              color: _clientTypeColor(client.typeClient),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              client.adresse ?? '-',
                              style: TextStyle(color: _textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Modifier',
                                  onPressed: _isBusy
                                      ? null
                                      : () => _onEditClient(client),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: _primary,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Supprimer',
                                  onPressed: _isBusy
                                      ? null
                                      : () => _onDeleteClient(client),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: _error,
                                  ),
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

  Widget _buildSortableHeader(
    String label,
    int columnIndex, {
    int flex = 1,
    bool disableSort = false,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: disableSort ? null : () => _onSort(columnIndex),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textSecondary,
              ),
            ),
            if (!disableSort && _sortColumnIndex == columnIndex)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: _primary,
              ),
          ],
        ),
      ),
    );
  }

  void _setHover(int index, bool hovering) {
    _rowHoverControllers.putIfAbsent(index, () {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      );
      if (hovering)
        c.forward();
      else
        c.reverse();
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
                      child: Text(
                        client.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _StatusChip(
                      label: _clientTypeLabel(client.typeClient),
                      color: _clientTypeColor(client.typeClient),
                    ),
                  ],
                ),
                const SizedBox(height: _baseUnit * 1.5),
                _InfoBadge(label: 'Tél', value: client.telephone),
                const SizedBox(height: _baseUnit),
                _InfoBadge(label: 'Email', value: client.email ?? '-'),
                const SizedBox(height: _baseUnit),
                _InfoBadge(label: 'Adresse', value: client.adresse ?? '-'),
                const SizedBox(height: _baseUnit * 1.5),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: _baseUnit,
                  runSpacing: _baseUnit,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isBusy ? null : () => _onEditClient(client),
                      icon: Icon(Icons.edit_outlined, color: _primary),
                      label: const Text('Modifier'),
                    ),
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

class _ClientFormSurface extends StatefulWidget {
  final ClientModel? initialClient;
  final List<String> clientTypes;
  final bool isBottomSheet;

  const _ClientFormSurface({
    required this.initialClient,
    required this.clientTypes,
    required this.isBottomSheet,
  });

  @override
  State<_ClientFormSurface> createState() => _ClientFormSurfaceState();
}

class _ClientFormSurfaceState extends State<_ClientFormSurface> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addrCtrl;
  late String _selectedClientType;

  bool get _isEditing => widget.initialClient != null;

  List<String> get _availableTypes {
    final source = widget.clientTypes.isEmpty
        ? ClientType.allowedValues
        : widget.clientTypes;

    return source
        .map((type) => ClientType.normalize(type, fallbackToDefault: true))
        .where(ClientType.isAllowed)
        .toSet()
        .toList()
      ..sort(
        (a, b) => ClientType.sortWeight(a).compareTo(ClientType.sortWeight(b)),
      );
  }

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.initialClient?.nom ?? '');
    _telCtrl = TextEditingController(
      text: widget.initialClient?.telephone ?? '',
    );
    _emailCtrl = TextEditingController(text: widget.initialClient?.email ?? '');
    _addrCtrl = TextEditingController(
      text: widget.initialClient?.adresse ?? '',
    );
    _selectedClientType = _isEditing
        ? ClientType.normalize(
            widget.initialClient?.typeClient,
            fallbackToDefault: true,
          )
        : ClientType.particulier;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _addrCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      NouveauClientPayload(
        nom: _nomCtrl.text,
        telephone: _telCtrl.text,
        email: _emailCtrl.text,
        adresse: _addrCtrl.text,
        typeClient: _selectedClientType,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(
            _nomCtrl,
            'Nom',
            Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.5),
          _buildTextField(
            _telCtrl,
            'TÃ©lÃ©phone',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.5),
          _buildTextField(
            _emailCtrl,
            'Email',
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Invalide';
              }
              return null;
            },
          ),
          SizedBox(height: _baseUnit * 1.5),
          _buildTextField(
            _addrCtrl,
            'Adresse',
            Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.5),
          if (_isEditing) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Type client',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: _baseUnit),
            Wrap(
              spacing: _baseUnit,
              runSpacing: _baseUnit,
              children: _availableTypes.map((type) {
                return ChoiceChip(
                  label: Text(ClientType.label(type)),
                  selected: _selectedClientType == type,
                  onSelected: (_) {
                    setState(() {
                      _selectedClientType = type;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: _baseUnit),
            Text(
              'Un client est cree comme Particulier par defaut. Ici vous pouvez le faire evoluer vers VIP, Fidel ou Entreprise.',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_baseUnit * 1.5),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined, color: _primary),
                  SizedBox(width: _baseUnit),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Type client initial',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Particulier',
                          style: TextStyle(color: _textSecondary),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Modifier client' : 'Nouveau client';

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: _baseUnit * 2,
          right: _baseUnit * 2,
          top: _baseUnit * 2,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: _baseUnit * 2),
                _buildForm(),
                SizedBox(height: _baseUnit * 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Modifier' : 'CrÃ©er'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: AdaptiveLayout.dialogWidth(context, max: 560, sideMargin: 16),
        child: SingleChildScrollView(child: _buildForm()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Modifier' : 'CrÃ©er'),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _textSecondary,
      ),
    );
  }
}
