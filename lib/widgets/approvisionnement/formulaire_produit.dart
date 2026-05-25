import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:invera_mobile/config/api.dart';
import 'package:invera_mobile/models/approvisionnement.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/commun.dart';
import 'package:invera_mobile/widgets/approvisionnement/role_utilisateur.dart';

class ProductFormDialog extends StatefulWidget {
  final List<ProcurementCategory> categories;
  final List<ProcurementSupplier> suppliers;
  final ProcurementProduct? initialProduct;

  const ProductFormDialog({
    super.key,
    required this.categories,
    required this.suppliers,
    required this.initialProduct,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  static const int _maxImageBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _discountController;

  int? _categoryId;
  int? _supplierId;
  String _unit = 'PIECE';
  bool _active = true;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImageMimeType;
  bool _pickingImage = false;

  bool get _isEditing => widget.initialProduct != null;
  bool get _discountDisabled =>
      ProcurementRoleStore.instance.role ==
      ProcurementUserRole.responsableAchat;
  String? get _existingImageUrl =>
      ApiConfig.resolveMediaUrl(widget.initialProduct?.imageUrl);

  @override
  void initState() {
    super.initState();
    final product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.displayName ?? '');
    _salePriceController = TextEditingController(
      text: product != null ? product.prixVente.toStringAsFixed(3) : '',
    );
    _purchasePriceController = TextEditingController(
      text: product != null ? product.prixAchat.toStringAsFixed(3) : '',
    );
    _stockController = TextEditingController(
      text: product != null ? '${product.quantiteStock}' : '0',
    );
    _thresholdController = TextEditingController(
      text: product != null ? '${product.seuilMinimum}' : '3',
    );
    _discountController = TextEditingController(
      text: product?.remiseTemporaire?.toStringAsFixed(1) ?? '0',
    );

    _categoryId =
        product?.categorie?.idCategorie ??
        (widget.categories.isNotEmpty
            ? widget.categories.first.idCategorie
            : null);
    _supplierId = _resolveInitialSupplierId(product);
    _unit = product?.uniteMesure.toUpperCase() ?? 'PIECE';
    _active = product?.active ?? true;
  }

  int? _resolveInitialSupplierId(ProcurementProduct? product) {
    if (product?.fournisseurId != null) return product!.fournisseurId;
    if (widget.suppliers.length == 1) {
      return widget.suppliers.first.idFournisseur;
    }
    return null;
  }

  ProcurementSupplier? get _selectedSupplier {
    if (_supplierId == null) return null;
    for (final supplier in widget.suppliers) {
      if (supplier.idFournisseur == _supplierId) return supplier;
    }
    return null;
  }

  Future<void> _pickImage() async {
    setState(() {
      _pickingImage = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showInlineError('Impossible de lire l image selectionnee.');
        return;
      }
      if (bytes.length > _maxImageBytes) {
        _showInlineError('Image trop volumineuse (max 5MB).');
        return;
      }

      final mimeType = _detectMimeType(file.extension);
      if (!const {
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
      }.contains(mimeType)) {
        _showInlineError('Format non supporte.');
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name.trim().isEmpty
            ? 'product-image.jpg'
            : file.name;
        _selectedImageMimeType = mimeType;
      });
    } catch (_) {
      if (!mounted) return;
      _showInlineError('Erreur lors de la selection de l image.');
    } finally {
      if (mounted) {
        setState(() {
          _pickingImage = false;
        });
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _selectedImageMimeType = null;
    });
  }

