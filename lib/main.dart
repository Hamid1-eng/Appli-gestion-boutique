import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        print('[ERROR] Flutter Error: ${details.exception}');
        print('[ERROR] Stack: ${details.stack}');
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        print('[ERROR] Unhandled async error: $error');
        print('[ERROR] Stack: $stack');
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: const Color(0xFFF8FAFC),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Une erreur a été détectée au chargement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          details.exceptionAsString(),
                          style: const TextStyle(color: Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      };

      final bool firebaseReady = await FirebaseBootstrap.initialize();
      print(
        '[Main] Firebase Ready: $firebaseReady, Error: ${FirebaseBootstrap.lastError}',
      );

      runApp(
        BoutiqueApp(
          firebaseReady: firebaseReady,
          firebaseError: FirebaseBootstrap.lastError,
        ),
      );
    },
    (Object error, StackTrace stack) {
      print('[ERROR] Zoned error: $error');
      print('[ERROR] Zoned stack: $stack');
    },
  );
}
