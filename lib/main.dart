// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invera_mobile/views/auth/welcome_screen.dart';
import 'package:invera_mobile/views/dashboard/Comemrcial_Dashboard/Commercial_dashboard.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement_Dashboard/approvisionnement_Dashboard.dart';
import 'package:invera_mobile/views/dashboard/vente_dashboard/responsable_vente_dashboard.dart';
import 'package:invera_mobile/views/auth/forgot_password_screen.dart';
import 'package:invera_mobile/views/auth/reset-password.dart';
import 'package:invera_mobile/views/profile/profile_screen.dart';
import 'config/app_routes.dart';
import 'config/app_globals.dart';
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
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      initialRoute: AppRoutes.login,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr', 'FR'),
      ],
      routes: {
        // Routes sans paramètres
        AppRoutes.welcome: (context) => const WelcomeScreen(),
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

          case AppRoutes.responsableVenteDashboard:
            final args = settings.arguments as Map<String, dynamic>?;
            final user = args?['user'] as User?;
            if (user != null) {
              return MaterialPageRoute(
                builder: (context) => ResponsableVenteDashboard(user: user),
              );
            }
            break;

          case AppRoutes.profile:
            final args = settings.arguments as Map<String, dynamic>?;
            final user = args?['user'] as User?;
            if (user != null) {
              return MaterialPageRoute(
                builder: (context) => ProfileScreen(user: user),
              );
            }
            break;

          case AppRoutes.forgotPassword:
            final args = settings.arguments as Map<String, dynamic>?;
            final email = args?['email'] as String?;
            return MaterialPageRoute(
              builder: (context) => ForgotPasswordScreen(initialEmail: email),
            );

          case AppRoutes.resetPassword:
            final args = settings.arguments as Map<String, dynamic>?;
            final email = args?['email'] as String?;
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(email: email ?? ''),
            );
        }

        // Route par défaut si aucune correspondance
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('Page non trouvée'))),
        );
      },
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 45, 71, 200),
        useMaterial3: true,
      ),
    );
  }
}
