import 'package:flutter/material.dart';
import 'package:invera_mobile/models/utilisateur.dart';
import 'package:invera_mobile/views/dashboard/commercial/tableau_de_bord.dart';
import 'package:invera_mobile/widgets/commercial/sidebar.dart';

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
          'Vue consolidee des clients, commandes et factures de vente.',
      initialPage: 'commandes',
      sidebarSections: const [
        CommercialSidebarSection(
          title: 'TABLEAU DE BORD',
          items: [
            CommercialSidebarItem(
              id: 'dashboard',
              label: 'Statistiques',
              icon: Icons.bar_chart_outlined,
            ),
          ],
        ),
        CommercialSidebarSection(
          title: 'CATALOGUE',
          items: [
            CommercialSidebarItem(
              id: 'produits',
              label: 'Produits',
              icon: Icons.inventory_2_outlined,
            ),
            CommercialSidebarItem(
              id: 'clients',
              label: 'Clients',
              icon: Icons.people_alt_outlined,
            ),
          ],
        ),
        CommercialSidebarSection(
          title: 'VENTES',
          items: [
            CommercialSidebarItem(
              id: 'commandes',
              label: 'Commandes',
              icon: Icons.shopping_cart_outlined,
            ),
            CommercialSidebarItem(
              id: 'ventes',
              label: 'Ventes',
              icon: Icons.paid_outlined,
            ),
            CommercialSidebarItem(
              id: 'factures_generees',
              label: 'Facturation',
              icon: Icons.receipt_long_outlined,
            ),
          ],
        ),
      ],
    );
  }
}
