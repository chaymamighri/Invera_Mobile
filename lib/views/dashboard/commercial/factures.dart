import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invera_mobile/core/ui/mise_en_page.dart';
import 'package:invera_mobile/models/client.dart';
import 'package:invera_mobile/models/commande.dart';
import 'package:invera_mobile/models/facture.dart';
import 'package:invera_mobile/services/commandes.dart';
import 'package:invera_mobile/services/factures.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _accent = Color(0xFF0CAE4A);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _borderLight = Color(0xFFE6EAF2);
const double _baseUnit = 8.0;
const double _pdfVatRate = 0.19;
const String _pdfCompanyAddress = '123 Rue de la Republique, 1000 Tunis';
const String _pdfCompanyPhone = '+216 00 000 000';
const String _pdfCompanyEmail = 'contact@invera.tn';
const String _pdfCompanyTaxId = 'MF: 0000000/A/M/000';

/// Widget qui affiche la section des factures commerciales.
class CommercialFacturesSection extends StatefulWidget {
  final String title;
  final String subtitle;

  const CommercialFacturesSection({
    super.key,
    this.title = 'Commandes pour facturation',
    this.subtitle =
        'Toutes les commandes confirmees. Filtrez par calendrier puis generez chaque facture commande par commande.',
  });

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<CommercialFacturesSection> createState() =>
      _CommercialFacturesSectionState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour la section des factures commerciales.
class _CommercialFacturesSectionState extends State<CommercialFacturesSection> {
  // Configuration, dependances et etat local de l'interface.
  static const Set<String> _confirmedStatuses = {'CONFIRMEE', 'VALIDEE'};

  final CommandeService _commandeService = CommandeService();
  final FactureService _factureService = FactureService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _refreshing = false;
  int? _generatingCommandeId;
  String? _error;

  List<CommandeModel> _confirmedCommandes = <CommandeModel>[];
  final Map<int, FactureModel> _facturesByCommandeId = <int, FactureModel>{};
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _loadData(showLoader: true);
  }

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Valeurs calculees et methodes utilitaires.

