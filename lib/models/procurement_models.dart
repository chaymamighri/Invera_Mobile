import 'dart:typed_data';

class ProcurementCategory {
  final int idCategorie;
  final String nomCategorie;
  final String description;
  final double tauxTVA;

  const ProcurementCategory({
    required this.idCategorie,
    required this.nomCategorie,
    required this.description,
    required this.tauxTVA,
  });

  String get displayName =>
      nomCategorie.trim().isEmpty ? 'Categorie #$idCategorie' : nomCategorie;

  factory ProcurementCategory.fromJson(Map<String, dynamic> json) {
    return ProcurementCategory(
      idCategorie: _readInt(json, ['idCategorie', 'id']),
      nomCategorie: _readString(json, ['nomCategorie', 'libelle', 'nom']),
      description: _readString(json, ['description']),
      tauxTVA: _readDouble(json, ['tauxTVA', 'tauxTva'], fallback: 0),
    );
  }
}

class ProcurementSupplier {
  final int idFournisseur;
  final String nomFournisseur;
  final String email;
  final String adresse;
  final String telephone;
  final String ville;
  final String pays;
  final bool actif;

  const ProcurementSupplier({
    required this.idFournisseur,
    required this.nomFournisseur,
    required this.email,
    required this.adresse,
    required this.telephone,
    required this.ville,
    required this.pays,
    required this.actif,
  });

  String get displayName => nomFournisseur.trim().isEmpty
      ? 'Fournisseur #$idFournisseur'
      : nomFournisseur;

  String get fullName => displayName;

  String get subtitle {
    final parts = <String>[
      if (email.trim().isNotEmpty) email.trim(),
      if (telephone.trim().isNotEmpty) telephone.trim(),
      if (ville.trim().isNotEmpty) ville.trim(),
    ];
    return parts.join(' • ');
  }

  factory ProcurementSupplier.fromJson(Map<String, dynamic> json) {
    return ProcurementSupplier(
      idFournisseur: _readInt(json, ['idFournisseur', 'id']),
      nomFournisseur: _readString(json, ['nomFournisseur', 'nom']),
      email: _readString(json, ['email']),
      adresse: _readString(json, ['adresse']),
      telephone: _readString(json, ['telephone']),
      ville: _readString(json, ['ville']),
      pays: _readString(json, ['pays']),
      actif: _readBool(json, ['actif', 'active'], fallback: true),
    );
  }
}

class ProcurementProduct {
  final int idProduit;
  final String libelle;
  final double prixVente;
  final double prixAchat;
  final ProcurementCategory? categorie;
  final int quantiteStock;
  final String status;
  final String uniteMesure;
  final bool active;
  final int seuilMinimum;
  final String imageUrl;
  final double? remiseTemporaire;

  const ProcurementProduct({
    required this.idProduit,
    required this.libelle,
    required this.prixVente,
    required this.prixAchat,
    required this.categorie,
    required this.quantiteStock,
    required this.status,
    required this.uniteMesure,
    required this.active,
    required this.seuilMinimum,
    required this.imageUrl,
    required this.remiseTemporaire,
  });

  String get displayName =>
      libelle.trim().isEmpty ? 'Produit #$idProduit' : libelle;

  String get categorieLabel => categorie?.displayName ?? 'Sans categorie';

  String get stockStatusLabel {
    switch (status.toUpperCase()) {
      case 'EN_STOCK':
        return 'En stock';
      case 'FAIBLE':
        return 'Stock faible';
      case 'CRITIQUE':
        return 'Stock critique';
      case 'RUPTURE':
        return 'Rupture';
      default:
        return status;
    }
  }

  String get unitLabel {
    switch (uniteMesure.toUpperCase()) {
      case 'PIECE':
        return 'Piece';
      case 'KILOGRAMME':
        return 'Kilogramme';
      case 'GRAMME':
        return 'Gramme';
      case 'LITRE':
        return 'Litre';
      case 'MILLILITRE':
        return 'Millilitre';
      case 'METRE':
        return 'Metre';
      default:
        return uniteMesure;
    }
  }

  bool get isLowStock =>
      status.toUpperCase() == 'FAIBLE' ||
      status.toUpperCase() == 'CRITIQUE' ||
      status.toUpperCase() == 'RUPTURE';

