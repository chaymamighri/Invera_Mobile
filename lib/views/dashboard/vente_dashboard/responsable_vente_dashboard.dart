import 'package:flutter/material.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/Commercial_dashboard.dart';

class ResponsableVenteDashboard extends StatelessWidget {
  final User user;

  const ResponsableVenteDashboard({super.key, required this.user});

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
