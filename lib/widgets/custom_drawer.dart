// lib/widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/app_routes.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  final User user;

  const CustomDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête du drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 16, 32, 112),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 50,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.business, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  '${user.prenom} ${user.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Menu items selon le rôle
          if (user.role == UserRole.COMMERCIAL) ...[
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.people,
              label: 'Clients',
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers clients
              },
              
            ),
             _buildDrawerItem(
              icon: Icons.shopping_cart,
              label: 'Commandes',
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers factures
              },
            ),
            _buildDrawerItem(
              icon: Icons.receipt,
              label: 'Factures',
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers factures
              },
            ),
          ],
          
          if (user.role == UserRole.RESPONSABLE_ACHAT) ...[
            _buildDrawerItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              onTap: () => Navigator.pop(context),
            ),
            _buildDrawerItem(
              icon: Icons.inventory,
              label: 'Gestion des stocks',
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers stocks
              },
            ),
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              label: 'Commandes fournisseurs',
              onTap: () {
                Navigator.pop(context);
                // TODO: Naviguer vers commandes
              },
            ),
          ],
          
          const Divider(),
        
          
          // Déconnexion
          _buildDrawerItem(
            icon: Icons.logout,
            label: 'Déconnexion',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // Widget helper pour les items du drawer
  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color.fromARGB(255, 45, 71, 200),
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }

  // Dialogue de déconnexion (déplacé depuis CommercialDashboard)
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authService = AuthService();
                await authService.logout();
                if (context.mounted) {
                  Navigator.pop(context); // Ferme le dialog
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Déconnecter'),
            ),
          ],
        );
      },
    );
  }
}