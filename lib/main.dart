// lib/main.dart
import 'package:flutter/material.dart';
import 'package:invera_mobile/views/auth/welcome_screen.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/Commercial_dashboard.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/approvisionnement_Dashboard.dart';
import 'config/app_routes.dart';
import 'views/auth/login_screen.dart';

import 'models/user_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Invera',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: {
        // Routes sans paramètres
        AppRoutes.Welcome: (context) => const WelcomeScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
      },
      onGenerateRoute: (settings) {
        // Routes avec paramètres
        switch (settings.name) {
          case AppRoutes.approvisionnementDashboard:
            final args = settings.arguments as Map<String, dynamic>?;
            final user = args?['user'] as User?;
            if (user != null) {
              return MaterialPageRoute(
                builder: (context) => ApprovisionnementDashboard(user: user),
              );
            }
            break;
            
          case AppRoutes.commercialDashboard:
            final args = settings.arguments as Map<String, dynamic>?;
            final user = args?['user'] as User?;
            if (user != null) {
              return MaterialPageRoute(
                builder: (context) => CommercialDashboard(user: user),
              );
            }
            break;
            
       /*   case AppRoutes.forgotPassword:
            return MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            );
            
          case AppRoutes.resetPassword:
            final args = settings.arguments as Map<String, dynamic>?;
            final email = args?['email'] as String?;
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email ?? ''),
            );*/
        }
        
        // Route par défaut si aucune correspondance
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('Page non trouvée'),
            ),
          ),
        );
      },
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 45, 71, 200),
        useMaterial3: true,
      ),
    );
  }
}