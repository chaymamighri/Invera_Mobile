// lib/views/dashboard/commercial_dashboard.dart
import 'package:flutter/material.dart';
import 'package:invera_mobile/models/user_model.dart';
import 'package:invera_mobile/widgets/custom_app_bar.dart';
import 'package:invera_mobile/widgets/custom_drawer.dart';

class CommercialDashboard extends StatelessWidget {
  final User user;

  const CommercialDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        user: user,
        title: 'Commercial',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
        ],
      ),
      
      drawer: CustomDrawer(user: user),
      
      body: const Center(
        child: Text(
          'Dashboard Commercial - En cours de développement',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}