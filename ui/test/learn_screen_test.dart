import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_o/screens/learn/learn_screen.dart';
import 'package:solar_o/services/learn_service.dart';
import 'package:solar_o/services/settings_store.dart';
import 'package:solar_o/theme/lang.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLang.current = 'es';
  });

  LearnService fakeService() => LearnService(
        client: MockClient((request) async {
          return http.Response(jsonEncode({'niveles': []}), 200);
        }),
      );

  testWidgets('LearnScreen muestra los 3 niveles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LearnScreen(service: fakeService()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nivel 1 - Básico'), findsOneWidget);
    expect(find.text('Nivel 2 - Intermedio'), findsOneWidget);
    expect(find.text('Nivel 3 - Avanzado'), findsOneWidget);
  });

  testWidgets('LearnScreen traduce los niveles al inglés', (tester) async {
    AppLang.current = 'en';
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LearnScreen(service: fakeService()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Level 1 - Beginner'), findsOneWidget);
    expect(find.text('Level 2 - Intermediate'), findsOneWidget);
    expect(find.text('Level 3 - Advanced'), findsOneWidget);
    expect(find.text('Nivel 1 - Básico'), findsNothing);
  });

  testWidgets('LearnScreen cambia los textos al cambiar el idioma',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LearnScreen(service: fakeService()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nivel 1 - Básico'), findsOneWidget);

    await SettingsStore.instance.setLang('en');
    await tester.pumpAndSettle();

    expect(find.text('Level 1 - Beginner'), findsOneWidget);
    expect(find.text('Nivel 1 - Básico'), findsNothing);
  });
}
