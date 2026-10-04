import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'home_shell_web.dart' if (dart.library.io) 'home_shell.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    print('[AuthGate] Build démarré');
    try {
      final AuthProvider auth = context.watch<AuthProvider>();
      print('[AuthGate] AuthProvider reçu, isLoggedIn=${auth.isLoggedIn}');
      if (auth.isLoggedIn) {
        print('[AuthGate] Affichage HomeShell');
        return const HomeShell();
      }
      print('[AuthGate] Affichage LoginScreen');
      return const LoginScreen();
    } catch (e) {
      print('[AuthGate] ERREUR: $e');
      return Scaffold(body: Center(child: Text('Erreur: $e')));
    }
  }
}
