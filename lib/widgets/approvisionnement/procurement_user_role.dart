import 'package:flutter/foundation.dart';

/// Role temporaire pour simuler le comportement web.
/// A remplacer plus tard par le role reel de l'utilisateur connecte.
enum ProcurementUserRole {
  responsableAchat,
  admin,
}

/// Store global temporaire.
/// Utilisation:
///   ProcurementRoleStore.instance.role = ProcurementUserRole.admin;
///   final role = ProcurementRoleStore.instance.role;
class ProcurementRoleStore extends ChangeNotifier {
  ProcurementRoleStore._();

  static final ProcurementRoleStore instance = ProcurementRoleStore._();

  ProcurementUserRole _role = ProcurementUserRole.responsableAchat;

  ProcurementUserRole get role => _role;

  bool get isAdmin => _role == ProcurementUserRole.admin;
  bool get isResponsableAchat => _role == ProcurementUserRole.responsableAchat;

  void setRole(ProcurementUserRole nextRole) {
    if (_role == nextRole) return;
    _role = nextRole;
    notifyListeners();
  }

  void toggleRole() {
    setRole(
      _role == ProcurementUserRole.admin
          ? ProcurementUserRole.responsableAchat
          : ProcurementUserRole.admin,
    );
  }

  String get roleLabel {
    switch (_role) {
      case ProcurementUserRole.admin:
        return 'Admin';
      case ProcurementUserRole.responsableAchat:
        return 'Responsable achat';
    }
  }
}