class ClientModel {
  final int id;
  final String nom;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? typeClient;
  final double? remise;

  ClientModel({
    required this.id,
    required this.nom,
    required this.telephone,
    this.email,
    this.adresse,
    this.typeClient,
    this.remise,
  });

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

    final nom = readString(['nom', 'name', 'raisonSociale', 'nomClient']);
    final telephone = readString(['telephone', 'phone', 'numeroTelephone']);
    final email = readString(['email']);
    final adresse = readString(['adresse', 'address']);
    final typeClient = readString(['typeClient', 'type']);

    return ClientModel(
      id: readInt(['id', 'clientId', 'idClient', 'id_client']),
      nom: nom,
      telephone: telephone,
      email: email.isEmpty ? null : email,
      adresse: adresse.isEmpty ? null : adresse,
      typeClient: typeClient.isEmpty ? null : typeClient,
      remise: readDouble(['remise', 'discount']),
    );
  }
}

class NouveauClientPayload {
  final String nom;
  final String telephone;
  final String? email;
  final String? adresse;
  final String? typeClient;

  NouveauClientPayload({
    required this.nom,
    required this.telephone,
    this.email,
    this.adresse,
    this.typeClient,
  });

  Map<String, dynamic> toJson() {
    final normalizedPhone = telephone.replaceAll(RegExp(r'\s+'), '').trim();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedType = typeClient?.trim().toUpperCase();

    return {
      'nom': nom.trim(),
      'telephone': normalizedPhone,
      if (normalizedEmail != null && normalizedEmail.isNotEmpty) 'email': normalizedEmail,
      if (adresse != null && adresse!.trim().isNotEmpty) 'adresse': adresse!.trim(),
      // Backend NouveauClientDTO expects "type"
      if (normalizedType != null && normalizedType.isNotEmpty) 'type': normalizedType,
    };
  }
}
