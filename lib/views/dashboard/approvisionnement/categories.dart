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
    final payload = await showDialog<ProcurementCategoryUpsertPayload>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CategoryEditToastDialog(
        initialCategory: category,
        initialVat: _editableVat(category.tauxTVA),
      ),
    );

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

    final isCompact = MediaQuery.sizeOf(context).width < 900;

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
              : isCompact
              ? Column(
                  children: [
                    for (final category in _categories) ...[
                      _CategoryMobileTile(
                        category: category,
                        onEdit: () => _showEditDialog(category),
                        onDelete: () => _deleteCategory(category),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('TVA')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final category in _categories) _buildRow(category),
                    ],
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

/// Widget qui affiche la tuile mobile de categorie.
class _CategoryMobileTile extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryMobileTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.displayName,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                category.vatLabel,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ID: ${category.idCategorie}',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          Text(
            category.description.isEmpty ? '-' : category.description,
            style: const TextStyle(color: Color(0xFF4B5563), height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget qui affiche le dialogue toast de modification de categorie.
class _CategoryEditToastDialog extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final ProcurementCategory initialCategory;
  final String initialVat;

  const _CategoryEditToastDialog({
    required this.initialCategory,
    required this.initialVat,
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
    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      title: const Text('Modifier la categorie'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  decoration: const InputDecoration(
                    labelText: 'Taux de TVA (%)',
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
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Mettre a jour'),
        ),
      ],
    );
  }
}
