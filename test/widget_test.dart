// Smoke test frontend SolarO (sin backend).
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_o/main.dart';

void main() {
  testWidgets('SolarO arranca en Auth', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(const SolarOApp());
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
