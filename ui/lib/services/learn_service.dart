import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../theme/lang.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Progreso de un nivel tal como lo devuelve `GET /learn/progress`.
class LearnProgress {
  final int level;
  final Set<int> completed;
  final int total;
  final double percentage;

  const LearnProgress({
    required this.level,
    required this.completed,
    required this.total,
    required this.percentage,
  });

  factory LearnProgress.fromJson(Map<String, dynamic> json) {
    final raw = json['completadas'];
    final completed = <int>{};
    if (raw is List) {
      for (final value in raw) {
        if (value is num) {
          completed.add(value.toInt());
        } else if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) completed.add(parsed);
        }
      }
    }
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final percentage = (json['porcentaje'] as num?)?.toDouble() ??
        (total == 0 ? 0 : completed.length / total * 100);
    return LearnProgress(
      level: (json['nivel'] as num?)?.toInt() ?? 0,
      completed: completed,
      total: total,
      percentage: percentage,
    );
  }
}

/// Cliente de los endpoints de progreso educativo.
///
/// Contrato (Backend `docs/learn.md`):
/// - `GET /learn/progress` → `{niveles: [{nivel, completadas, total, porcentaje}]}`
/// - `POST /learn/progress` `{nivel, leccion}`
/// - `DELETE /learn/progress/{nivel}/{leccion}`
class LearnService {
  final http.Client _client;
  LearnService({http.Client? client}) : _client = client ?? http.Client();

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

  /// true si el error viene de JWT (token inválido/expirado). Flask-JWT
  /// responde con `{msg: ...}`, mientras que las validaciones propias usan
  /// `message` o `error`.
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

  /// Reintenta una vez los fallos de red, tiempo de espera y 5xx (Render en
  /// frío). Las escrituras no se reintentan para no duplicar operaciones.
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

  Future<Map<int, LearnProgress>> getProgress(String token) =>
      _withRetry(() async {
        final res = await _client
            .get(Uri.parse('${ApiConfig.baseUrl}/learn/progress'),
                headers: _headers(token))
            .timeout(ApiConfig.timeout);
        if (res.statusCode != 200) _throw(res);

        final decoded = jsonDecode(res.body);
        final raw = decoded is Map ? decoded['niveles'] : null;
        final result = <int, LearnProgress>{};
        if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final map = item.map((k, v) => MapEntry('$k', v));
              final progress = LearnProgress.fromJson(map);
              if (progress.level > 0) result[progress.level] = progress;
            }
          }
        }
        return result;
      });

  Future<void> markLesson(String token, int level, int lesson) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/learn/progress'),
          headers: _headers(token),
          body: jsonEncode({'nivel': level, 'leccion': lesson}),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 200 || res.statusCode == 201) return;
    _throw(res);
  }

  Future<void> unmarkLesson(String token, int level, int lesson) async {
    final res = await _client
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/learn/progress/$level/$lesson'),
          headers: _headers(token),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 200) return;
    _throw(res);
  }
}
