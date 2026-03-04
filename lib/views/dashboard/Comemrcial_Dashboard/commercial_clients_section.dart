import 'dart:async';
import 'package:flutter/material.dart';
import 'package:invera_mobile/models/client_model.dart';
import 'package:invera_mobile/services/client_service.dart';

class CommercialClientsSection extends StatefulWidget {
  const CommercialClientsSection({super.key});

  @override
  State<CommercialClientsSection> createState() => _CommercialClientsSectionState();
}

class _CommercialClientsSectionState extends State<CommercialClientsSection> {
  final ClientService _clientService = ClientService();
  final TextEditingController _searchController = TextEditingController();

  final List<ClientModel> _clients = [];
  List<String> _clientTypes = [];

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;

  String _query = '';
  String? _selectedType;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(() {
      // keep suffix icon in sync
      if (mounted) setState(() {});
    });
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
        _clients
          ..clear()
          ..addAll((results[0] as List<ClientModel>));
        _clientTypes = (results[1] as List<String>)
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
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

  Future<void> _loadClients({bool showBusy = false}) async {
    if (showBusy && mounted) {
      setState(() => _isBusy = true);
    }

    try {
      final clients = await _clientService.getClients(query: _composeQuery());
      if (!mounted) return;

      setState(() {
        _clients
          ..clear()
          ..addAll(clients);
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (showBusy && mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  String _composeQuery() {
    final q = _query.trim();
    final t = (_selectedType ?? '').trim();
    if (q.isEmpty && t.isEmpty) return '';
    if (q.isEmpty) return t;
    if (t.isEmpty) return q;
    // Keep it simple: backend can ignore if it doesn't support
    return '$q $t';
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _query = value.trim();
      _loadClients(showBusy: true);
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _query = '';
    _loadClients(showBusy: true);
    setState(() {});
  }

  void _onSelectType(String? type) {
    setState(() {
      _selectedType = type;
    });
    _loadClients(showBusy: true);
  }

  Future<void> _onCreateClient() async {
    final payload = await _openClientForm();
    if (payload == null) return;

    setState(() => _isBusy = true);
    try {
      final phoneAlreadyExists = await _clientService.checkTelephoneExists(payload.telephone);
      if (phoneAlreadyExists) {
        _showMessage('Ce numéro de téléphone est déjà utilisé.', isError: true);
        return;
      }

      await _clientService.createClient(payload);
      await _loadClients();
      _showMessage('Client créé avec succès');
    } catch (e) {
      final raw = e.toString().replaceFirst('Exception: ', '');
      _showMessage(_friendlyCreateError(raw), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onEditClient(ClientModel client) async {
    if (client.id <= 0) {
      _showMessage('ID client invalide, modification impossible.', isError: true);
      return;
    }

    final payload = await _openClientForm(initialClient: client);
    if (payload == null) return;

    setState(() => _isBusy = true);
    try {
      await _clientService.updateClient(client.id, payload);
      await _loadClients();
      _showMessage('Client modifié avec succès');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onDeleteClient(ClientModel client) async {
    if (client.id <= 0) {
      _showMessage('ID client invalide, suppression impossible.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer client'),
          content: Text('Confirmer la suppression de "${client.nom}" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isBusy = true);
    try {
      await _clientService.deleteClient(client.id);
      await _loadClients();
      _showMessage('Client supprimé avec succès');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<NouveauClientPayload?> _openClientForm({ClientModel? initialClient}) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: initialClient?.nom ?? '');
    final telephoneController = TextEditingController(text: initialClient?.telephone ?? '');
    final emailController = TextEditingController(text: initialClient?.email ?? '');
    final adresseController = TextEditingController(text: initialClient?.adresse ?? '');
    final typeController = TextEditingController(
      text: initialClient?.typeClient ?? (_clientTypes.isNotEmpty ? _clientTypes.first : ''),
    );

    InputDecoration deco(String label, String hint, IconData icon) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2D47C8), width: 2),
        ),
      );
    }

    return showDialog<NouveauClientPayload>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(initialClient == null ? 'Nouveau client' : 'Modifier client'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomController,
                      decoration: deco('Nom', 'Nom du client', Icons.person_outline),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Nom requis';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: deco('Téléphone', 'Ex: 0612345678', Icons.phone_outlined),
                      validator: (value) {
                        final phone = (value ?? '').trim();
                        if (phone.isEmpty) return 'Téléphone requis';
                        if (phone.length < 8) return 'Téléphone invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: deco('Email', 'client@email.com', Icons.email_outlined),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Email requis';
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(text)) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: adresseController,
                      maxLines: 2,
                      decoration: deco('Adresse', 'Adresse du client', Icons.location_on_outlined),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return 'Adresse requise';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: typeController,
                      decoration: deco('Type client', 'Ex: PARTICULIER, VIP', Icons.category_outlined),
                      validator: (value) {
                        final raw = (value ?? '').trim();
                        if (raw.isEmpty) return 'Type client requis';

                        if (_clientTypes.isNotEmpty) {
                          final allowed = _clientTypes
                              .map((e) => e.trim().toUpperCase())
                              .where((e) => e.isNotEmpty)
                              .toSet();
                          final normalized = raw.toUpperCase();
                          if (!allowed.contains(normalized)) {
                            return 'Type invalide. Utilisez: ${allowed.join(', ')}';
                          }
                        }
                        return null;
                      },
                    ),
                    if (_clientTypes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _clientTypes
                              .map(
                                (type) => ChoiceChip(
                                  label: Text(type),
                                  selected: typeController.text.trim().toUpperCase() ==
                                      type.trim().toUpperCase(),
                                  onSelected: (_) {
                                    typeController.text = type.trim().toUpperCase();
                                    (formKey.currentState)?.validate();
                                    setState(() {});
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
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
                Navigator.pop(
                  dialogContext,
                  NouveauClientPayload(
                    nom: nomController.text,
                    telephone: telephoneController.text,
                    email: emailController.text,
                    adresse: adresseController.text,
                    typeClient: typeController.text.trim().toUpperCase(),
                  ),
                );
              },
              child: Text(initialClient == null ? 'Créer' : 'Modifier'),
            ),
          ],
        );
      },
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

  String _friendlyCreateError(String message) {
    final lower = message.toLowerCase();
    final isPkConflict = (lower.contains('client_pkey') && lower.contains('id_client')) ||
        (lower.contains('duplicate key') && lower.contains('id_client')) ||
        lower.contains('cle dupliquee');

    if (isPkConflict) {
      return 'Création temporairement indisponible (conflit ID serveur). Réessayez dans quelques secondes.';
    }
    return message;
  }

  // ---------- UI (PRO) ----------

  static const _bg = Color(0xFFF4F7FC);
  static const _card = Colors.white;
  static const _primary = Color(0xFF2D47C8);
  static const _accent = Color(0xFF0CAE4A);
  static const _text = Color(0xFF1F2A44);
  static const _muted = Color(0xFF607089);

  Widget _pageShell({required Widget child}) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _headerCard(BoxConstraints c) {
    final compact = c.maxWidth < 900;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, Color(0xFF2037A7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.people_alt_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestion des clients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Recherchez, ajoutez, modifiez et supprimez vos clients.',
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.9),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _countPill(_clients.length),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _isBusy ? null : () => _loadClients(showBusy: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _searchBar(fullWidth: true),
                const SizedBox(height: 10),
                _primaryButton(
                  icon: Icons.add,
                  label: 'Nouveau client',
                  onTap: _isBusy ? null : _onCreateClient,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _searchBar(fullWidth: false)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 190,
                  child: _primaryButton(
                    icon: Icons.add,
                    label: 'Nouveau client',
                    onTap: _isBusy ? null : _onCreateClient,
                  ),
                ),
              ],
            ),
          if (_clientTypes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _typeChips(),
          ],
          if (_isBusy) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countPill(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E2FF)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _searchBar({required bool fullWidth}) {
    return SizedBox(
      width: fullWidth ? double.infinity : 340,
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Rechercher (nom, téléphone, email...)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close),
                  onPressed: _isBusy ? null : _onClearSearch,
                ),
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6EAF2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _typeChips() {
    final normalized = _clientTypes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tous'),
            selected: _selectedType == null,
            onSelected: _isBusy ? null : (_) => _onSelectType(null),
          ),
          ...normalized.map(
            (t) => ChoiceChip(
              label: Text(t),
              selected: (_selectedType ?? '').toUpperCase() == t.toUpperCase(),
              onSelected: _isBusy ? null : (_) => _onSelectType(t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({required IconData icon, required String label, required VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _contentCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _skeletonList() {
    Widget bar(double w) => Container(
          width: w,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF2F7),
            borderRadius: BorderRadius.circular(99),
          ),
        );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) => _contentCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(180),
                    const SizedBox(height: 10),
                    bar(260),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              bar(70),
            ],
          ),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 6,
    );
  }

  Widget _emptyState() {
    final text = _query.isEmpty && (_selectedType == null || _selectedType!.isEmpty)
        ? 'Aucun client disponible'
        : 'Aucun client trouvé pour votre recherche';

    return Center(
      child: _contentCard(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.person_search_outlined, color: _primary, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w800, color: _text),
              ),
              const SizedBox(height: 6),
              Text(
                'Essayez un autre mot-clé ou ajoutez un nouveau client.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 14),
              if (_query.isEmpty)
                _primaryButton(
                  icon: Icons.add,
                  label: 'Ajouter un client',
                  onTap: _isBusy ? null : _onCreateClient,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: _contentCard(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 44),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _clientsResponsiveTable() {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return _clientsCards();
        }
        return _clientsTable();
      },
    );
  }

  Widget _clientsTable() {
    return _contentCard(
      child: Column(
        children: [
          // header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F9FC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TableHeader('Nom')),
                Expanded(flex: 2, child: _TableHeader('Téléphone')),
                Expanded(flex: 3, child: _TableHeader('Email')),
                Expanded(flex: 2, child: _TableHeader('Type')),
                Expanded(flex: 4, child: _TableHeader('Adresse')),
                SizedBox(width: 120, child: _TableHeader('Actions')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: _clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = _clients[index];
                return InkWell(
                  onTap: _isBusy ? null : () => _onEditClient(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _TableCellTitle(c.nom.isNotEmpty ? c.nom : 'Sans nom'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TableCellText(c.telephone.isNotEmpty ? c.telephone : '-'),
                        ),
                        Expanded(
                          flex: 3,
                          child: _TableCellText((c.email ?? '').isNotEmpty ? c.email! : '-'),
                        ),
                        Expanded(
                          flex: 2,
                          child: _TypePill(text: (c.typeClient ?? '-').isEmpty ? '-' : (c.typeClient ?? '-')),
                        ),
                        Expanded(
                          flex: 4,
                          child: _TableCellText(
                            (c.adresse ?? '').isNotEmpty ? c.adresse! : '-',
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Modifier',
                                onPressed: _isBusy ? null : () => _onEditClient(c),
                                icon: const Icon(Icons.edit_outlined, size: 20),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: _isBusy ? null : () => _onDeleteClient(c),
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _clientsCards() {
    return ListView.separated(
      itemCount: _clients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _clients[index];

        return _contentCard(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF4FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.person_outline, color: _primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.nom.isNotEmpty ? c.nom : 'Sans nom',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: _text,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: _isBusy ? null : () => _onEditClient(c),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: _isBusy ? null : () => _onDeleteClient(c),
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.phone_outlined, c.telephone.isNotEmpty ? c.telephone : '-'),
                _infoRow(Icons.email_outlined, (c.email ?? '').isNotEmpty ? c.email! : '-'),
                _infoRow(Icons.category_outlined, (c.typeClient ?? '').isNotEmpty ? c.typeClient! : '-'),
                _infoRow(Icons.location_on_outlined, (c.adresse ?? '').isNotEmpty ? c.adresse! : '-'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _pageShell(
      child: LayoutBuilder(
        builder: (context, c) {
          if (_isLoading) {
            return Column(
              children: [
                _headerCard(c),
                const SizedBox(height: 14),
                Expanded(child: _skeletonList()),
              ],
            );
          }

          if (_errorMessage != null) {
            return _errorState(_errorMessage!);
          }

          return Column(
            children: [
              _headerCard(c),
              const SizedBox(height: 14),
              Expanded(
                child: _clients.isEmpty ? _emptyState() : _clientsResponsiveTable(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF607089),
      ),
    );
  }
}

class _TableCellTitle extends StatelessWidget {
  const _TableCellTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: Color(0xFF1F2A44),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TableCellText extends StatelessWidget {
  const _TableCellText(this.text, {this.maxLines = 1});
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.text});
  final String text;

  static const _primary = Color(0xFF2D47C8);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD7E2FF)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}