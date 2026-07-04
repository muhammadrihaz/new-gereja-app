import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:gereja_app_2/firebase_options.dart';
import 'package:gereja_app_2/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('show login screen on cold start', (WidgetTester tester) async {
    await tester.pumpWidget(const GerejaApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(Scaffold), findsWidgets);
  });
}
