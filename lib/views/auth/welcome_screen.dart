// lib/views/auth/welcome_screen.dart
import 'package:flutter/material.dart';
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
              Color.fromARGB(255, 53, 82, 224),   // Bleu vif
              Color.fromARGB(255, 45, 67, 191),   // Bleu moyen
              Color.fromARGB(255, 35, 53, 169),   // Bleu moyen-foncé
              Color.fromARGB(255, 24, 37, 136),   // Bleu foncé
              Color.fromARGB(255, 13, 21, 111),   // Bleu très foncé
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double availableHeight = constraints.maxHeight;

              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        children: [
                          SizedBox(height: availableHeight * 0.05),

                          // Logo
                          Container(
                            width: 180,
                            height: 180,
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              width: 180,
                              height: 180,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 180,
                                  height: 180,
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
                                  const Color.fromARGB(255, 19, 203, 148)
                                      .withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              '✨ ERP Cloud Intelligent ✨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(height: availableHeight * 0.06),

                          // Message principal
                          const Text(
                            'Connectez-vous à votre\nespace de gestion',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Description avec icônes
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.shopping_cart,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 5),
                              Text('Ventes',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              SizedBox(width: 10),
                              Icon(Icons.inventory,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 5),
                              Text('Stocks',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.receipt,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 5),
                              Text('Facturation',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              SizedBox(width: 10),
                              Icon(Icons.auto_awesome,
                                  color: Colors.white70, size: 18),
                              SizedBox(width: 5),
                              Text('IA',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                            ],
                          ),

                          const Spacer(),

                          // Bouton et footer (sans le TextButton)
                          Column(
                            children: [
                              // Bouton
                              Container(
                                width: double.infinity,
                                height: 44,
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
                                      color: const Color.fromARGB(255, 42, 230,
                                              189)
                                          .withOpacity(0.4),
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
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen(),
                                      ),
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

                              const SizedBox(height: 20), // Espace légèrement réduit

                              Text(
                                '© ${DateTime.now().year} InVera ERP',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),

                              SizedBox(height: availableHeight * 0.02),
                            ],
                          ),
                        ],
                      ),
                    ),
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