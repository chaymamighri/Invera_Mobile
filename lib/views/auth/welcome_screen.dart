import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/adaptive_layout.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 53, 82, 224),
              Color.fromARGB(255, 45, 67, 191),
              Color.fromARGB(255, 35, 53, 169),
              Color.fromARGB(255, 24, 37, 136),
              Color.fromARGB(255, 13, 21, 111),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final compact = constraints.maxWidth < 380;
              final horizontalPadding = AdaptiveLayout.horizontalPadding(
                context,
                phone: 18,
                tablet: 24,
                desktop: 30,
              );

              final rawLogoSize = math.min(180.0, constraints.maxWidth * 0.42);
              final logoSize = rawLogoSize < 130 ? 130.0 : rawLogoSize;
              final titleSize = compact ? 22.0 : 26.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: Column(
                    children: [
                      SizedBox(height: availableHeight * 0.05),
                      SizedBox(
                        width: logoSize,
                        height: logoSize,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromARGB(255, 45, 76, 231),
                                    Color.fromARGB(255, 7, 9, 62),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'InVera',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              const Color.fromARGB(255, 19, 203, 148).withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'ERP Cloud Intelligent',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 24 : availableHeight * 0.06),
                      Text(
                        'Connectez-vous à votre\nespace de gestion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: const [
                          _FeatureChip(icon: Icons.shopping_cart, label: 'Ventes'),
                          _FeatureChip(icon: Icons.inventory, label: 'Stocks'),
                          _FeatureChip(icon: Icons.receipt, label: 'Facturation'),
                          _FeatureChip(icon: Icons.auto_awesome, label: 'IA'),
                        ],
                      ),
                      SizedBox(height: compact ? 28 : 40),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 10, 79, 41),
                                Color.fromARGB(255, 12, 174, 74),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 42, 230, 189).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '© ${DateTime.now().year} InVera ERP',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      SizedBox(height: math.max(16.0, availableHeight * 0.02)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
