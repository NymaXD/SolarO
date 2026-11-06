import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_o/screens/learn/learn_level.dart';
import 'package:solar_o/screens/learn/learn_level_screen.dart';
import 'package:solar_o/services/learn_service.dart';
import 'package:solar_o/theme/lang.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'solaro.access_token': 'fake'});
    AppLang.current = 'es';
  });

  testWidgets('LearnLevelScreen marca y desmarca contra /learn/progress',
      (tester) async {
    final calls = <String>[];
    final service = LearnService(
      client: MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        return http.Response('{}', request.method == 'POST' ? 201 : 200);
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LearnLevelScreen(
          level: LearnData.levels().first,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿Qué es la energía solar?'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Marcar como completado'));
    await tester.pumpAndSettle();
    expect(find.text('Completado'), findsOneWidget);
    expect(calls, contains('POST /learn/progress'));

    await tester.tap(find.text('Pendiente'));
    await tester.pumpAndSettle();
    expect(find.text('Marcar como completado'), findsOneWidget);
    expect(find.text('Completado'), findsNothing);
    expect(calls, contains('DELETE /learn/progress/1/1'));
  });

  testWidgets('las lecciones de video ofrecen abrir YouTube', (tester) async {
    final service = LearnService(
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LearnLevelScreen(
          level: LearnData.levels().first,
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Video: ¿Qué es la energía solar?'));
    await tester.pumpAndSettle();

    expect(find.text('Ver video en YouTube'), findsOneWidget);
    expect(find.textContaining('ábrelo en YouTube'), findsOneWidget);
  });
}
