import 'package:flutter/material.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/Commercial_dashboard.dart';

/// Widget qui affiche le tableau de bord du responsable des ventes.
class ResponsableVenteDashboard extends StatelessWidget {
  // Configuration, dependances et etat local de l'interface.
  final User user;

  const ResponsableVenteDashboard({super.key, required this.user});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    return CommercialDashboard(
      user: user,
      appTitle: 'Responsable vente',
      appSubtitle: 'Pilotage des ventes',
      analyticsTitle: 'Pilotage commercial',
      analyticsSubtitle:
          'Vue consolidée des clients, commandes et factures de vente.',
    );
  }
}
