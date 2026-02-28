import 'package:flutter/material.dart';

class AchatHome extends StatelessWidget {
  final String fullName;
  const AchatHome({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Responsable Achat")),
      body: Center(
        child: Text(
          "Bienvenue $fullName\nDashboard Responsable Achat",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}