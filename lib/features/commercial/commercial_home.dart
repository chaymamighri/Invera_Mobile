import 'package:flutter/material.dart';

class CommercialHome extends StatelessWidget {
  final String fullName;
  const CommercialHome({super.key, required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Commercial")),
      body: Center(
        child: Text(
          "Bienvenue $fullName\nDashboard Commercial",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}