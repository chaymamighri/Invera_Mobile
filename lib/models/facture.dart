class FactureModel {
  final int idFactureClient;
  final String referenceFactureClient;
  final int? commandeId;
  final int? clientId;
  final String statut;
  final double montantTotal;
  final String dateFactureDisplay;
  final String? clientNomComplet;
  final String? clientType;
  final String? clientEmail;
  final String? clientTelephone;
  final String? clientAdresse;
  final String? commandeReference;
  final String? commandeStatut;
  final String? commandeDateDisplay;

  FactureModel({
    required this.idFactureClient,
    required this.referenceFactureClient,
    required this.commandeId,
    required this.clientId,
    required this.statut,
    required this.montantTotal,
    required this.dateFactureDisplay,
    this.clientNomComplet,
    this.clientType,
    this.clientEmail,
    this.clientTelephone,
    this.clientAdresse,
    this.commandeReference,
    this.commandeStatut,
    this.commandeDateDisplay,
  });

  FactureModel copyWith({
    int? idFactureClient,
    String? referenceFactureClient,
    int? commandeId,
    int? clientId,
    String? statut,
    double? montantTotal,
    String? dateFactureDisplay,
    String? clientNomComplet,
    String? clientType,
    String? clientEmail,
    String? clientTelephone,
    String? clientAdresse,
    String? commandeReference,
    String? commandeStatut,
    String? commandeDateDisplay,
  }) {
    return FactureModel(
      idFactureClient: idFactureClient ?? this.idFactureClient,
      referenceFactureClient:
          referenceFactureClient ?? this.referenceFactureClient,
      commandeId: commandeId ?? this.commandeId,
      clientId: clientId ?? this.clientId,
      statut: statut ?? this.statut,
      montantTotal: montantTotal ?? this.montantTotal,
      dateFactureDisplay: dateFactureDisplay ?? this.dateFactureDisplay,
      clientNomComplet: clientNomComplet ?? this.clientNomComplet,
      clientType: clientType ?? this.clientType,
      clientEmail: clientEmail ?? this.clientEmail,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      clientAdresse: clientAdresse ?? this.clientAdresse,
      commandeReference: commandeReference ?? this.commandeReference,
      commandeStatut: commandeStatut ?? this.commandeStatut,
      commandeDateDisplay: commandeDateDisplay ?? this.commandeDateDisplay,
    );
  }

  factory FactureModel.fromJson(Map<String, dynamic> json) {
    final rawCommande = json['commande'];
    final rawClient = json['client'];

    var commandeId = _readIntNullable(json, [
      'commandeId',
      'idCommande',
      'idCommandeClient',
    ]);
    var clientId = _readIntNullable(json, ['clientId', 'idClient']);

    if (commandeId == null && rawCommande is Map<String, dynamic>) {
      commandeId = _readIntNullable(rawCommande, [
        'idCommandeClient',
        'commandeId',
        'id',
      ]);
    }

    if (clientId == null && rawClient is Map<String, dynamic>) {
      clientId = _readIntNullable(rawClient, ['idClient', 'clientId', 'id']);
    }

    String? clientNomComplet;
    String? clientType;
    String? clientEmail;
    String? clientTelephone;
    String? clientAdresse;
    if (rawClient is Map<String, dynamic>) {
      final prenom = _readString(rawClient, ['prenom']);
      final nom = _readString(rawClient, ['nom']);
      final raisonSociale = _readString(rawClient, [
        'raisonSociale',
        'raison_sociale',
      ]);
      final resolvedType = _readString(rawClient, ['typeClient', 'type']);
      final fullName =
          resolvedType.toUpperCase() == 'ENTREPRISE' && raisonSociale.isNotEmpty
          ? raisonSociale
          : '$prenom $nom'.trim();

      clientNomComplet = fullName.isEmpty ? null : fullName;
      clientType = resolvedType.isEmpty ? null : resolvedType;
      clientEmail = _nullableString(_readString(rawClient, ['email']));
      clientTelephone = _nullableString(_readString(rawClient, ['telephone']));
      clientAdresse = _nullableString(_readString(rawClient, ['adresse']));
    }

    String? commandeReference;
    String? commandeStatut;
    String? commandeDateDisplay;
    if (rawCommande is Map<String, dynamic>) {
      commandeReference = _nullableString(
        _readString(rawCommande, [
          'referenceCommandeClient',
          'referenceCommande',
          'reference',
        ]),
      );
      commandeStatut = _nullableString(
        _readString(rawCommande, ['statutDisplay', 'statut']),
      );
      commandeDateDisplay = _nullableString(
        _readString(rawCommande, ['dateCommandeFormatted', 'dateCommande']),
      );
    }

    final dateFactureDisplay = _readString(json, [
      'dateFactureFormatted',
      'dateFacture',
      'createdAt',
      'dateCreation',
    ], fallback: '-');

    return FactureModel(
      idFactureClient: _readInt(json, ['idFactureClient', 'id']),
      referenceFactureClient: _readString(json, [
        'referenceFactureClient',
        'referenceFacture',
        'reference',
      ], fallback: '-'),
      commandeId: commandeId,
      clientId: clientId,
      statut: _readString(json, ['statut'], fallback: 'INCONNU'),
      montantTotal: _readDouble(json, ['montantTotal', 'total']),
      dateFactureDisplay: dateFactureDisplay,
      clientNomComplet: clientNomComplet,
      clientType: clientType,
      clientEmail: clientEmail,
      clientTelephone: clientTelephone,
      clientAdresse: clientAdresse,
      commandeReference: commandeReference,
      commandeStatut: commandeStatut,
      commandeDateDisplay: commandeDateDisplay,
    );
  }
}

String? _nullableString(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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

int? _readIntNullable(Map<String, dynamic> json, List<String> keys) {
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
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return fallback;
}