  ProcurementProduct copyWith({
    int? idProduit,
    String? libelle,
    double? prixVente,
    double? prixAchat,
    ProcurementCategory? categorie,
    int? quantiteStock,
    String? status,
    String? uniteMesure,
    bool? active,
    int? seuilMinimum,
    String? imageUrl,
    double? remiseTemporaire,
  }) {
    return ProcurementProduct(
      idProduit: idProduit ?? this.idProduit,
      libelle: libelle ?? this.libelle,
      prixVente: prixVente ?? this.prixVente,
      prixAchat: prixAchat ?? this.prixAchat,
      categorie: categorie ?? this.categorie,
      quantiteStock: quantiteStock ?? this.quantiteStock,
      status: status ?? this.status,
      uniteMesure: uniteMesure ?? this.uniteMesure,
      active: active ?? this.active,
      seuilMinimum: seuilMinimum ?? this.seuilMinimum,
      imageUrl: imageUrl ?? this.imageUrl,
      remiseTemporaire: remiseTemporaire ?? this.remiseTemporaire,
    );
  }

  factory ProcurementProduct.fromJson(Map<String, dynamic> json) {
    final rawCategorie = json['categorie'];

    return ProcurementProduct(
      idProduit: _readInt(json, ['idProduit', 'id']),
      libelle: _readString(json, ['libelle', 'nom']),
      prixVente: _readDouble(json, ['prixVente', 'prix']),
      prixAchat: _readDouble(json, ['prixAchat']),
      categorie: rawCategorie is Map<String, dynamic>
          ? ProcurementCategory.fromJson(rawCategorie)
          : null,
      quantiteStock: _readInt(json, ['quantiteStock', 'stock']),
      status: _readString(json, ['status', 'statut'], fallback: 'EN_STOCK'),
      uniteMesure: _readString(json, [
        'uniteMesure',
        'unite',
      ], fallback: 'PIECE'),
      active: _readBool(json, ['active', 'actif'], fallback: true),
      seuilMinimum: _readInt(json, ['seuilMinimum'], fallback: 0),
      imageUrl: _readString(json, ['imageUrl']),
      remiseTemporaire: _readNullableDouble(json, [
        'remiseTemporaire',
        'remise',
      ]),
    );
  }
}

class ProcurementOrderLine {
  final int? idLigneCommandeFournisseur;
  final int produitId;
  final String produitLibelle;
  final String produitReference;
  final int quantite;
  final double prixUnitaire;
  final double sousTotalHT;
  final double montantTVA;
  final double sousTotalTTC;
  final int quantiteRecue;
  final String notes;
  final String categorieNom;

  const ProcurementOrderLine({
    required this.idLigneCommandeFournisseur,
    required this.produitId,
    required this.produitLibelle,
    required this.produitReference,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotalHT,
    required this.montantTVA,
    required this.sousTotalTTC,
    required this.quantiteRecue,
    required this.notes,
    required this.categorieNom,
  });

  String get displayName =>
      produitLibelle.trim().isEmpty ? 'Produit #$produitId' : produitLibelle;

  String get libelle => displayName;
  double get sousTotal => sousTotalHT;
  double get total => sousTotalTTC;

  factory ProcurementOrderLine.fromJson(Map<String, dynamic> json) {
    return ProcurementOrderLine(
      idLigneCommandeFournisseur: _readNullableInt(json, [
        'idLigneCommandeFournisseur',
        'id',
      ]),
      produitId: _readInt(json, ['produitId', 'idProduit']),
      produitLibelle: _readString(json, ['produitLibelle', 'libelle']),
      produitReference: _readString(json, [
        'produitReference',
        'reference',
      ], fallback: '-'),
      quantite: _readInt(json, ['quantite']),
      prixUnitaire: _readDouble(json, ['prixUnitaire']),
      sousTotalHT: _readDouble(json, ['sousTotalHT']),
      montantTVA: _readDouble(json, ['montantTVA']),
      sousTotalTTC: _readDouble(json, ['sousTotalTTC']),
      quantiteRecue: _readInt(json, ['quantiteRecue'], fallback: 0),
      notes: _readString(json, ['notes']),
      categorieNom: _readString(json, [
        'categorieNom',
        'categorie',
      ], fallback: '-'),
    );
  }
}

