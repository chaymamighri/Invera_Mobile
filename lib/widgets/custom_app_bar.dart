// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/app_routes.dart';
import '../services/auth_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final User user;
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.user,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          // Logo
          Image.asset(
            'assets/images/logo.png',
            height: 30,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
      backgroundColor: Color.fromARGB(255, 16, 32, 112),
      foregroundColor: Colors.white,
      actions: actions ?? [
        // Menu utilisateur par défaut
        PopupMenuButton<String>(
          icon: const Icon(Icons.account_circle),
          onSelected: (value) async {
            if (value == 'logout') {
              final authService = AuthService();
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            } else if (value == 'profile') {
              // TODO: Naviguer vers profil
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text('${user.prenom} ${user.nom}'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}