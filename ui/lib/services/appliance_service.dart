import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';
import '../theme/lang.dart';

/// Convierte a double tolerando que el backend devuelva el número como texto
/// (las columnas NUMERIC/Decimal se serializan como "2280.00").
double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim()) ?? 0;
  return 0;
}

/// Igual que [_toDouble] pero devuelve null si no hay valor usable.
int? _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) {
    final t = v.trim();
    return int.tryParse(t) ?? double.tryParse(t)?.toInt();
  }
  return null;
}

/// Electrodoméstico tal como lo expone el backend.
class ApplianceItemData {
  final int? id;
  final String name;
  final String tipo;
  final double powerW;
  final double hoursPerDay;
  final int daysPerWeek;
  final int quantity;
  final double kwhMonth;

  const ApplianceItemData({
    this.id,
    required this.name,
    required this.tipo,
    this.powerW = 0,
    required this.hoursPerDay,
    this.daysPerWeek = 7,
    this.quantity = 1,
    this.kwhMonth = 0,
  });

  factory ApplianceItemData.fromJson(Map<String, dynamic> e) {
    return ApplianceItemData(
      id: _toInt(e['id']),
      name: e['nombre']?.toString() ?? '',
      tipo: e['tipo']?.toString() ?? '',
      powerW: _toDouble(e['potencia_w']),
      hoursPerDay: _toDouble(e['horas_dia']),
      daysPerWeek: _toInt(e['dias_semana']) ?? 7,
      quantity: _toInt(e['cantidad']) ?? 1,
      kwhMonth: _toDouble(e['consumo_mensual']),
    );
  }

  double get kwhDay => powerW * hoursPerDay * quantity / 1000;
}

class ApplianceService {
  final http.Client _client;
  ApplianceService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _body(ApplianceItemData item) => {
        'nombre': item.name,
        'tipo': item.tipo,
        'horas_dia': item.hoursPerDay,
        'dias_semana': item.daysPerWeek,
        'cantidad': item.quantity,
      };

  String _msg(http.Response res) {
    final data = _jsonMap(res);
    final msg = data?['message'] ?? data?['msg'];
    if (msg is String && msg.trim().isNotEmpty) return msg;
    return tr('err_generic');
  }

  Map<String, dynamic>? _jsonMap(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map) {
        return data.map((k, v) => MapEntry('$k', v));
      }
    } catch (_) {}
    return null;
  }

  /// true si el error viene de JWT (token inválido/expirado). Flask-JWT lo
  /// responde con `{msg: ...}` y 401/403/422, mientras que los errores de
  /// validación propios usan la clave `message`.
  bool _invalidToken(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) return true;
    final data = _jsonMap(res);
    return data != null &&
        data.containsKey('msg') &&
        !data.containsKey('message');
  }

  Never _throw(http.Response res) {
    if (_invalidToken(res)) {
      throw AuthException(tr('session_expired'), 401);
    }
    throw AuthException(_msg(res), res.statusCode);
  }

  /// Reintenta una vez en errores de red/tiempo (ej: Render arrancando en frío)
  /// o si el backend responde 5xx (la lista no tiene manejo de error de BD).
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

  List<dynamic> _asList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['items', 'data', 'appliances', 'electrodomesticos']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.map((k, v) => MapEntry('$k', v));
    if (decoded is List && decoded.isNotEmpty) {
      for (final entry in decoded) {
        final map = _asMap(entry);
        if (map.isNotEmpty) return map;
      }
    }
    return const {};
  }

  Future<List<ApplianceItemData>> getAppliances(String token) =>
      _withRetry(() async {
        final res = await _client
            .get(Uri.parse('${ApiConfig.baseUrl}/appliances'),
                headers: _headers(token))
            .timeout(ApiConfig.timeout);
        if (res.statusCode == 200) {
          return _asList(jsonDecode(res.body))
              .whereType<Map>()
              .map((e) => ApplianceItemData.fromJson(
                  e.map((k, v) => MapEntry('$k', v))))
              .toList();
        }
        _throw(res);
      });

  Future<Map<String, int>> getCatalog(String token) => _withRetry(() async {
        final res = await _client
            .get(Uri.parse('${ApiConfig.baseUrl}/appliances/info'),
                headers: _headers(token))
            .timeout(ApiConfig.timeout);
        if (res.statusCode == 200) {
          return _asMap(jsonDecode(res.body)).map(
              (k, v) => MapEntry(k, _toInt(v) ?? 0));
        }
        _throw(res);
      });

  Future<void> createAppliance(String token, ApplianceItemData item) async {
    final res = await _client
        .post(
          Uri.parse('${ApiConfig.baseUrl}/appliances'),
          headers: _headers(token),
          body: jsonEncode(_body(item)),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 201) return;
    _throw(res);
  }

  Future<void> updateAppliance(String token, ApplianceItemData item) async {
    final id = item.id;
    if (id == null) throw AuthException(tr('err_generic'), 400);
    final res = await _client
        .put(
          Uri.parse('${ApiConfig.baseUrl}/appliances/$id'),
          headers: _headers(token),
          body: jsonEncode(_body(item)),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 204) return;
    _throw(res);
  }

  Future<void> deleteAppliance(String token, int id) async {
    final res = await _client
        .delete(Uri.parse('${ApiConfig.baseUrl}/appliances/$id'), headers: _headers(token))
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 204) return;
    _throw(res);
  }
}