  String _detectMimeType(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  void _showInlineError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: procurementDanger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7DEEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: procurementPrimary, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD7DEEA)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: procurementDanger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: procurementDanger, width: 1.8),
      ),
    );
  }

  Widget _buildFieldTitle(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: procurementInk,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: procurementDanger),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: procurementPrimaryDark),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              color: procurementInk,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard() {
    final supplier = _selectedSupplier;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldTitle('Fournisseur', required: true),
          DropdownButtonFormField<int>(
            initialValue: _supplierId,
            decoration: _inputDecoration(
              label: '',
              hint: '-- Sélectionner un fournisseur --',
            ).copyWith(labelText: null),
            items: widget.suppliers
                .map(
                  (item) => DropdownMenuItem<int>(
                    value: item.idFournisseur,
                    child: Text(
                      item.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _supplierId = value;
              });
            },
            validator: (value) =>
                value == null ? 'Le fournisseur est requis' : null,
          ),
          if (supplier != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations du fournisseur',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supplier.email.isEmpty
                        ? 'Email non renseigné'
                        : supplier.email,
                    style: const TextStyle(color: procurementInk, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier.telephone.isEmpty
                        ? 'Téléphone non renseigné'
                        : supplier.telephone,
                    style: const TextStyle(color: procurementInk, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    supplier.adresse.isEmpty
                        ? 'Adresse non renseignée'
                        : supplier.adresse,
                    style: const TextStyle(
                      color: procurementMuted,
                      fontSize: 12.5,
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

  Widget _buildImagePreview() {
    final hasExistingImage = _existingImageUrl != null;
    final fallback = Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7DEEA)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF64748B),
        size: 34,
      ),
    );

    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          _selectedImageBytes!,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
        ),
      );
    }

    if (hasExistingImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _existingImageUrl!,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return fallback;
  }

  Widget _buildImageSection() {
    final hasExistingImage = _existingImageUrl != null;
    final helperText = _selectedImageBytes != null
        ? _selectedImageName!
        : hasExistingImage
        ? 'Image actuelle chargee. Choisissez-en une autre pour la remplacer.'
        : 'Ajoutez une image pour afficher le produit clairement dans le catalogue.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldTitle('Image du produit'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helperText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: procurementMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickingImage ? null : _pickImage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: procurementPrimaryDark,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          _pickingImage
                              ? Icons.hourglass_top_rounded
                              : Icons.upload_file_outlined,
                        ),
                        label: Text(
                          _selectedImageBytes != null || hasExistingImage
                              ? 'Changer image'
                              : 'Choisir image',
                        ),
                      ),
                      if (_selectedImageBytes != null)
                        TextButton.icon(
                          onPressed: _clearSelectedImage,
                          icon: const Icon(Icons.close),
                          label: const Text('Annuler'),
                        ),
                    ],
                  ),
                ],
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 14),
                    details,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePreview(),
                  const SizedBox(width: 14),
                  Expanded(child: details),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _supplierId == null) return;

    final payload = ProductUpsertPayload(
      libelle: _nameController.text.trim(),
      prixVente: double.parse(_salePriceController.text.replaceAll(',', '.')),
      prixAchat: double.parse(
        _purchasePriceController.text.replaceAll(',', '.'),
      ),
      categorieId: _categoryId!,
      quantiteStock: _isEditing ? int.parse(_stockController.text) : 0,
      seuilMinimum: int.parse(_thresholdController.text),
      uniteMesure: _unit,
      remiseTemporaire: _discountController.text.trim().isEmpty
          ? null
          : double.parse(_discountController.text.replaceAll(',', '.')),
      active: _active,
      fournisseurId: _supplierId,
      includeQuantiteStock: !_isEditing,
      imageBytes: _selectedImageBytes,
      imageFileName: _selectedImageName,
      imageMimeType: _selectedImageMimeType,
    );

    Navigator.pop(context, payload);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Modifier le produit' : 'Nouveau produit';
    final primaryLabel = _isEditing
        ? 'Modifier le produit'
        : 'Créer le produit';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: procurementInk,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 20,
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Informations générales'),
                            _buildFieldTitle('Libellé', required: true),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration(
                                label: '',
                                hint: 'Nom du produit',
                              ).copyWith(labelText: null),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Le libellé est requis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle(
                                        'Prix d\'achat DT',
                                        required: true,
                                      ),
                                      TextFormField(
                                        controller: _purchasePriceController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _inputDecoration(
                                          label: '',
                                          hint: '0',
                                        ).copyWith(labelText: null),
                                        validator: (value) {
                                          final parsed = double.tryParse(
                                            (value ?? '').replaceAll(',', '.'),
                                          );
                                          if (parsed == null || parsed <= 0) {
                                            return 'Le prix d\'achat doit être supérieur à 0';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle(
                                        'Prix de vente DT',
                                        required: true,
                                      ),
                                      TextFormField(
                                        controller: _salePriceController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _inputDecoration(
                                          label: '',
                                          hint: '0',
                                        ).copyWith(labelText: null),
                                        validator: (value) {
                                          final parsed = double.tryParse(
                                            (value ?? '').replaceAll(',', '.'),
                                          );
                                          if (parsed == null || parsed <= 0) {
                                            return 'Le prix de vente doit être supérieur à 0';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildFieldTitle('Catégorie', required: true),
                            DropdownButtonFormField<int>(
                              initialValue: _categoryId,
                              decoration: _inputDecoration(
                                label: '',
                                hint: 'Sélectionner une catégorie',
                              ).copyWith(labelText: null),
                              items: widget.categories
                                  .map(
                                    (category) => DropdownMenuItem<int>(
                                      value: category.idCategorie,
                                      child: Text(category.displayName),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _categoryId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'La catégorie est requise'
                                  : null,
                            ),
                            const SizedBox(height: 28),
                            _buildSectionTitle(
                              'Fournisseur',
                              icon: Icons.apartment_rounded,
                            ),
                            _buildSupplierCard(),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Gestion du stock'),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle('Stock actuel'),
                                      TextFormField(
                                        controller: _stockController,
                                        enabled: false,
                                        decoration:
                                            _inputDecoration(
                                              label: '',
                                              helper: 'Géré automatiquement',
                                            ).copyWith(
                                              labelText: null,
                                              fillColor: const Color(
                                                0xFFF1F5F9,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle('Seuil minimum'),
                                      TextFormField(
                                        controller: _thresholdController,
                                        keyboardType: TextInputType.number,
                                        decoration: _inputDecoration(
                                          label: '',
                                        ).copyWith(labelText: null),
                                        validator: (value) {
                                          final parsed = int.tryParse(
                                            value ?? '',
                                          );
                                          if (parsed == null || parsed < 0) {
                                            return 'Le seuil minimum doit être positif';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildFieldTitle('Unité de mesure', required: true),
                            DropdownButtonFormField<String>(
                              initialValue: _unit,
                              decoration: _inputDecoration(
                                label: '',
                              ).copyWith(labelText: null),
                              items: const [
                                DropdownMenuItem(
                                  value: 'PIECE',
                                  child: Text('Pièce'),
                                ),
                                DropdownMenuItem(
                                  value: 'KILOGRAMME',
                                  child: Text('Kilogramme'),
                                ),
                                DropdownMenuItem(
                                  value: 'GRAMME',
                                  child: Text('Gramme'),
                                ),
                                DropdownMenuItem(
                                  value: 'LITRE',
                                  child: Text('Litre'),
                                ),
                                DropdownMenuItem(
                                  value: 'MILLILITRE',
                                  child: Text('Millilitre'),
                                ),
                                DropdownMenuItem(
                                  value: 'METRE',
                                  child: Text('Mètre'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _unit = value ?? 'PIECE';
                                });
                              },
                            ),
                            const SizedBox(height: 28),
                            _buildSectionTitle('Informations commerciales'),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle('Remise temporaire (%)'),
                                      TextFormField(
                                        controller: _discountController,
                                        enabled: !_discountDisabled,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration:
                                            _inputDecoration(
                                              label: '',
                                              hint: '0',
                                              helper: _discountDisabled
                                                  ? 'La remise est gérée par l\'administrateur'
                                                  : null,
                                            ).copyWith(
                                              labelText: null,
                                              fillColor: _discountDisabled
                                                  ? const Color(0xFFF1F5F9)
                                                  : Colors.white,
                                            ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return null;
                                          }
                                          final parsed = double.tryParse(
                                            value.replaceAll(',', '.'),
                                          );
                                          if (parsed == null ||
                                              parsed < 0 ||
                                              parsed > 100) {
                                            return 'La remise doit être entre 0 et 100';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldTitle(
                                        'Statut',
                                        required: true,
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD7DEEA),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: RadioListTile<bool>(
                                                value: true,
                                                groupValue: _active,
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                activeColor: procurementAccent,
                                                title: const Text(
                                                  'Actif',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _active = value ?? true;
                                                  });
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child: RadioListTile<bool>(
                                                value: false,
                                                groupValue: _active,
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                activeColor: procurementDanger,
                                                title: const Text(
                                                  'Inactif',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _active = value ?? false;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _buildImageSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 14),
                        FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(primaryLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
