import 'package:flutter/material.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/services/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';

/// Widget qui affiche la section des categories d'approvisionnement.
class ProcurementCategoriesSection extends StatefulWidget {
  const ProcurementCategoriesSection({super.key});

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ProcurementCategoriesSection> createState() =>
      _ProcurementCategoriesSectionState();
}

/// Classe utilitaire pour l'etat de la section des categories d'approvisionnement.
class _ProcurementCategoriesSectionState
    extends State<ProcurementCategoriesSection> {
  final ProcurementService _service = ProcurementService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<ProcurementCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final categories = await _service.getCategories();

      if (!mounted) return;
      setState(() {
        _categories = _sortCategories(categories);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<ProcurementCategory> _sortCategories(
    List<ProcurementCategory> categories,
  ) {
    final sorted = categories.toList();
    sorted.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return sorted;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _vatController.clear();
  }

  String _editableVat(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  Future<void> _showEditDialog(ProcurementCategory category) async {
    final useBottomSheet = MediaQuery.sizeOf(context).width < 600;

    final payload = useBottomSheet
        ? await showModalBottomSheet<ProcurementCategoryUpsertPayload>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _CategoryEditToastDialog(
              initialCategory: category,
              initialVat: _editableVat(category.tauxTVA),
              isBottomSheet: true,
            ),
          )
        : await showDialog<ProcurementCategoryUpsertPayload>(
            context: context,
            barrierDismissible: false,
            builder: (_) => _CategoryEditToastDialog(
              initialCategory: category,
              initialVat: _editableVat(category.tauxTVA),
            ),
          );

    if (!mounted) return;
    if (payload == null) return;

    try {
      final updated = await _service.updateCategory(
        category.idCategorie,
        payload,
      );

      if (!mounted) return;
      setState(() {
        _categories = _sortCategories([
          for (final item in _categories)
            if (item.idCategorie == updated.idCategorie) updated else item,
        ]);
      });
      showMessage(context, 'Categorie mise a jour avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = ProcurementCategoryUpsertPayload(
      nomCategorie: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      tauxTVA: double.parse(_vatController.text.replaceAll(',', '.').trim()),
    );

    setState(() {
      _submitting = true;
    });

    try {
      final category = await _service.createCategory(payload);

      if (!mounted) return;
      setState(() {
        _categories = _sortCategories(<ProcurementCategory>[
          category,
          ..._categories,
        ]);
      });
      _resetForm();
      showMessage(context, 'Categorie creee avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(ProcurementCategory category) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Supprimer la categorie',
      message:
          'Voulez-vous supprimer ${category.displayName} ? Cette action est irreversible.',
      confirmLabel: 'Supprimer',
      confirmColor: Colors.red,
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCategory(category.idCategorie);
      if (!mounted) return;
      setState(() {
        _categories = [
          for (final item in _categories)
            if (item.idCategorie != category.idCategorie) item,
        ];
      });
      showMessage(context, 'Categorie supprimee avec succes.');
    } catch (error) {
      if (!mounted) return;
      showMessage(
        context,
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingPanel(message: 'Chargement des categories...');
    }

    if (_error != null) {
      return AsyncErrorCard(
        title: 'Impossible de charger les categories',
        message: _error!,
        onRetry: _loadCategories,
      );
    }

    final compactTable = MediaQuery.sizeOf(context).width < 760;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionSurface(
          title: 'Ajouter une nouvelle categorie',
          subtitle:
              'Le formulaire d ajout reste separe du formulaire de modification',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 720;

                    final nameField = TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la categorie',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom de la categorie est requis';
                        }
                        return null;
                      },
                    );

                    final vatField = TextFormField(
                      controller: _vatController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Taux de TVA (%)',
                        helperText: 'Ex: 19, 10, 5.5',
                      ),
                      validator: (value) {
                        final raw = value?.replaceAll(',', '.').trim() ?? '';
                        final parsed = double.tryParse(raw);
                        if (raw.isEmpty) {
                          return 'Le taux de TVA est requis';
                        }
                        if (parsed == null || parsed < 0 || parsed > 100) {
                          return 'Taux TVA invalide';
                        }
                        return null;
                      },
                    );

                    if (stacked) {
                      return Column(
                        children: [
                          nameField,
                          const SizedBox(height: 12),
                          vatField,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: nameField),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: vatField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: const Icon(Icons.add),
                      label: Text(
                        _submitting
                            ? 'Enregistrement...'
                            : 'Ajouter la categorie',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionSurface(
          title: 'Liste des categories',
          subtitle:
              '${_categories.length} categorie${_categories.length > 1 ? 's' : ''}',
          child: _categories.isEmpty
              ? const EmptyPanel(
                  title: 'Aucune categorie trouvee',
                  message:
                      'Ajoutez votre premiere categorie via le formulaire ci-dessus.',
                )
              : Scrollbar(
                  thumbVisibility: compactTable,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 760),
                      child: DataTable(
                        headingRowHeight: compactTable ? 46 : 50,
                        dataRowMinHeight: compactTable ? 64 : 70,
                        dataRowMaxHeight: compactTable ? 76 : 84,
                        horizontalMargin: compactTable ? 12 : 16,
                        columnSpacing: compactTable ? 16 : 22,
                        dividerThickness: 0.8,
                        headingRowColor: const WidgetStatePropertyAll(
                          procurementSoftBackground,
                        ),
                        headingTextStyle: TextStyle(
                          color: procurementMuted,
                          fontSize: compactTable ? 11.2 : 12.2,
                          fontWeight: FontWeight.w800,
                        ),
                        dataTextStyle: TextStyle(
                          color: procurementInk,
                          fontSize: compactTable ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('NOM')),
                          DataColumn(label: Text('DESCRIPTION')),
                          DataColumn(label: Text('TVA')),
                          DataColumn(label: Text('ACTION')),
                        ],
                        rows: [
                          for (final category in _categories)
                            _buildRow(category),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  DataRow _buildRow(ProcurementCategory category) {
    return DataRow(
      cells: [
        DataCell(Text('${category.idCategorie}')),
        DataCell(Text(category.displayName)),
        DataCell(
          SizedBox(
            width: 260,
            child: Text(
              category.description.isEmpty ? '-' : category.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(category.vatLabel)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Modifier',
                onPressed: () => _showEditDialog(category),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: () => _deleteCategory(category),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget qui affiche le dialogue toast de modification de categorie.
class _CategoryEditToastDialog extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementCategory initialCategory;
  final String initialVat;
  final bool isBottomSheet;

  const _CategoryEditToastDialog({
    required this.initialCategory,
    required this.initialVat,
    this.isBottomSheet = false,
  });

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<_CategoryEditToastDialog> createState() =>
      _CategoryEditToastDialogState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour le dialogue toast de modification de categorie.
class _CategoryEditToastDialogState extends State<_CategoryEditToastDialog> {
  // Configuration, dependances et etat local de l'interface.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vatController;

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCategory.displayName,
    );
    _descriptionController = TextEditingController(
      text: widget.initialCategory.description,
    );
    _vatController = TextEditingController(text: widget.initialVat);
  }

  /// Libere les controleurs et les ecouteurs avant la destruction du widget.
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _vatController.dispose();
    super.dispose();
  }

  // Actions utilisateur et traitements asynchrones.

  /// Soumet les donnees actuelles du formulaire.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      ProcurementCategoryUpsertPayload(
        nomCategorie: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        tauxTVA: double.parse(_vatController.text.replaceAll(',', '.').trim()),
      ),
    );
  }

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < 560;
    final surface = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(phone ? 18 : 20),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          phone ? 18 : 24,
          phone ? 18 : 20,
          phone ? 18 : 24,
          phone ? 18 : 22,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Modifier la categorie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: procurementInk,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la categorie',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de la categorie est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Taux de TVA (%)'),
                validator: (value) {
                  final raw = value?.replaceAll(',', '.').trim() ?? '';
                  final parsed = double.tryParse(raw);
                  if (raw.isEmpty) {
                    return 'Le taux de TVA est requis';
                  }
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'Taux TVA invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              phone
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _submit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Mettre a jour'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Mettre a jour'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );

    if (widget.isBottomSheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          MediaQuery.viewInsetsOf(context).bottom > 0
              ? MediaQuery.viewInsetsOf(context).bottom
              : 12,
        ),
        child: SafeArea(top: false, child: surface),
      );
    }

    return AlertDialog(
      insetPadding: EdgeInsets.all(phone ? 12 : 20),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(width: 520, child: surface),
    );
  }
}
