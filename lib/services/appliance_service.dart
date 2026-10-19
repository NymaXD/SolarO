import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';
import '../theme/lang.dart';

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
      id: (e['id'] as num?)?.toInt(),
      name: (e['nombre'] as String?) ?? '',
      tipo: (e['tipo'] as String?) ?? '',
      powerW: ((e['potencia_w'] as num?) ?? 0).toDouble(),
      hoursPerDay: ((e['horas_dia'] as num?) ?? 0).toDouble(),
      daysPerWeek: ((e['dias_semana'] as num?) ?? 7).toInt(),
      quantity: ((e['cantidad'] as num?) ?? 1).toInt(),
      kwhMonth: ((e['consumo_mensual'] as num?) ?? 0).toDouble(),
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
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) return data['message'] as String;
    } catch (_) {}
    return tr('err_generic');
  }

  Never _throw(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw AuthException(tr('session_expired'), 401);
    }
    throw AuthException(_msg(res), res.statusCode);
  }

  Future<List<ApplianceItemData>> getAppliances(String token) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/appliances'), headers: _headers(token))
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => ApplianceItemData.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throw(res);
  }

  Future<Map<String, int>> getCatalog(String token) async {
    final res = await _client
        .get(Uri.parse('${ApiConfig.baseUrl}/appliances/info'), headers: _headers(token))
        .timeout(ApiConfig.timeout);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
    _throw(res);
  }

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
