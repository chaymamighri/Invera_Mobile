// lib/views/dashboard/approvisionnement_dashboard.dart
import 'package:flutter/material.dart';
import 'package:invera_mobile/models/user_model.dart';
import '../../../models/user_model.dart';

class ApprovisionnementDashboard extends StatelessWidget {
  final User user;

  const ApprovisionnementDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Approvisionnement'),
      ),
      body: const Center(
        child: Text(
          'Dashboard Approvisionnement - En cours de développement (Sprint à venir)',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}