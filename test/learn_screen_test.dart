import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_o/screens/learn/learn_screen.dart';

void main() {
  testWidgets('LearnScreen muestra los 3 niveles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: LearnScreen())));
    // Deja pasar el delay de carga (900 ms) + frames
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    expect(find.text('Nivel 1 - Básico'), findsOneWidget);
    expect(find.text('Nivel 2 - Intermedio'), findsOneWidget);
    expect(find.text('Nivel 3 - Avanzado'), findsOneWidget);
  });
}