  /// Charge les donnees.
  Future<void> _loadData({required bool showLoader}) async {
    setState(() {
      if (showLoader) {
        _loading = true;
      } else {
        _refreshing = true;
      }
      _error = null;
    });

    try {
      final commandes = await _commandeService.getCommandes();
      final confirmed = _sortCommandesByCreation(
        commandes.where((cmd) {
          return _confirmedStatuses.contains(cmd.statut.trim().toUpperCase());
        }).toList(),
      );

      final facturesByCommande = <int, FactureModel>{};
      try {
        final factures = await _factureService.getAllFactures();
        for (final facture in factures) {
          final cmdId = facture.commandeId;
          if (cmdId != null) {
            facturesByCommande[cmdId] = facture;
          }
        }
      } catch (_) {
        if (mounted) {
          _showMessage(
            'Factures API warning: impossible de charger les factures existantes. Les commandes restent chargees.',
            isError: true,
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _confirmedCommandes = confirmed;
        _facturesByCommandeId
          ..clear()
          ..addAll(facturesByCommande);
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  /// Methode utilitaire pour la date seule.
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Trie les commandes par creation dans l'ordre souhaite.
  List<CommandeModel> _sortCommandesByCreation(List<CommandeModel> commandes) {
    final sorted = List<CommandeModel>.from(commandes);
    sorted.sort((a, b) {
      final ad = _parseCommandeCreationDate(a);
      final bd = _parseCommandeCreationDate(b);

      if (ad != null && bd != null) {
        final cmp = bd.compareTo(ad);
        if (cmp != 0) return cmp;
      } else if (ad == null && bd != null) {
        return 1;
      } else if (ad != null && bd == null) {
        return -1;
      }

      return b.idCommandeClient.compareTo(a.idCommandeClient);
    });
    return sorted;
  }

  /// Methode utilitaire pour l'analyse de la date de creation de la commande.
  DateTime? _parseCommandeCreationDate(CommandeModel cmd) {
    final raw = cmd.dateCommande.trim();
    if (raw.isNotEmpty) {
      final parsedRaw = DateTime.tryParse(raw);
      if (parsedRaw != null) return parsedRaw;
    }

    final formatted = cmd.dateCommandeFormatted.trim();
    if (formatted.isEmpty || formatted == '-') return null;

    final parsedFormatted = DateTime.tryParse(formatted);
    if (parsedFormatted != null) return parsedFormatted;

    final normalized = formatted.replaceFirst(' ', 'T');
    final parsedNormalized = DateTime.tryParse(normalized);
    if (parsedNormalized != null) return parsedNormalized;

    final match = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(formatted);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day, hour, minute, second);
  }

  /// Methode utilitaire pour l'analyse de la date de la commande.
  DateTime? _parseCommandeDate(CommandeModel cmd) {
    final parsed = _parseCommandeCreationDate(cmd);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Methode utilitaire pour l'appartenance a la plage de dates.
  bool _belongsToDateRange(CommandeModel cmd) {
    final selected = _selectedDateRange;
    if (selected == null) return true;

    final date = _parseCommandeDate(cmd);
    if (date == null) return false;

    final start = _dayOnly(selected.start);
    final end = _dayOnly(selected.end);
    final order = _dayOnly(date);
    return !order.isBefore(start) && !order.isAfter(end);
  }

  /// Verifie si la commande est facturee.
  bool _isInvoiced(int commandeId) {
    return _facturesByCommandeId.containsKey(commandeId);
  }

  /// Retourne les commandes en attente.
  List<CommandeModel> get _pendingCommandes {
    return _confirmedCommandes
        .where((cmd) => !_isInvoiced(cmd.idCommandeClient))
        .toList();
  }

  /// Retourne les commandes visibles.
  List<CommandeModel> get _visibleCommandes {
    final terms = _searchQueryTerms;

    return _confirmedCommandes.where((cmd) {
      if (!_belongsToDateRange(cmd)) return false;
      if (terms.isEmpty) return true;
      final haystack = _buildSearchHaystack(cmd);
      return terms.every(haystack.contains);
    }).toList();
  }

  /// Formate la date pour l'affichage dans l'interface.
  String _formatDateForUi(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  /// Retourne le libelle de la plage de dates.
  String get _dateRangeLabel {
    final selected = _selectedDateRange;
    if (selected == null) return 'Toutes dates';
    return '${_formatDateForUi(selected.start)} -> ${_formatDateForUi(selected.end)}';
  }

  /// Verifie si la plage de dates est identique.
  bool _isSameDateRange(DateTimeRange? a, DateTimeRange? b) {
    if (a == null || b == null) return a == b;
    final startA = _dayOnly(a.start);
    final endA = _dayOnly(a.end);
    final startB = _dayOnly(b.start);
    final endB = _dayOnly(b.end);
    return startA == startB && endA == endB;
  }

  /// Methode utilitaire pour la plage normalisee.
  DateTimeRange _normalizedRange(DateTime start, DateTime end) {
    final normalizedStart = _dayOnly(start);
    final normalizedEnd = _dayOnly(end);
    if (!normalizedStart.isAfter(normalizedEnd)) {
      return DateTimeRange(start: normalizedStart, end: normalizedEnd);
    }
    return DateTimeRange(start: normalizedEnd, end: normalizedStart);
  }

  // Actions utilisateur et traitements asynchrones.

  /// Ouvre la feuille de filtre par date.
  Future<void> _openDateFilterSheet() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10, 1, 1);
    final lastDate = DateTime(now.year + 10, 12, 31);
    final todayRange = _normalizedRange(now, now);
    final last7DaysRange = _normalizedRange(
      now.subtract(const Duration(days: 6)),
      now,
    );
    final monthRange = _normalizedRange(
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 0),
    );
    final yearRange = _normalizedRange(
      DateTime(now.year, 1, 1),
      DateTime(now.year, 12, 31),
    );

    DateTimeRange? draftRange = _selectedDateRange;

    DateTime safeInitialDate(DateTime? input) {
      final base = _dayOnly(input ?? now);
      if (base.isBefore(firstDate)) return firstDate;
      if (base.isAfter(lastDate)) return lastDate;
      return base;
    }

    Future<DateTime?> pickSingleDate({
      required DateTime? initialDate,
      required String helpText,
    }) async {
      return showDatePicker(
        context: context,
        locale: const Locale('fr', 'FR'),
        firstDate: firstDate,
        lastDate: lastDate,
        initialDate: safeInitialDate(initialDate),
        helpText: helpText,
        cancelText: 'Annuler',
        confirmText: 'Valider',
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            Widget quickRangeChip(String label, DateTimeRange? range) {
              final selected = _isSameDateRange(draftRange, range);
              return ChoiceChip(
                selected: selected,
                label: Text(label),
                selectedColor: _primary.withValues(alpha: 0.16),
                backgroundColor: _surface,
                side: BorderSide(color: selected ? _primary : _borderLight),
                labelStyle: TextStyle(
                  color: selected ? _primaryDark : _textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
                onSelected: (_) => modalSetState(() => draftRange = range),
              );
            }

            Future<void> pickStartDate() async {
              final picked = await pickSingleDate(
                initialDate: draftRange?.start,
                helpText: 'Date debut',
              );
              if (picked == null) return;
              modalSetState(() {
                draftRange = _normalizedRange(
                  picked,
                  draftRange?.end ?? picked,
                );
              });
            }

            Future<void> pickEndDate() async {
              final picked = await pickSingleDate(
                initialDate: draftRange?.end ?? draftRange?.start,
                helpText: 'Date fin',
              );
              if (picked == null) return;
              modalSetState(() {
                draftRange = _normalizedRange(
                  draftRange?.start ?? picked,
                  picked,
                );
              });
            }

            return SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.date_range_outlined,
                            color: _primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtre calendrier',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choisissez une plage rapide ou des dates precises.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fermer',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        quickRangeChip('Toutes dates', null),
                        quickRangeChip('Aujourd\'hui', todayRange),
                        quickRangeChip('7 derniers jours', last7DaysRange),
                        quickRangeChip('Ce mois', monthRange),
                        quickRangeChip('Cette annee', yearRange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickStartDate,
                              icon: const Icon(Icons.event_outlined, size: 16),
                              label: Text(
                                draftRange == null
                                    ? 'Du'
                                    : 'Du ${_formatDateForUi(draftRange!.start)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickEndDate,
                              icon: const Icon(Icons.event_available, size: 16),
                              label: Text(
                                draftRange == null
                                    ? 'Au'
                                    : 'Au ${_formatDateForUi(draftRange!.end)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              _selectedDateRange = draftRange;
                            });
                            Navigator.of(sheetContext).pop();
                            _showMessage(
                              draftRange == null
                                  ? 'Filtre date efface.'
                                  : 'Filtre applique: $_dateRangeLabel',
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Appliquer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
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

  // Valeurs calculees et methodes utilitaires.

  /// Normalise le texte de recherche.
  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\u00E0-\u00E5]'), 'a')
        .replaceAll(RegExp(r'[\u00E8-\u00EB]'), 'e')
        .replaceAll(RegExp(r'[\u00EC-\u00EF]'), 'i')
        .replaceAll(RegExp(r'[\u00F2-\u00F6]'), 'o')
        .replaceAll(RegExp(r'[\u00F9-\u00FC]'), 'u')
        .replaceAll('\u00E7', 'c')
        .replaceAll('\u0153', 'oe')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Retourne les termes de la recherche.
  List<String> get _searchQueryTerms {
    final normalized = _normalizeSearchText(_searchQuery);
    if (normalized.isEmpty) return const <String>[];
    return normalized
        .split(' ')
        .where((term) => term.isNotEmpty)
        .toList(growable: false);
  }

  // Construction de l'interface.

  /// Construit la chaine de recherche.
  String _buildSearchHaystack(CommandeModel cmd) {
    final date = _parseCommandeDate(cmd);
    final normalizedDate = date == null
        ? ''
        : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final raw = <String>[
      cmd.referenceCommandeClient,
      cmd.dateCommande,
      cmd.dateCommandeFormatted,
      cmd.client?.fullName ?? '',
      cmd.client?.telephone ?? '',
      cmd.client?.email ?? '',
      _displayStatus(cmd.statut),
      cmd.total.toStringAsFixed(2),
      normalizedDate,
    ].join(' ');
    return _normalizeSearchText(raw);
  }

  // Valeurs calculees et methodes utilitaires.

  /// Calcule le total.
  double _sumTotal(List<CommandeModel> items) {
    return items.fold<double>(0, (sum, e) => sum + e.total);
  }

  /// Formate amount pour l'affichage.
  String _formatAmount(double value) => '${value.toStringAsFixed(2)} DT';

  /// Retourne un libelle d'affichage pour le statut.
  String _displayStatus(String raw) {
    final norm = raw.trim().toUpperCase();
    if (norm == 'EN_ATTENTE') return 'En attente';
    if (norm == 'CONFIRMEE' || norm == 'VALIDEE') return 'Confirmee';
    if (norm == 'ANNULEE' || norm == 'REJETEE') return 'Annulee';
    return raw;
  }

  // Construction de l'interface.

  /// Construit l'apercu des produits.
  String _buildProductsPreview(CommandeModel cmd) {
    if (cmd.produits.isEmpty) return 'Aucun produit';
    final names = cmd.produits.map((p) => p.libelle).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names[0]} + ${names[1]} + ${names.length - 2} autres';
  }

  /// Construit le sous-total de la commande.
  String _buildCommandeSubtotal(CommandeModel cmd) {
    final subtotal = cmd.produits.fold<double>(
      0,
      (sum, p) => sum + p.sousTotal,
    );
    return '${subtotal.toStringAsFixed(2)} DT';
  }

  // Valeurs calculees et methodes utilitaires.

  /// Verifie s'il s'agit d'une erreur d'authentification.
  bool _isAuthError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('http 401') ||
        normalized.contains('http 403') ||
        normalized.contains('acces refuse') ||
        normalized.contains('access denied');
  }

  /// Nettoie le message d'erreur avant l'affichage.
  String _cleanErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.startsWith('Exception:')) {
      return raw.substring('Exception:'.length).trim();
    }
    return raw;
  }

  /// Verifie si la generation est en cours.
  bool _isGeneratingFor(int commandeId) {
    return _generatingCommandeId == commandeId;
  }

  /// Methode utilitaire pour la creation d'une facture pour la commande.
  Future<FactureModel?> _ensureFactureForCommande(CommandeModel cmd) async {
    final cached = _facturesByCommandeId[cmd.idCommandeClient];
    if (cached != null) return cached;

    setState(() => _generatingCommandeId = cmd.idCommandeClient);

    try {
      final existing = await _factureService.getFactureByCommandeId(
        cmd.idCommandeClient,
      );

      if (existing != null) {
        if (!mounted) return existing;
        setState(() {
          _facturesByCommandeId[cmd.idCommandeClient] = existing;
          _generatingCommandeId = null;
        });
        return existing;
      }

      final facture = await _factureService.generateFromCommande(
        cmd.idCommandeClient,
      );

      if (!mounted) return facture;
      setState(() {
        _facturesByCommandeId[cmd.idCommandeClient] = facture;
        _generatingCommandeId = null;
      });
      _showMessage(
        'Facture ${facture.referenceFactureClient} generee pour ${cmd.referenceCommandeClient}.',
      );
      return facture;
    } catch (error) {
      if (!mounted) return null;
      setState(() => _generatingCommandeId = null);

      final message = _cleanErrorMessage(error);
      _showMessage(
        _isAuthError(message)
            ? 'Generation impossible pour ${cmd.referenceCommandeClient}. Verifiez les droits backend sur /api/factures/generer/{commandeId}.'
            : 'Erreur de generation pour ${cmd.referenceCommandeClient}: $message',
        isError: true,
      );
      return null;
    }
  }

  // Actions utilisateur et traitements asynchrones.

  /// Ouvre le flux de facture.
  Future<void> _openFactureFlow(CommandeModel cmd) async {
    final facture = await _ensureFactureForCommande(cmd);
    if (!mounted || facture == null) return;
    _showFactureDetails(cmd, facture);
  }

  /// Exporte le PDF de la facture.
  Future<void> _exportFacturePdf(
    CommandeModel cmd,
    FactureModel facture,
  ) async {
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _buildFacturePdfBytes(cmd, facture),
        name: '${facture.referenceFactureClient}.pdf',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        'Export PDF impossible: ${_cleanErrorMessage(error)}',
        isError: true,
      );
    }
  }

  // Construction de l'interface.

  /// Construit les octets du PDF de la facture.
  Future<Uint8List> _buildFacturePdfBytes(
    CommandeModel cmd,
    FactureModel facture,
  ) async {
    final baseFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bold.ttf'),
    );
    final pdfTheme = pw.ThemeData.withFont(base: baseFont, bold: boldFont);
    final document = pw.Document();
    final client = cmd.client;
    final logoBytes = await rootBundle.load('assets/images/logo.png');
    final logoImage = pw.MemoryImage(
      logoBytes.buffer.asUint8List(
        logoBytes.offsetInBytes,
        logoBytes.lengthInBytes,
      ),
    );
    final generatedAt = _formatPdfDate(facture.dateFactureDisplay);
    final clientType = _formatClientType(client?.typeClient);
    final articlesSubtotal = cmd.produits.fold<double>(
      0,
      (sum, produit) => sum + produit.sousTotal,
    );
    final subtotal = articlesSubtotal > 0 ? articlesSubtotal : cmd.sousTotal;
    final vatAmount = subtotal * _pdfVatRate;
    final totalTtc = subtotal + vatAmount;
    final invoiceHeadlineAmount = facture.montantTotal > 0
        ? facture.montantTotal
        : cmd.total;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 24),
        build: (context) => [
          _buildPdfHeader(
            logoImage: logoImage,
            reference: facture.referenceFactureClient,
            status: facture.statut,
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildPdfInfoCard(
                  title: 'CLIENT',
                  marker: 'C',
                  markerBackground: PdfColor.fromInt(0xFFF1E8FF),
                  markerColor: PdfColor.fromInt(0xFF6B3FA0),
                  children: [
                    _buildPdfInfoRow('Nom', client?.fullName ?? '-'),
                    _buildPdfInfoRow('Type', clientType),
                    _buildPdfInfoRow('Email', client?.email ?? '-'),
                    _buildPdfInfoRow('Tel', client?.telephone ?? '-'),
                    _buildPdfInfoRow('Adresse', client?.adresse ?? '-'),
                  ],
                ),
              ),
              pw.SizedBox(width: 18),
              pw.Expanded(
                child: _buildPdfInfoCard(
                  title: 'FACTURE',
                  marker: 'F',
                  markerBackground: PdfColor.fromInt(0xFFF3EBFF),
                  markerColor: PdfColor.fromInt(0xFFA06BFF),
                  children: [
                    _buildPdfInfoRow('Date', generatedAt),
                    _buildPdfInfoRow(
                      'No',
                      facture.referenceFactureClient.trim().isEmpty
                          ? '-'
                          : facture.referenceFactureClient,
                    ),
                    pw.SizedBox(height: 14),
                    pw.Container(
                      height: 1,
                      color: PdfColor.fromInt(0xFFE8ECF4),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total TTC',
                          style: pw.TextStyle(
                            fontSize: 12.5,
                            color: PdfColor.fromInt(0xFF4B5A6A),
                          ),
                        ),
                        pw.Text(
                          _formatPdfAmount(invoiceHeadlineAmount),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(_primary.toARGB32()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 26),
          _buildPdfSectionTitle('ARTICLES'),
          pw.SizedBox(height: 12),
          _buildPdfArticlesTable(cmd.produits),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: _buildPdfTotalsCard(
              subtotal: subtotal,
              vatAmount: vatAmount,
              totalTtc: totalTtc,
            ),
          ),
          pw.SizedBox(height: 30),
          _buildPdfFooter(),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildPdfHeader({
    required pw.MemoryImage logoImage,
    required String reference,
    required String status,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 78,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Container(
                    width: 1,
                    height: 84,
                    color: PdfColor.fromInt(0xFFE6EAF2),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPdfContactLine(
                          marker: 'P',
                          value: _pdfCompanyAddress,
                          markerBackground: PdfColor.fromInt(0xFFFFE8F2),
                          markerColor: PdfColor.fromInt(0xFFE25793),
                        ),
                        pw.SizedBox(height: 10),
                        _buildPdfContactLine(
                          marker: 'T',
                          value: _pdfCompanyPhone,
                          markerBackground: PdfColor.fromInt(0xFFFFE7F1),
                          markerColor: PdfColor.fromInt(0xFFD44A86),
                        ),
                        pw.SizedBox(height: 10),
                        _buildPdfContactLine(
                          marker: '@',
                          value: _pdfCompanyEmail,
                          markerBackground: PdfColor.fromInt(0xFFF4EDFF),
                          markerColor: PdfColor.fromInt(0xFF8C73E6),
                        ),
                        pw.SizedBox(height: 10),
                        _buildPdfContactLine(
                          marker: 'ID',
                          value: _pdfCompanyTaxId,
                          markerBackground: PdfColor.fromInt(0xFFF2E9FF),
                          markerColor: PdfColor.fromInt(0xFF9A63E6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 29,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF16223C),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    reference.trim().isEmpty ? '-' : reference,
                    style: pw.TextStyle(
                      fontSize: 12.5,
                      color: PdfColor.fromInt(0xFF6E7C8F),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  _buildPdfStatusPill(status),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Container(height: 1, color: PdfColor.fromInt(0xFFF0F2F6)),
      ],
    );
  }

  pw.Widget _buildPdfContactLine({
    required String marker,
    required String value,
    required PdfColor markerBackground,
    required PdfColor markerColor,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 16,
          height: 16,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: markerBackground,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            marker,
            style: pw.TextStyle(
              fontSize: marker.length > 1 ? 6.5 : 8.5,
              fontWeight: pw.FontWeight.bold,
              color: markerColor,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColor.fromInt(0xFF556273),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfStatusPill(String rawStatus) {
    final statusLabel = _displayStatus(rawStatus);
    final statusUpper = rawStatus.trim().toUpperCase();
    var borderColor = PdfColor.fromInt(0xFFF5D978);
    var fillColor = PdfColor.fromInt(0xFFFFFBEC);
    var textColor = PdfColor.fromInt(0xFFB27A1D);

    if (statusUpper == 'PAYEE' || statusUpper == 'PAID') {
      borderColor = PdfColor.fromInt(0xFF93D7AB);
      fillColor = PdfColor.fromInt(0xFFEFFAF3);
      textColor = PdfColor.fromInt(0xFF24734A);
    } else if (statusUpper == 'ANNULEE' || statusUpper == 'REJETEE') {
      borderColor = PdfColor.fromInt(0xFFF0A5A5);
      fillColor = PdfColor.fromInt(0xFFFFF1F1);
      textColor = PdfColor.fromInt(0xFFC25353);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: pw.BoxDecoration(
        color: fillColor,
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 7,
            height: 7,
            decoration: pw.BoxDecoration(
              color: textColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            statusLabel,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfInfoCard({
    required String title,
    required String marker,
    required PdfColor markerBackground,
    required PdfColor markerColor,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFBFCFF),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
        borderRadius: pw.BorderRadius.circular(18),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPdfCardTitle(
            title: title,
            marker: marker,
            markerBackground: markerBackground,
            markerColor: markerColor,
          ),
          pw.SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildPdfCardTitle({
    required String title,
    required String marker,
    required PdfColor markerBackground,
    required PdfColor markerColor,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 18,
          height: 18,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: markerBackground,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            marker,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: markerColor,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6B7788),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 54,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11.5,
                color: PdfColor.fromInt(0xFF8A96A7),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value.trim().isEmpty ? '-' : value,
              style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF1C263A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSectionTitle(String title) {
    return pw.Row(
      children: [
        pw.Container(
          width: 16,
          height: 16,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF3EBFF),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title.substring(0, 1),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFFB58CFF),
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A7788),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfArticlesTable(List<CommandeProduitDetail> produits) {
    final rows = produits.isEmpty ? <CommandeProduitDetail>[] : produits;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        children: [
          _buildPdfArticleRow(
            description: 'DESCRIPTION',
            quantity: 'QTE',
            unitPrice: 'PRIX UNITAIRE',
            total: 'TOTAL',
            isHeader: true,
          ),
          if (rows.isEmpty)
            _buildPdfArticleRow(
              description: 'Aucun article',
              quantity: '-',
              unitPrice: '-',
              total: '-',
            )
          else
            for (final produit in rows)
              _buildPdfArticleRow(
                description: produit.libelle,
                quantity: '${produit.quantite}',
                unitPrice: _formatPdfAmount(produit.prixUnitaire),
                total: _formatPdfAmount(produit.sousTotal),
              ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfArticleRow({
    required String description,
    required String quantity,
    required String unitPrice,
    required String total,
    bool isHeader = false,
  }) {
    final textColor = isHeader
        ? PdfColor.fromInt(0xFF7A8696)
        : PdfColor.fromInt(0xFF1E273A);
    final borderSide = pw.BorderSide(color: PdfColor.fromInt(0xFFEFF3F8));

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: pw.BoxDecoration(
        color: isHeader ? PdfColor.fromInt(0xFFFBFCFF) : PdfColors.white,
        border: isHeader ? null : pw.Border(top: borderSide),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildPdfArticleCell(
            text: description,
            flex: 4,
            alignment: pw.Alignment.centerLeft,
            isHeader: isHeader,
            color: textColor,
          ),
          _buildPdfArticleCell(
            text: quantity,
            flex: 1,
            alignment: pw.Alignment.center,
            isHeader: isHeader,
            color: textColor,
          ),
          _buildPdfArticleCell(
            text: unitPrice,
            flex: 2,
            alignment: pw.Alignment.centerRight,
            isHeader: isHeader,
            color: textColor,
          ),
          _buildPdfArticleCell(
            text: total,
            flex: 2,
            alignment: pw.Alignment.centerRight,
            isHeader: isHeader,
            color: textColor,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfArticleCell({
    required String text,
    required int flex,
    required pw.Alignment alignment,
    required bool isHeader,
    required PdfColor color,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: alignment,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: pw.Text(
          text,
          textAlign: alignment == pw.Alignment.centerRight
              ? pw.TextAlign.right
              : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: isHeader ? 10.5 : 11.5,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
            letterSpacing: isHeader ? 0.25 : 0,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildPdfTotalsCard({
    required double subtotal,
    required double vatAmount,
    required double totalTtc,
  }) {
    return pw.Container(
      width: 258,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE9EEF5)),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildPdfSummaryLine('Sous-total', _formatPdfAmount(subtotal)),
          pw.SizedBox(height: 12),
          _buildPdfSummaryLine(
            'TVA ${(100 * _pdfVatRate).toStringAsFixed(0)}%',
            _formatPdfAmount(vatAmount),
          ),
          pw.SizedBox(height: 12),
          pw.Container(height: 1, color: PdfColor.fromInt(0xFFE9EEF5)),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Total TTC',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF20293B),
                ),
              ),
              pw.Text(
                _formatPdfAmount(totalTtc),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(_primary.toARGB32()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfSummaryLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12.5,
            color: PdfColor.fromInt(0xFF667383),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12.5,
            color: PdfColor.fromInt(0xFF303A49),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F9FD),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Center(
        child: pw.Text(
          'Merci de votre confiance - Facture generee par InVera',
          style: pw.TextStyle(
            fontSize: 10.5,
            color: PdfColor.fromInt(0xFF8A96A6),
          ),
        ),
      ),
    );
  }

  // Valeurs calculees et methodes utilitaires.

  /// Formate pdf amount pour l'affichage.
  String _formatPdfAmount(double value) {
    final absolute = value.abs().toStringAsFixed(3);
    final parts = absolute.split('.');
    final integerPart = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    final formatted = '$integerPart,${parts.last} DT';
    return value < 0 ? '-$formatted' : formatted;
  }

  /// Formate pdf date pour l'affichage.
  String _formatPdfDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final parsed = _parseFlexibleDate(trimmed);
    if (parsed == null) return trimmed;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString().padLeft(4, '0');
    return '$day/$month/$year';
  }

  /// Methode utilitaire pour l'analyse d'une date flexible.
  DateTime? _parseFlexibleDate(String raw) {
    final parsedRaw = DateTime.tryParse(raw);
    if (parsedRaw != null) return parsedRaw;

    final normalized = raw.replaceFirst(' ', 'T');
    final parsedNormalized = DateTime.tryParse(normalized);
    if (parsedNormalized != null) return parsedNormalized;

    final match = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[ T](\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
    ).firstMatch(raw);
    if (match == null) return null;

    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    final hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day, hour, minute, second);
  }

  /// Formate le type de client pour l'affichage.
  String _formatClientType(String? raw) {
    final normalized = ClientType.normalize(raw);
    if (normalized.isEmpty) return '-';
    return normalized == 'FIDEL' ? 'FIDELE' : normalized;
  }

  // Actions utilisateur et traitements asynchrones.

  /// Affiche les details de la facture.
  void _showFactureDetails(CommandeModel cmd, FactureModel facture) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 24,
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: const Text('Facture'),
          content: SizedBox(
            width: AdaptiveLayout.dialogWidth(ctx, max: 520, sideMargin: 8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailsSection(
                    title: 'Informations facture',
                    child: Column(
                      children: [
                        _buildSummaryTile(
                          label: 'Reference',
                          value: facture.referenceFactureClient,
                        ),
                        const SizedBox(height: _baseUnit),
                        _buildSummaryTile(
                          label: 'Commande',
                          value: cmd.referenceCommandeClient,
                        ),
                        const SizedBox(height: _baseUnit),
                        _buildSummaryTile(
                          label: 'Date facture',
                          value: facture.dateFactureDisplay,
                        ),
                        const SizedBox(height: _baseUnit),
                        _buildSummaryTile(
                          label: 'Statut',
                          value: facture.statut,
                        ),
                        const SizedBox(height: _baseUnit),
                        _buildSummaryTile(
                          label: 'Montant total',
                          value: _formatAmount(facture.montantTotal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _baseUnit * 2),
                  _buildDetailsSection(
                    title: 'Client',
                    child: Column(
                      children: [
                        _buildCommandeDetailRow(
                          icon: Icons.person_outline,
                          label: 'Nom complet',
                          value: cmd.client?.fullName ?? '-',
                        ),
                        _buildCommandeDetailRow(
                          icon: Icons.phone_outlined,
                          label: 'Telephone',
                          value: cmd.client?.telephone ?? '-',
                        ),
                        _buildCommandeDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: cmd.client?.email ?? '-',
                        ),
                        _buildCommandeDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Adresse',
                          value: cmd.client?.adresse ?? '-',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
            ),
            ElevatedButton.icon(
              onPressed: () => _exportFacturePdf(cmd, facture),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Affiche les details de la commande.
  void _showCommandeDetails(CommandeModel cmd) {
    final facture = _facturesByCommandeId[cmd.idCommandeClient];
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final client = cmd.client;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: AdaptiveLayout.dialogWidth(ctx, max: 1000, sideMargin: 12),
            constraints: BoxConstraints(
              maxHeight: AdaptiveLayout.dialogHeight(ctx, ratio: 0.9),
            ),
            padding: EdgeInsets.all(_baseUnit * 3),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: _primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: _baseUnit * 1.5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Details de la commande',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cmd.referenceCommandeClient,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(cmd.statut),
                    const SizedBox(width: _baseUnit),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: _baseUnit * 2),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 860;

                      final leftPanel = SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailsSection(
                              title: 'Informations generales',
                              child: Wrap(
                                spacing: _baseUnit,
                                runSpacing: _baseUnit,
                                children: [
                                  _buildDetailInfoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Date',
                                    value: cmd.dateCommandeFormatted,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Client',
                                    value: client?.fullName ?? '-',
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.local_offer_outlined,
                                    label: 'Reference',
                                    value: cmd.referenceCommandeClient,
                                  ),
                                  _buildDetailInfoCard(
                                    icon: Icons.percent_outlined,
                                    label: 'Remise',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Coordonnees client',
                              child: Column(
                                children: [
                                  _buildCommandeDetailRow(
                                    icon: Icons.person_outline,
                                    label: 'Nom complet',
                                    value: client?.fullName ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.phone_outlined,
                                    label: 'Telephone',
                                    value: client?.telephone ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: client?.email ?? '-',
                                  ),
                                  _buildCommandeDetailRow(
                                    icon: Icons.location_on_outlined,
                                    label: 'Adresse',
                                    value: client?.adresse ?? '-',
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: _baseUnit * 2),
                            _buildDetailsSection(
                              title: 'Produits commandes',
                              child: Column(
                                children: [
                                  if (cmd.produits.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(_baseUnit * 2),
                                      decoration: BoxDecoration(
                                        color: _background,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _borderLight),
                                      ),
                                      child: const Text(
                                        'Aucun produit dans cette commande.',
                                        style: TextStyle(color: _textSecondary),
                                      ),
                                    )
                                  else
                                    ...cmd.produits.asMap().entries.map((
                                      entry,
                                    ) {
                                      return _buildProduitDetailCard(
                                        index: entry.key + 1,
                                        produit: entry.value,
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      final rightPanel = SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildDetailsSection(
                              title: 'Resume financier',
                              child: Column(
                                children: [
                                  _buildSummaryTile(
                                    label: 'Nombre de lignes',
                                    value: '${cmd.produits.length}',
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Statut',
                                    value: _displayStatus(cmd.statut),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildSummaryTile(
                                    label: 'Remise appliquee',
                                    value:
                                        '${cmd.tauxRemise.toStringAsFixed(2)}%',
                                  ),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  const Divider(color: _borderLight),
                                  const SizedBox(height: _baseUnit * 1.5),
                                  _buildAmountRow(
                                    'Sous-total estime',
                                    _buildCommandeSubtotal(cmd),
                                  ),
                                  const SizedBox(height: _baseUnit),
                                  _buildAmountRow(
                                    'Total final',
                                    '${cmd.total.toStringAsFixed(2)} DT',
                                    isPrimary: true,
                                  ),
                                ],
                              ),
                            ),
                            if (facture != null) ...[
                              const SizedBox(height: _baseUnit * 2),
                              _buildDetailsSection(
                                title: 'Facture enregistree',
                                child: Column(
                                  children: [
                                    _buildSummaryTile(
                                      label: 'Reference',
                                      value: facture.referenceFactureClient,
                                    ),
                                    const SizedBox(height: _baseUnit),
                                    _buildSummaryTile(
                                      label: 'Statut facture',
                                      value: facture.statut,
                                    ),
                                    const SizedBox(height: _baseUnit),
                                    _buildSummaryTile(
                                      label: 'Montant',
                                      value: _formatAmount(
                                        facture.montantTotal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            Expanded(child: leftPanel),
                            const SizedBox(height: _baseUnit * 2),
                            Expanded(child: rightPanel),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: leftPanel),
                          const SizedBox(width: _baseUnit * 2),
                          Expanded(flex: 2, child: rightPanel),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: _baseUnit * 2),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: _baseUnit,
                  runSpacing: _baseUnit,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.of(ctx, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
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

  // Construction de l'interface.

  /// Construit la pastille de statut.
  Widget _buildStatusChip(String status) {
    final normalized = status.trim().toUpperCase();
    late Color bg;
    late Color fg;

    if (normalized == 'CONFIRMEE' || normalized == 'VALIDEE') {
      bg = const Color(0xFFE9F8EF);
      fg = const Color(0xFF11853F);
    } else if (normalized == 'ANNULEE' || normalized == 'REJETEE') {
      bg = const Color(0xFFFFE8E8);
      fg = const Color(0xFFB42318);
    } else {
      bg = const Color(0xFFEFF4FF);
      fg = _primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        _displayStatus(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  /// Construit la tuile meta.
  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.25,
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
          Icon(icon, size: 14, color: _textSecondary),
          const SizedBox(width: 6),
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

  /// Construit la section de details.
  Widget _buildDetailsSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_baseUnit * 2),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: _baseUnit * 1.5),
          child,
        ],
      ),
    );
  }

  /// Construit la carte d'information detaillee.
  Widget _buildDetailInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: EdgeInsets.all(_baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderLight),
            ),
            child: Icon(icon, size: 18, color: _primary),
          ),
          const SizedBox(width: _baseUnit),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la ligne de detail de la commande.
  Widget _buildCommandeDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : _baseUnit),
      padding: EdgeInsets.all(_baseUnit * 1.25),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _textSecondary),
          const SizedBox(width: _baseUnit),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la carte detaillee du produit.
  Widget _buildProduitDetailCard({
    required int index,
    required CommandeProduitDetail produit,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _baseUnit * 1.25),
      padding: EdgeInsets.all(_baseUnit * 1.5),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderLight),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
              ),
              const SizedBox(width: _baseUnit),
              Expanded(
                child: Text(
                  produit.libelle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _textPrimary,
                  ),
                ),
              ),
              Text(
                '${produit.sousTotal.toStringAsFixed(2)} DT',
                style: const TextStyle(
                  color: _primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: _baseUnit * 1.25),
          Wrap(
            spacing: _baseUnit,
            runSpacing: _baseUnit,
            children: [
              _buildBadge(
                'Quantite: ${produit.quantite}',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
              _buildBadge(
                'Prix: ${produit.prixUnitaire.toStringAsFixed(2)} DT',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
              _buildBadge(
                'Sous-total: ${produit.sousTotal.toStringAsFixed(2)} DT',
                const Color(0xFF475569),
                const Color(0xFFF1F5F9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construit la tuile recapitulative.
  Widget _buildSummaryTile({required String label, required String value}) {
    final decoration = BoxDecoration(
      color: _background,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _borderLight),
    );

    final labelWidget = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: _textSecondary, fontSize: 12),
    );

    final valueWidget = Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 320;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _baseUnit * 1.5,
            vertical: _baseUnit * 1.3,
          ),
          decoration: decoration,
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 6),
                    valueWidget,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: labelWidget),
                    const SizedBox(width: _baseUnit),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Construit amount ligne.
  Widget _buildAmountRow(String label, String value, {bool isPrimary = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? _textPrimary : _textSecondary,
              fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
              fontSize: isPrimary ? 15 : 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? _accent : _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: isPrimary ? 18 : 14,
          ),
        ),
      ],
    );
  }

  // Actions utilisateur et traitements asynchrones.

  /// Affiche le message.
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : null,
      ),
    );
  }

  // Construction de l'interface.

  /// Construit le badge.
  Widget _buildBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Construit la pastille de compteur.
  Widget _buildCountPill(int count, {bool onDark = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _baseUnit * 1.5,
        vertical: _baseUnit,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.18)
            : _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.28)
              : _primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        '$count commandes',
        style: TextStyle(
          color: onDark ? Colors.white : _primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  /// Construit l'en-tete.
  Widget _buildHeader({
    required List<CommandeModel> visible,
    required int pending,
  }) {
    final selectableVisible = visible
        .where((e) => !_isInvoiced(e.idCommandeClient))
        .toList();

    final hasDateFilter = _selectedDateRange != null;
    final dateFilterButton = OutlinedButton.icon(
      onPressed: _openDateFilterSheet,
      icon: const Icon(Icons.date_range_outlined),
      label: Text(_dateRangeLabel),
    );

    final clearDateFilterButton = hasDateFilter
        ? OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedDateRange = null;
              });
              _showMessage('Filtre date efface.');
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Effacer filtre'),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(_baseUnit * 2),
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
              final compact = constraints.maxWidth < 760;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitle,
                    style: TextStyle(color: Color(0xFFE3EBFF), fontSize: 13),
                  ),
                  const SizedBox(height: _baseUnit * 1.5),
                  Wrap(
                    spacing: _baseUnit,
                    runSpacing: _baseUnit,
                    children: [
                      _buildBadge(
                        '$pending non facturees',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                      _buildBadge(
                        '${selectableVisible.length} visibles a generer',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                      _buildBadge(
                        'Montant visible: ${_formatAmount(_sumTotal(selectableVisible))}',
                        Colors.white,
                        Colors.white.withValues(alpha: 0.16),
                      ),
                    ],
                  ),
                ],
              );

              final counter = _buildCountPill(
                _confirmedCommandes.length,
                onDark: true,
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: _baseUnit * 1.5),
                    counter,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: _baseUnit * 2),
                  counter,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: _baseUnit * 1.5),
        Container(
          padding: EdgeInsets.all(_baseUnit * 1.5),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final searchField = TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText:
                      'Recherche multi-critere: ref, client, date, statut...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Vider',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                  filled: true,
                  fillColor: _background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    const SizedBox(height: _baseUnit),
                    Wrap(
                      spacing: _baseUnit * 0.75,
                      runSpacing: _baseUnit * 0.75,
                      children: [
                        dateFilterButton,
                        if (clearDateFilterButton != null)
                          clearDateFilterButton,
                      ],
                    ),
                    const SizedBox(height: _baseUnit),
                    const Text(
                      'Astuce: utilisez Details ou Facture sur chaque commande.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Expanded(child: searchField)],
                  ),
                  const SizedBox(height: _baseUnit),
                  Wrap(
                    spacing: _baseUnit,
                    runSpacing: _baseUnit,
                    children: [
                      dateFilterButton,
                      if (clearDateFilterButton != null) clearDateFilterButton,
                    ],
                  ),
                  const SizedBox(height: _baseUnit),
                  const Text(
                    'Astuce: utilisez Details ou Facture sur chaque commande.',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11.5,
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

  /// Construit le panneau des commandes.
  Widget _buildOrdersPanel(List<CommandeModel> visible) {
    if (visible.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: const Center(
          child: Text('Aucune commande ne correspond aux filtres actifs.'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildCommandeCard(visible[index]),
      ),
    );
  }

  /// Construit la carte de commande.
  Widget _buildCommandeCard(CommandeModel cmd) {
    final invoiced = _isInvoiced(cmd.idCommandeClient);
    final facture = _facturesByCommandeId[cmd.idCommandeClient];
    final isGenerating = _isGeneratingFor(cmd.idCommandeClient);
    final generationLocked = _generatingCommandeId != null;

    return Container(
      decoration: BoxDecoration(
        color: isGenerating ? const Color(0xFFF4F7FF) : _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGenerating ? const Color(0xFFBBC9FF) : _borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(_baseUnit * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: _baseUnit * 1.25),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cmd.referenceCommandeClient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cmd.dateCommandeFormatted,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _baseUnit),
                _buildStatusChip(cmd.statut),
              ],
            ),
            const SizedBox(height: _baseUnit * 1.5),
            Wrap(
              spacing: _baseUnit,
              runSpacing: _baseUnit,
              children: [
                _buildMetaTile(
                  icon: Icons.person_outline,
                  label: 'Client',
                  value: cmd.client?.fullName ?? '-',
                ),
                _buildMetaTile(
                  icon: Icons.payments_outlined,
                  label: 'Total',
                  value: _formatAmount(cmd.total),
                ),
                _buildMetaTile(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Lignes',
                  value: '${cmd.produits.length}',
                ),
              ],
            ),
            const SizedBox(height: _baseUnit * 1.5),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: _baseUnit * 1.25,
                vertical: _baseUnit,
              ),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildProductsPreview(cmd),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _baseUnit * 1.5),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: _baseUnit,
              runSpacing: _baseUnit,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showCommandeDetails(cmd),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Details'),
                ),
                OutlinedButton.icon(
                  onPressed: isGenerating || (generationLocked && !invoiced)
                      ? null
                      : () {
                          if (facture != null) {
                            _showFactureDetails(cmd, facture);
                            return;
                          }
                          _openFactureFlow(cmd);
                        },
                  icon: isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          invoiced
                              ? Icons.description_outlined
                              : Icons.receipt_outlined,
                        ),
                  label: const Text('Facture'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: invoiced ? _primaryDark : _accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit l'interface visible de ce widget.
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
              onPressed: () => _loadData(showLoader: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final visible = _visibleCommandes;
    final pending = _pendingCommandes.length;

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoader: false),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1120;
          final minHeight = constraints.maxHeight - (compact ? 24 : 36);

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.all(compact ? 12 : 18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight > 0 ? minHeight : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(visible: visible, pending: pending),
                  if (_refreshing) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 12),
                  _buildOrdersPanel(visible),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
