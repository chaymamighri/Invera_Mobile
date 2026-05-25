import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:invera_mobile/views/auth/mot_de_passe_oublie.dart';
import 'package:invera_mobile/views/auth/reinitialiser_mot_de_passe.dart';
import 'package:invera_mobile/views/dashboard/commercial/responsable_vente_dashboard.dart';
import 'package:invera_mobile/views/dashboard/commercial/tableau_de_bord.dart';
import 'package:invera_mobile/views/dashboard/approvisionnement/tableau_de_bord.dart';
import 'package:invera_mobile/views/profile/profil.dart';

import 'config/globals.dart';
import 'config/routes.dart';
import 'models/utilisateur.dart';
import 'views/auth/connexion.dart';

/// Lance l'application Flutter.
void main() {
  runApp(const MyApp());
}

/// Widget racine qui configure la navigation, les routes et le theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
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
      supportedLocales: const [Locale('en'), Locale('fr', 'FR')],
      routes: {AppRoutes.login: (context) => const LoginScreen()},
      onGenerateRoute: (settings) {
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

        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('Page non trouvee'))),
        );
      },
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 45, 71, 200),
        useMaterial3: true,
      ),
    );
  }
}
