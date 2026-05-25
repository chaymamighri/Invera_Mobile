class FactureModel {
  final int idFactureClient;
  final String referenceFactureClient;
  final int? commandeId;
  final int? clientId;
  final String statut;
  final double montantTotal;
  final String dateFactureDisplay;

  FactureModel({
    required this.idFactureClient,
    required this.referenceFactureClient,
    required this.commandeId,
    required this.clientId,
    required this.statut,
    required this.montantTotal,
    required this.dateFactureDisplay,
  });

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
    );
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