class ProcurementOrder {
  final int idCommandeFournisseur;
  final String numeroCommande;
  final DateTime? dateCommande;
  final DateTime? dateLivraisonPrevue;
  final DateTime? dateLivraisonReelle;
  final String adresseLivraison;
  final ProcurementSupplier? fournisseur;
  final String statut;
  final double totalHT;
  final double totalTVA;
  final double totalTTC;
  final double tauxTVA;
  final bool actif;
  final List<ProcurementOrderLine> lignesCommande;

  const ProcurementOrder({
    required this.idCommandeFournisseur,
    required this.numeroCommande,
    required this.dateCommande,
    required this.dateLivraisonPrevue,
    required this.dateLivraisonReelle,
    required this.adresseLivraison,
    required this.fournisseur,
    required this.statut,
    required this.totalHT,
    required this.totalTVA,
    required this.totalTTC,
    required this.tauxTVA,
    required this.actif,
    required this.lignesCommande,
  });

  String get displayNumber => numeroCommande.trim().isEmpty
      ? 'Commande #$idCommandeFournisseur'
      : numeroCommande;

  String get referenceCommande => displayNumber;
  String get statutDisplay => statusLabel;
  String get dateCommandeFormatted =>
      _formatDateValue(dateCommande, withTime: true);
  String get dateLivraisonPrevueFormatted =>
      _formatDateValue(dateLivraisonPrevue);
  String get dateLivraisonReelleFormatted =>
      _formatDateValue(dateLivraisonReelle, withTime: true);
  String get partenaireNom => fournisseur?.displayName ?? 'Fournisseur';
  double get sousTotal => totalHT;
  double get total => totalTTC;
  double get tauxRemise => 0;
  List<ProcurementOrderLine> get produits => lignesCommande;
  int get produitsCount => produits.length;

  int get itemCount =>
      lignesCommande.fold<int>(0, (sum, line) => sum + line.quantite);

  String get statusLabel {
    switch (statut.toUpperCase()) {
      case 'BROUILLON':
        return 'Brouillon';
      case 'VALIDEE':
        return 'Validee';
      case 'ENVOYEE':
        return 'Envoyee';
      case 'RECUE':
        return 'Recue';
      case 'FACTUREE':
        return 'Facturee';
      case 'ANNULEE':
        return 'Annulee';
      default:
        return statut;
    }
  }

  bool get canEdit => statut.toUpperCase() == 'BROUILLON' && actif;
  bool get canDelete =>
      (statut.toUpperCase() == 'BROUILLON' ||
          statut.toUpperCase() == 'ANNULEE') &&
      actif;
  bool get canValidate => statut.toUpperCase() == 'BROUILLON' && actif;
  bool get canSend => statut.toUpperCase() == 'VALIDEE' && actif;
  bool get canReceive => statut.toUpperCase() == 'ENVOYEE' && actif;
  bool get canInvoice => statut.toUpperCase() == 'RECUE' && actif;
  bool get canCancel =>
      statut.toUpperCase() != 'RECUE' &&
      statut.toUpperCase() != 'FACTUREE' &&
      actif;
  bool get canRestore => !actif;

  factory ProcurementOrder.fromJson(Map<String, dynamic> json) {
    final rawSupplier = json['fournisseur'];
    final rawLines = json['lignesCommande'];

    return ProcurementOrder(
      idCommandeFournisseur: _readInt(json, ['idCommandeFournisseur', 'id']),
      numeroCommande: _readString(json, ['numeroCommande', 'reference']),
      dateCommande: _readDate(json, ['dateCommande']),
      dateLivraisonPrevue: _readDate(json, ['dateLivraisonPrevue']),
      dateLivraisonReelle: _readDate(json, ['dateLivraisonReelle']),
      adresseLivraison: _readString(json, ['adresseLivraison']),
      fournisseur: rawSupplier is Map<String, dynamic>
          ? ProcurementSupplier.fromJson(rawSupplier)
          : null,
      statut: _readString(json, ['statut'], fallback: 'BROUILLON'),
      totalHT: _readDouble(json, ['totalHT']),
      totalTVA: _readDouble(json, ['totalTVA']),
      totalTTC: _readDouble(json, ['totalTTC']),
      tauxTVA: _readDouble(json, ['tauxTVA'], fallback: 19),
      actif: _readBool(json, ['actif', 'active'], fallback: true),
      lignesCommande: rawLines is List
          ? rawLines
                .whereType<Map<String, dynamic>>()
                .map(ProcurementOrderLine.fromJson)
                .toList()
          : <ProcurementOrderLine>[],
    );
  }
}

