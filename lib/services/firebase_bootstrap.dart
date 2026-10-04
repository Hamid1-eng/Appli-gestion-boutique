import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Object? _lastError;
  static String _statusMessage = 'Initialisation...';
  static Future<bool>? _initFuture;

  static Object? get lastError => _lastError;
  static String get statusMessage => _statusMessage;

  static Future<bool> initialize() async {
    // Cache le Future pour éviter initialisation multiple
    if (_initFuture != null) {
      debugPrint('[Firebase] Utilisation du Future en cache');
      return _initFuture!;
    }

    _initFuture = _initializeInternal();
    return _initFuture!;
  }

  static Future<bool> _initializeInternal() async {
    try {
      _statusMessage = 'Connexion Firebase...';
      debugPrint('[Firebase] Démarrage initialisation');

      // Timeout wrapping
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[Firebase] TIMEOUT sur initialisation (>15s)');
          throw Exception('Firebase initialisation timeout (>15s)');
        },
      );

      debugPrint('[Firebase] Initialisation réussie!');
      _statusMessage = 'Prêt';
      _lastError = null;
      return true;
    } catch (error) {
      debugPrint('[Firebase] Erreur lors initialisation: $error');
      _statusMessage = 'Erreur Firebase';
      _lastError = error;
      return false;
    }
  }
}
