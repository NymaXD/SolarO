import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:solar_o/services/auth_service.dart';
import 'package:solar_o/services/pqrs_service.dart';

void main() {
  test('submit traduce el tipo y envía el radicado', () async {
    late http.Request captured;
    final service = PqrsService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'radicado': 'PQRS-20261103-1',
            'confirmacion_enviada': true,
          }),
          201,
        );
      }),
    );

    final confirmed = await service.submit(
      'token',
      radicado: 'PQRS-20261103-1',
      type: 'suggestion',
      name: 'Ana Pérez',
      email: 'ana@example.com',
      subject: 'Más lecciones',
      message: 'Me gustaría ver más lecciones.',
      rating: 4,
    );

    expect(confirmed, isTrue);
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['tipo'], 'sugerencia');
    expect(body['numero_radicado'], 'PQRS-20261103-1');
    expect(body['calificacion'], 4);
    expect(captured.headers['Authorization'], 'Bearer token');
  });

  test('submit omite la calificación cuando es 0', () async {
    late http.Request captured;
    final service = PqrsService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'radicado': 'PQRS-1', 'confirmacion_enviada': false}),
          201,
        );
      }),
    );

    await service.submit(
      'token',
      radicado: 'PQRS-1',
      type: 'complaint',
      name: 'Ana',
      email: 'ana@example.com',
      subject: 'Asunto',
      message: 'Descripción',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body.containsKey('calificacion'), isFalse);
    expect(body['tipo'], 'queja');
  });

  test('submit propaga 409 como AuthException', () async {
    final service = PqrsService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'El número de radicado ya existe'}),
          409,
        );
      }),
    );

    expect(
      () => service.submit(
        'token',
        radicado: 'PQRS-1',
        type: 'petition',
        name: 'Ana',
        email: 'ana@example.com',
        subject: 'Asunto',
        message: 'Descripción',
      ),
      throwsA(
        isA<AuthException>().having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
  });

  test('list traduce los tipos del backend', () async {
    final service = PqrsService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'pqrs': [
              {
                'numero_radicado': 'PQRS-1',
                'tipo': 'reclamo',
                'asunto': 'Cobro',
                'fecha': '2026-11-03T21:10:00+00:00',
              },
            ],
          }),
          200,
        );
      }),
    );

    final entries = await service.list('token');
    expect(entries, hasLength(1));
    expect(entries.first.radicado, 'PQRS-1');
    expect(entries.first.type, 'claim');
    expect(entries.first.subject, 'Cobro');
  });
}