class ProductUpsertPayload {
  final String libelle;
  final double prixVente;
  final double prixAchat;
  final int categorieId;
  final int quantiteStock;
  final int seuilMinimum;
  final String uniteMesure;
  final double? remiseTemporaire;
  final bool active;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final String? imageMimeType;

  const ProductUpsertPayload({
    required this.libelle,
    required this.prixVente,
    required this.prixAchat,
    required this.categorieId,
    required this.quantiteStock,
    required this.seuilMinimum,
    required this.uniteMesure,
    required this.remiseTemporaire,
    required this.active,
    this.imageBytes,
    this.imageFileName,
    this.imageMimeType,
  });

  bool get hasImageUpload =>
      imageBytes != null &&
      imageBytes!.isNotEmpty &&
      imageFileName != null &&
      imageFileName!.trim().isNotEmpty;

  Map<String, String> toMultipartFields() {
    final fields = <String, String>{
      'libelle': libelle.trim(),
      'prixVente': prixVente.toString(),
      'prixAchat': prixAchat.toString(),
      'categorieId': categorieId.toString(),
      'quantiteStock': quantiteStock.toString(),
      'seuilMinimum': seuilMinimum.toString(),
      'uniteMesure': uniteMesure.trim().toUpperCase(),
      'active': active.toString(),
    };

    if (remiseTemporaire != null) {
      fields['remiseTemporaire'] = remiseTemporaire.toString();
    }

    return fields;
  }
}

class ProcurementOrderLinePayload {
  final int produitId;
  final int quantite;
  final double prixUnitaire;

  const ProcurementOrderLinePayload({
    required this.produitId,
    required this.quantite,
    required this.prixUnitaire,
  });

  Map<String, dynamic> toJson() {
    return {
      'produitId': produitId,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
    };
  }
}

class ProcurementOrderCreatePayload {
  final int fournisseurId;
  final DateTime dateLivraisonPrevue;
  final String adresseLivraison;
  final List<ProcurementOrderLinePayload> lignesCommande;

  const ProcurementOrderCreatePayload({
    required this.fournisseurId,
    required this.dateLivraisonPrevue,
    required this.adresseLivraison,
    required this.lignesCommande,
  });

  Map<String, dynamic> toJson() {
    return {
      'fournisseur': {'idFournisseur': fournisseurId},
      'dateLivraisonPrevue': dateLivraisonPrevue.toIso8601String(),
      'adresseLivraison': adresseLivraison.trim(),
      'lignesCommande': lignesCommande.map((line) => line.toJson()).toList(),
    };
  }
}

class ProcurementOrderUpdatePayload {
  final DateTime dateLivraisonPrevue;
  final String adresseLivraison;

  const ProcurementOrderUpdatePayload({
    required this.dateLivraisonPrevue,
    required this.adresseLivraison,
  });

  Map<String, dynamic> toJson() {
    return {
      'dateLivraisonPrevue': dateLivraisonPrevue.toIso8601String(),
      'adresseLivraison': adresseLivraison.trim(),
    };
  }
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

double _readDouble(
  Map<String, dynamic> json,
  List<String> keys, {
  double fallback = 0,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}

double? _readNullableDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

bool _readBool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    if (value is num) return value != 0;
  }
  return fallback;
}

DateTime? _readDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String _formatDateValue(DateTime? value, {bool withTime = false}) {
  if (value == null) return '-';

  final day = _twoDigits(value.day);
  final month = _twoDigits(value.month);
  final year = value.year.toString();

  if (!withTime) return '$day/$month/$year';

  final hour = _twoDigits(value.hour);
  final minute = _twoDigits(value.minute);
  return '$day/$month/$year $hour:$minute';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
