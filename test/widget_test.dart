// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appligestion/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BoutiqueApp(firebaseReady: false));

    // Verify that the app builds successfully.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
