class ProduitOption {
  final int idProduit;
  final String libelle;
  final double prixVente;
  final int quantiteStock;
  final String status;
  final String uniteMesure;

  ProduitOption({
    required this.idProduit,
    required this.libelle,
    required this.prixVente,
    required this.quantiteStock,
    required this.status,
    required this.uniteMesure,
  });

  factory ProduitOption.fromJson(Map<String, dynamic> json) {
    return ProduitOption(
      idProduit: _readInt(json, ['idProduit', 'id']),
      libelle: _readString(json, ['libelle', 'nom', 'name']),
      prixVente: _readDouble(json, ['prixVente', 'prix', 'prixUnitaire']),
      quantiteStock: _readInt(json, ['quantiteStock', 'stock']),
      status: _readString(json, ['status', 'statut'], fallback: 'INCONNU'),
      uniteMesure: _readString(json, ['uniteMesure', 'unite'], fallback: '-'),
    );
  }
}

class CommandeClientInfo {
  final int idClient;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String adresse;
  final String typeClient;

  CommandeClientInfo({
    required this.idClient,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.typeClient,
  });

  String get fullName {
    final value = '$prenom $nom'.trim();
    return value.isEmpty ? 'Client #$idClient' : value;
  }

  factory CommandeClientInfo.fromJson(Map<String, dynamic> json) {
    return CommandeClientInfo(
      idClient: _readInt(json, ['idClient', 'id', 'clientId']),
      nom: _readString(json, ['nom']),
      prenom: _readString(json, ['prenom']),
      email: _readString(json, ['email']),
      telephone: _readString(json, ['telephone']),
      adresse: _readString(json, ['adresse']),
      typeClient: _readString(json, ['typeClient', 'type']),
    );
  }
}

class CommandeProduitDetail {
  final int produitId;
  final String libelle;
  final double prixUnitaire;
  final int quantite;
  final double sousTotal;
  final String categorieNom;

  CommandeProduitDetail({
    required this.produitId,
    required this.libelle,
    required this.prixUnitaire,
    required this.quantite,
    required this.sousTotal,
    required this.categorieNom,
  });

  factory CommandeProduitDetail.fromJson(Map<String, dynamic> json) {
    return CommandeProduitDetail(
      produitId: _readInt(json, ['produitId', 'id']),
      libelle: _readString(json, ['libelle', 'produitLibelle', 'nom']),
      prixUnitaire: _readDouble(json, ['prixUnitaire', 'prix']),
      quantite: _readInt(json, ['quantite']),
      sousTotal: _readDouble(json, ['sousTotal', 'totalLigne']),
      categorieNom: _readString(json, [
        'categorieNom',
        'categorie',
      ], fallback: '-'),
    );
  }
}

class CommandeModel {
  final int idCommandeClient;
  final String referenceCommandeClient;
  final CommandeClientInfo? client;
  final String statut;
  final String statutDisplay;
  final String dateCommande;
  final String dateCommandeFormatted;
  final double sousTotal;
  final double tauxRemise;
  final double total;
  final List<CommandeProduitDetail> produits;

  CommandeModel({
    required this.idCommandeClient,
    required this.referenceCommandeClient,
    required this.client,
    required this.statut,
    required this.statutDisplay,
    required this.dateCommande,
    required this.dateCommandeFormatted,
    required this.sousTotal,
    required this.tauxRemise,
    required this.total,
    required this.produits,
  });

  bool get canEdit => statut.toUpperCase() == 'EN_ATTENTE';
  bool get canCancel => statut.toUpperCase() == 'EN_ATTENTE';

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    final rawClient = json['client'];
    final rawProduits = json['produits'];
    final fallbackDate = _readString(json, ['dateCommande']);

    return CommandeModel(
      idCommandeClient: _readInt(json, ['idCommandeClient', 'id']),
      referenceCommandeClient: _readString(json, [
        'referenceCommandeClient',
        'reference',
      ], fallback: '-'),
      client: rawClient is Map<String, dynamic>
          ? CommandeClientInfo.fromJson(rawClient)
          : null,
      statut: _readString(json, ['statut'], fallback: 'EN_ATTENTE'),
      statutDisplay: _readString(json, [
        'statutDisplay',
        'statut',
      ], fallback: 'En attente'),
      dateCommande: fallbackDate,
      dateCommandeFormatted: _readString(json, [
        'dateCommandeFormatted',
      ], fallback: fallbackDate.isEmpty ? '-' : fallbackDate),
      sousTotal: _readDouble(json, ['sousTotal']),
      tauxRemise: _readDouble(json, ['tauxRemise', 'remiseTotale']),
      total: _readDouble(json, ['total']),
      produits: rawProduits is List
          ? rawProduits
                .whereType<Map<String, dynamic>>()
                .map(CommandeProduitDetail.fromJson)
                .toList()
          : <CommandeProduitDetail>[],
    );
  }
}

class CommandeProduitPayload {
  final int produitId;
  final int quantite;
  final double? prixUnitaire;
  final int? idLigne;

  CommandeProduitPayload({
    required this.produitId,
    required this.quantite,
    this.prixUnitaire,
    this.idLigne,
  });

  Map<String, dynamic> toCreateJson() {
    return {
      'produitId': produitId,
      'quantite': quantite,
      if (prixUnitaire != null) 'prixUnitaire': prixUnitaire,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (idLigne != null) 'id': idLigne,
      'produitId': produitId,
      'quantite': quantite,
      if (prixUnitaire != null) 'prixUnitaire': prixUnitaire,
    };
  }
}

class CommandeCreatePayload {
  final int clientId;
  final List<CommandeProduitPayload> produits;
  final double remiseTotale;

  CommandeCreatePayload({
    required this.clientId,
    required this.produits,
    this.remiseTotale = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'produits': produits.map((p) => p.toCreateJson()).toList(),
      'remiseTotale': remiseTotale,
    };
  }
}

class CommandeUpdatePayload {
  final List<CommandeProduitPayload> produits;
  final String? statut;
  final int? clientId;
  final String? clientAdresse;
  final String? clientTelephone;
  final String? clientEmail;

  CommandeUpdatePayload({
    required this.produits,
    this.statut,
    this.clientId,
    this.clientAdresse,
    this.clientTelephone,
    this.clientEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      if (statut != null && statut!.trim().isNotEmpty) 'statut': statut!.trim(),
      if (clientId != null) 'clientId': clientId,
      if (clientAdresse != null && clientAdresse!.trim().isNotEmpty)
        'clientAdresse': clientAdresse!.trim(),
      if (clientTelephone != null && clientTelephone!.trim().isNotEmpty)
        'clientTelephone': clientTelephone!.replaceAll(RegExp(r'\s+'), ''),
      if (clientEmail != null && clientEmail!.trim().isNotEmpty)
        'clientEmail': clientEmail!.trim().toLowerCase(),
      'produits': produits.map((p) => p.toUpdateJson()).toList(),
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
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}
