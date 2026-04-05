import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invera_mobile/config/app_globals.dart';
import 'package:invera_mobile/core/ui/adaptive_layout.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/services/commande_service.dart';
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
        horizontal: _baseUnit * 1.25,
        vertical: _baseUnit * 0.65,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
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
        horizontal: _baseUnit * 1.25,
        vertical: _baseUnit * 0.8,
      ),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: _textSecondary, fontSize: 11.5),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
              ),
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
  final CommandeService _commandeService = CommandeService();
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
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
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
      final linkedOrdersCount = await _findLinkedOrdersCount(client.id);
      if (!mounted) return;

      if (linkedOrdersCount != null && linkedOrdersCount > 0) {
        await _showDeleteBlockedDialog(client, linkedOrdersCount);
        return;
      }

      await _clientService.deleteClient(client.id);
      await _loadClients();
      _showMessage('Client supprimé');
    } catch (e) {
      _showMessage(_clientDeleteErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<int?> _findLinkedOrdersCount(int clientId) async {
    try {
      final commandes = await _commandeService.getCommandes(clientId: clientId);
      return commandes.length;
    } catch (_) {
      return null;
    }
  }

  String _clientDeleteErrorMessage(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('commande_client') ||
        lower.contains('foreign key') ||
        lower.contains('toujours référence') ||
        lower.contains('toujours reference') ||
        lower.contains('viole la contrainte') ||
        lower.contains('23503')) {
      return 'Suppression impossible: ce client est lie a des commandes existantes.';
    }

    if (lower.contains('non trouvé') ||
        lower.contains('non trouve') ||
        lower.contains('not found')) {
      return 'Ce client n existe plus ou a deja ete supprime.';
    }

    if (lower.contains('403') ||
        lower.contains('401') ||
        lower.contains('forbidden') ||
        lower.contains('unauthorized')) {
      return 'Suppression refusee: vous n avez pas les droits necessaires.';
    }

    if (lower.contains('timeout') ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'Connexion impossible au serveur pendant la suppression du client.';
    }

    return raw.isEmpty ? 'Erreur lors de la suppression du client.' : raw;
  }

  Future<void> _showDeleteBlockedDialog(ClientModel client, int ordersCount) {
    final orderLabel = ordersCount > 1 ? 'commandes' : 'commande';
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suppression impossible'),
        content: Text(
          'Le client "${client.nom}" est rattache a $ordersCount $orderLabel. '
          'Il faut conserver ou traiter ses commandes avant de le supprimer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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

    final isCompactPage = MediaQuery.sizeOf(context).width < 760;

    if (isCompactPage) {
      return Container(
        color: _background,
        child: Scrollbar(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(isCompactPage: true)),
              if (_isBusy)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_clients.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(isCompactPage: true),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    _baseUnit * 1.5,
                    0,
                    _baseUnit * 1.5,
                    _baseUnit * 2,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final client = _clients[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: _baseUnit),
                        child: _buildClientCard(client),
                      );
                    }, childCount: _clients.length),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isCompactPage: false),
          if (_isBusy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _clients.isEmpty
                ? _buildEmptyState(isCompactPage: false)
                : _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isCompactPage}) {
    return Container(
      margin: EdgeInsets.all(isCompactPage ? _baseUnit * 1.25 : _baseUnit * 2),
      padding: EdgeInsets.all(isCompactPage ? _baseUnit * 1.25 : _baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(isCompactPage ? 16 : 20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: isCompactPage ? 14 : 20,
            offset: Offset(0, isCompactPage ? 6 : 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompactPage ? 34 : 44,
                height: isCompactPage ? 34 : 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(isCompactPage ? 10 : 12),
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
                    Text(
                      'Gestion des clients',
                      style: TextStyle(
                        fontSize: isCompactPage ? 15.5 : 18,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recherche et edition de votre portefeuille client.',
                      maxLines: isCompactPage ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: isCompactPage ? 11.5 : 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountPill(_clients.length),
              SizedBox(width: isCompactPage ? 4 : _baseUnit),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isBusy ? null : () => _loadClients(showBusy: true),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: BoxConstraints.tightFor(
                  width: isCompactPage ? 32 : 38,
                  height: isCompactPage ? 32 : 38,
                ),
                icon: Icon(Icons.refresh, size: isCompactPage ? 20 : 22),
              ),
            ],
          ),
          SizedBox(height: isCompactPage ? _baseUnit * 1.5 : _baseUnit * 2),
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 700;
              if (isCompact) {
                return Column(
                  children: [
                    _buildSearchBar(fullWidth: true),
                    const SizedBox(height: _baseUnit),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildCreateButton(
                        fullWidth: true,
                        isCompactPage: true,
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildSearchBar(fullWidth: false)),
                    const SizedBox(width: _baseUnit * 1.5),
                    _buildCreateButton(fullWidth: false, isCompactPage: false),
                  ],
                );
              }
            },
          ),
          if (_clientTypes.isNotEmpty) ...[
            SizedBox(height: isCompactPage ? _baseUnit * 1.5 : _baseUnit * 2),
            _buildTypeChips(),
          ],
        ],
      ),
    );
  }

  Widget _buildCountPill(int count) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.25,
        vertical: _baseUnit * 0.75,
      ),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSearchBar({required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 320,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          isDense: true,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton({
    required bool fullWidth,
    required bool isCompactPage,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : 176,
      child: ElevatedButton.icon(
        onPressed: _isBusy ? null : _onCreateClient,
        icon: Icon(Icons.add, size: isCompactPage ? 18 : 20),
        label: const Text('Nouveau client'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size(0, isCompactPage ? 42 : 44),
          padding: EdgeInsets.symmetric(
            horizontal: isCompactPage ? 14 : 16,
            vertical: isCompactPage ? 10 : 12,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: TextStyle(
            fontSize: isCompactPage ? 12.5 : 13,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => _onSelectType(null),
        ),
        ..._clientTypes.map(
          (t) => ChoiceChip(
            label: Text(ClientType.label(t)),
            selected: _selectedType == t,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => _onSelectType(t),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isCompactPage}) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isCompactPage ? _baseUnit * 3 : _baseUnit * 4),
        margin: EdgeInsets.all(isCompactPage ? _baseUnit * 1.5 : _baseUnit * 2),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(isCompactPage ? 16 : 20),
          border: Border.all(color: _borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: isCompactPage ? 52 : 64,
              color: _textSecondary,
            ),
            SizedBox(height: isCompactPage ? _baseUnit * 1.5 : _baseUnit * 2),
            Text(
              _query.isEmpty && _selectedType == null
                  ? 'Aucun client disponible'
                  : 'Aucun client trouvé',
              style: TextStyle(
                fontSize: isCompactPage ? 15 : 16,
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
            child: Scrollbar(
              child: ListView.separated(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                          ? _primary.withValues(alpha: 0.03)
                          : Colors.transparent,
                      child: ListTile(
                        onTap: _isBusy ? null : () => _onEditClient(client),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: _baseUnit * 2,
                          vertical: _baseUnit * 0.75,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                client.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                client.telephone,
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                client.email ?? '-',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12.5,
                                ),
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
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 108,
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
      if (hovering) {
        c.forward();
      } else {
        c.reverse();
      }
      return c;
    });
    if (hovering) {
      _rowHoverControllers[index]!.forward();
    } else {
      _rowHoverControllers[index]!.reverse();
    }
  }

  Widget _buildClientMetaRow(IconData icon, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: _textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 11.8,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(ClientModel client) {
    final email = (client.email ?? '').trim();
    final address = (client.adresse ?? '').trim();
    final actionStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
    );

    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isBusy ? null : () => _onEditClient(client),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(_baseUnit * 1.25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderLight),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
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
                          client.nom,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.telephone,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: _clientTypeLabel(client.typeClient),
                    color: _clientTypeColor(client.typeClient),
                  ),
                ],
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildClientMetaRow(Icons.email_outlined, email),
              ],
              if (address.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildClientMetaRow(
                  Icons.location_on_outlined,
                  address,
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _isBusy ? null : () => _onEditClient(client),
                    icon: Icon(Icons.edit_outlined, color: _primary, size: 18),
                    label: const Text('Modifier'),
                    style: actionStyle,
                  ),
                  TextButton.icon(
                    onPressed: _isBusy ? null : () => _onDeleteClient(client),
                    icon: Icon(Icons.delete_outline, color: _error, size: 18),
                    label: const Text('Supprimer'),
                    style: actionStyle.copyWith(
                      foregroundColor: const WidgetStatePropertyAll(_error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCards() {
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
    for (var c in _rowHoverControllers.values) {
      c.dispose();
    }
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
        isDense: true,
        prefixIcon: Icon(icon),
        prefixIconColor: _primary,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        filled: true,
        fillColor: _background,
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 12.5),
        floatingLabelStyle: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w700,
        ),
        alignLabelWithHint: maxLines > 1,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _baseUnit * 1.5,
          vertical: maxLines > 1 ? _baseUnit * 1.5 : _baseUnit * 1.25,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            _nomCtrl,
            'Nom',
            Icons.person_outline,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.25),
          _buildTextField(
            _telCtrl,
            'Telephone',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.25),
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
          SizedBox(height: _baseUnit * 1.25),
          _buildTextField(
            _addrCtrl,
            'Adresse',
            Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) => v!.isEmpty ? 'Requis' : null,
          ),
          SizedBox(height: _baseUnit * 1.25),
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
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
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

  Widget _buildFormHeader({required String title, required bool isCompact}) {
    final subtitle = _isEditing
        ? 'Mettez a jour les coordonnees et le type du client.'
        : 'Ajoutez un client avec une fiche plus propre et plus compacte.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isCompact ? 42 : 46,
          height: isCompact ? 42 : 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_primary, _primaryDark]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            _isEditing ? Icons.person_outline : Icons.person_add_alt_1_outlined,
            color: Colors.white,
          ),
        ),
        SizedBox(width: _baseUnit * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 18,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: isCompact ? 12 : 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations client',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nom, contact et adresse principale.',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
          SizedBox(height: _baseUnit * 1.75),
          _buildForm(),
        ],
      ),
    );
  }

  Widget buildFormActions({required bool isCompact}) {
    final cancelButton = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text('Annuler'),
    );

    final submitButton = ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(0, isCompact ? 38 : 40),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14 : 16,
          vertical: isCompact ? 10 : 12,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(_isEditing ? 'Modifier' : 'Creer'),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          submitButton,
          SizedBox(height: _baseUnit),
          cancelButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        cancelButton,
        SizedBox(width: _baseUnit),
        submitButton,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Modifier client' : 'Nouveau client';
    final availableHeight = MediaQuery.sizeOf(context).height;

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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(28),
            ),
            child: SizedBox(
              height: availableHeight * 0.82,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _baseUnit * 2,
                  _baseUnit * 1.25,
                  _baseUnit * 2,
                  _baseUnit * 2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _borderLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    SizedBox(height: _baseUnit * 1.5),
                    _buildFormHeader(title: title, isCompact: true),
                    SizedBox(height: _baseUnit * 1.5),
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: _buildFormCard(),
                        ),
                      ),
                    ),
                    SizedBox(height: _baseUnit * 1.5),
                    buildFormActions(isCompact: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: EdgeInsets.fromLTRB(
        _baseUnit * 3,
        _baseUnit * 3,
        _baseUnit * 3,
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        _baseUnit * 3,
        _baseUnit * 2,
        _baseUnit * 3,
        0,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        _baseUnit * 3,
        0,
        _baseUnit * 3,
        _baseUnit * 3,
      ),
      title: _buildFormHeader(title: title, isCompact: false),
      content: SizedBox(
        width: AdaptiveLayout.dialogWidth(context, max: 560, sideMargin: 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * 0.62),
          child: Scrollbar(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: _buildFormCard(),
            ),
          ),
        ),
      ),
      actions: [buildFormActions(isCompact: false)],
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
