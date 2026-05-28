class ClientType {
  static const String particulier = 'PARTICULIER';
  static const String vip = 'VIP';
  static const String fidel = 'FIDELE';
  static const String entreprise = 'ENTREPRISE';

  static const List<String> allowedValues = <String>[
    particulier,
    vip,
    fidel,
    entreprise,
  ];

  static String normalize(String? raw, {bool fallbackToDefault = false}) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return fallbackToDefault ? particulier : '';
    }

    switch (value.toUpperCase()) {
      case 'PARTICULIER':
      case 'PARTICULER':
      case 'PARTUCULIER':
      case 'PARTUCULER':
        return particulier;
      case 'VIP':
        return vip;
      case 'FIDEL':
      case 'FIDELE':
        return fidel;
      case 'PROFESSIONNEL':
      case 'PROFESSIONNELS':
      case 'PROFESSIONNELLE':
        return entreprise;
      case 'ENTREPRISE':
      case 'ENTREPRISES':
        return entreprise;
      default:
        return fallbackToDefault ? particulier : value.toUpperCase();
    }
  }

  static String label(String? raw, {bool fallbackToDefault = false}) {
    final normalized = normalize(raw, fallbackToDefault: fallbackToDefault);
    switch (normalized) {
      case particulier:
        return 'Particulier';
      case vip:
        return 'VIP';
      case fidel:
        return 'Fidel';
      case entreprise:
        return 'Entreprise';
      default:
        if (normalized.isEmpty) {
          return fallbackToDefault ? 'Particulier' : '-';
        }
        final lower = normalized.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  static bool isAllowed(String? raw) {
    return allowedValues.contains(normalize(raw));
  }

  static int sortWeight(String? raw) {
    final normalized = normalize(raw, fallbackToDefault: true);
    final index = allowedValues.indexOf(normalized);
    return index >= 0 ? index : allowedValues.length;
  }
}

class ClientModel {
  final int id;
  final String nom;
  final String? prenom;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? typeClient;
  final String? raisonSociale;
  final String? matriculeFiscale;
  final double? remise;

  ClientModel({
    required this.id,
    required this.nom,
    this.prenom,
    required this.telephone,
    this.email,
    this.adresse,
    this.typeClient,
    this.raisonSociale,
    this.matriculeFiscale,
    this.remise,
  });

  String get fullName {
    final company = raisonSociale?.trim() ?? '';
    if (company.isNotEmpty) return company;
    final value = '${prenom ?? ''} $nom'.trim();
    return value.isEmpty ? nom : value;
  }

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return '';
    }

    int readInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return 0;
    }

    double? readDouble(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    final raisonSociale = readString([
      'raisonSociale',
      'raison_sociale',
      'companyName',
    ]);
    final nom = readString(['nom', 'name', 'raisonSociale', 'nomClient']);
    final prenom = readString(['prenom', 'firstName', 'givenName']);
    final telephone = readString(['telephone', 'phone', 'numeroTelephone']);
    final email = readString(['email']);
    final adresse = readString(['adresse', 'address']);
    final typeClient = readString(['typeClient', 'type']);
    final matriculeFiscale = readString([
      'matriculeFiscale',
      'matriculeFiscal',
      'matricule_fiscale',
    ]);
    final normalizedType = ClientType.normalize(
      typeClient,
      fallbackToDefault: true,
    );

    double? resolveRemiseForType() {
      final generic = readDouble(['remise', 'discount', 'remiseStandard']);
      switch (normalizedType) {
        case ClientType.vip:
          return readDouble([
                'remiseClientVIP',
                'remiseClientVip',
                'remise_client_vip',
              ]) ??
              generic;
        case ClientType.fidel:
          return readDouble(['remiseClientFidele', 'remise_client_fidele']) ??
              generic;
        case ClientType.entreprise:
          return readDouble([
                'remiseClientProfessionnelle',
                'remise_client_professionnelle',
              ]) ??
              generic;
        case ClientType.particulier:
        default:
          return generic;
      }
    }

    return ClientModel(
      id: readInt(['id', 'clientId', 'idClient', 'id_client']),
      nom: nom,
      prenom: prenom.isEmpty ? null : prenom,
      telephone: telephone,
      email: email.isEmpty ? null : email,
      adresse: adresse.isEmpty ? null : adresse,
      typeClient: normalizedType,
      raisonSociale: raisonSociale.isEmpty ? null : raisonSociale,
      matriculeFiscale: matriculeFiscale.isEmpty ? null : matriculeFiscale,
      remise: resolveRemiseForType(),
    );
  }
}

class NouveauClientPayload {
  final String nom;
  final String? prenom;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? typeClient;
  final String? raisonSociale;
  final String? matriculeFiscale;

  NouveauClientPayload({
    required this.nom,
    this.prenom,
    required this.telephone,
    this.email,
    this.adresse,
    this.typeClient,
    this.raisonSociale,
    this.matriculeFiscale,
  });

  Map<String, dynamic> toJson() {
    final normalizedPhone = telephone.replaceAll(RegExp(r'\s+'), '').trim();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedType = ClientType.normalize(
      typeClient,
      fallbackToDefault: true,
    );
    final normalizedRaisonSociale = raisonSociale?.trim();
    final normalizedMatricule = matriculeFiscale?.trim().toUpperCase();

    return {
      'nom': nom.trim(),
      if (prenom != null && prenom!.trim().isNotEmpty) 'prenom': prenom!.trim(),
      'telephone': normalizedPhone,
      if (normalizedEmail != null && normalizedEmail.isNotEmpty)
        'email': normalizedEmail,
      if (adresse != null && adresse!.trim().isNotEmpty)
        'adresse': adresse!.trim(),
      // Backend NouveauClientDTO expects "type"
      'type': normalizedType,
      if (normalizedType == ClientType.entreprise &&
          normalizedRaisonSociale != null &&
          normalizedRaisonSociale.isNotEmpty)
        'raisonSociale': normalizedRaisonSociale,
      if (normalizedType == ClientType.entreprise &&
          normalizedMatricule != null &&
          normalizedMatricule.isNotEmpty)
        'matriculeFiscale': normalizedMatricule,
    };
  }
}
