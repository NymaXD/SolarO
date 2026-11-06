import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../theme/lang.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// PQRS tal como la devuelve `GET /pqrs` (sin datos del solicitante).
class PqrsRemoteEntry {
  final String radicado;
  final String type; // petition | complaint | claim | suggestion
  final String subject;
  final DateTime createdAt;

  const PqrsRemoteEntry({
    required this.radicado,
    required this.type,
    required this.subject,
    required this.createdAt,
  });
}

/// Cliente de PQRS.
///
/// El frontend conserva sus tipos en inglés y el backend usa los nombres en
/// español; la conversión se hace aquí para no cambiar la UI existente.
class PqrsService {
  final http.Client _client;
  PqrsService({http.Client? client}) : _client = client ?? http.Client();

  static const Map<String, String> _toApi = {
    'petition': 'peticion',
    'complaint': 'queja',
    'claim': 'reclamo',
    'suggestion': 'sugerencia',
  };

  static const Map<String, String> _fromApi = {
    'peticion': 'petition',
    'queja': 'complaint',
    'reclamo': 'claim',
    'sugerencia': 'suggestion',
  };

  static String apiType(String local) => _toApi[local] ?? 'peticion';
  static String localType(String api) => _fromApi[api] ?? 'petition';

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic>? _jsonMap(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map) return data.map((k, v) => MapEntry('$k', v));
    } catch (_) {}
    return null;
  }

  String _msg(http.Response res) {
    final data = _jsonMap(res);
    final msg = data?['message'] ?? data?['error'] ?? data?['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return tr('err_generic');
  }

  bool _invalidToken(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) return true;
    final data = _jsonMap(res);
    return data != null &&
        data.containsKey('msg') &&
        !data.containsKey('message') &&
        !data.containsKey('error');
  }

  Never _throw(http.Response res) {
    if (_invalidToken(res)) {
      throw AuthException(tr('session_expired'), 401);
    }
    throw AuthException(_msg(res), res.statusCode);
  }

  /// Reintenta una vez los fallos de red/tiempo y 5xx al consultar la lista.
  /// El envío no se reintenta: un 502 puede haber llegado al correo y el
  /// usuario debe decidir si vuelve a intentarlo.
  Future<T> _withRetry<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 2));
      return await run();
    } on http.ClientException {
      await Future.delayed(const Duration(seconds: 2));
      return await run();
    } on AuthException catch (e) {
      if (e.statusCode >= 500) {
        await Future.delayed(const Duration(seconds: 2));
        return await run();
      }
      rethrow;
    }
  }

  /// `POST /pqrs`. Devuelve `confirmacion_enviada` si el backend lo informa.
  Future<bool> submit(
    String token, {
    required String radicado,
    required String type,
    required String name,
    required String email,
    required String subject,
    required String message,
    int rating = 0,
  }) async {
    final body = <String, dynamic>{
      'tipo': apiType(type),
      'numero_radicado': radicado,
      'nombre': name,
      'email': email,
      'asunto': subject,
      'descripcion': message,
      if (rating > 0) 'calificacion': rating,
    };

    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/pqrs'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(ApiConfig.timeout);

    if (res.statusCode == 201) {
      final data = _jsonMap(res);
      return data?['confirmacion_enviada'] as bool? ?? true;
    }
    _throw(res);
  }

  /// `GET /pqrs`, de la más reciente a la más antigua.
  Future<List<PqrsRemoteEntry>> list(String token) => _withRetry(() async {
        final res = await _client
            .get(Uri.parse('${ApiConfig.baseUrl}/pqrs'),
                headers: _headers(token))
            .timeout(ApiConfig.timeout);
        if (res.statusCode != 200) _throw(res);

        final decoded = jsonDecode(res.body);
        final raw = decoded is Map ? decoded['pqrs'] : null;
        if (raw is! List) return const [];

        final entries = <PqrsRemoteEntry>[];
        for (final item in raw) {
          if (item is! Map) continue;
          final map = item.map((k, v) => MapEntry('$k', v));
          final radicado = map['numero_radicado']?.toString() ?? '';
          if (radicado.isEmpty) continue;
          entries.add(
            PqrsRemoteEntry(
              radicado: radicado,
              type: localType(map['tipo']?.toString() ?? ''),
              subject: map['asunto']?.toString() ?? '',
              createdAt:
                  DateTime.tryParse(map['fecha']?.toString() ?? '')?.toLocal() ??
                      DateTime.now(),
            ),
          );
        }
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return entries;
      });
}
