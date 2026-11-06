import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../theme/lang.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Gestión de usuarios contra `/users` (contrato Backend v1.1).
/// Todas requieren Bearer de sesión. Los cuerpos deben llevar EXACTAMENTE
/// las claves indicadas (de más o de menos = 422).
class UserService {
  final http.Client _client;
  UserService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Never _throwNetwork(Object e) {
    if (e is TimeoutException) throw AuthException(tr('err_timeout'));
    if (e is SocketException) throw AuthException(tr('err_noconn'));
    throw AuthException(tr('err_network'));
  }

  /// true si el error proviene de JWT (token inválido/expirado). Flask-JWT
  /// responde con `{msg: ...}` y 401/403/422; los errores de validación
  /// propios usan la clave `message`.
  static bool _invalidToken(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) return true;
    try {
      final json = jsonDecode(res.body);
      return json is Map && json.containsKey('msg') && !json.containsKey('message');
    } catch (_) {
      return false;
    }
  }

  Never _throwResponse(http.Response res) {
    if (_invalidToken(res)) {
      throw AuthException(tr('session_expired'), 401);
    }
    throw AuthException(_msg(res.body), res.statusCode);
  }

  /// GET /users/me → datos actuales.
  Future<AuthUser> getMe(String token) async {
    late http.Response res;
    try {
      res = await _client.get(Uri.parse('${ApiConfig.baseUrl}/users/me'), headers: _headers(token)).timeout(ApiConfig.timeout);
    } catch (e) {
      _throwNetwork(e);
    }
    if (res.statusCode == 200) {
      return AuthUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    _throwResponse(res);
  }

  /// PUT /users/me con EXACTAMENTE {nombre, email}. 204 = ok (sin cuerpo).
  Future<AuthUser> updateMe({required String token, required String nombre, required String email}) async {
    late http.Response res;
    try {
      res = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/me'),
            headers: _headers(token),
            body: jsonEncode({'nombre': nombre.trim(), 'email': email.trim().toLowerCase()}),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      _throwNetwork(e);
    }
    if (res.statusCode == 204) {
      return AuthUser(id: 0, nombre: nombre.trim(), email: email.trim().toLowerCase());
    }
    _throwResponse(res);
  }

  /// PUT /users/me/password con EXACTAMENTE {contrasena_antigua, contrasena_nueva}.
  /// 200 = ok. 422 con field=contrasena_antigua si la actual no coincide.
  Future<String> updatePassword({required String token, required String actual, required String nueva}) async {
    late http.Response res;
    try {
      res = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}/users/me/password'),
            headers: _headers(token),
            body: jsonEncode({'contrasena_antigua': actual, 'contrasena_nueva': nueva}),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      _throwNetwork(e);
    }
    if (res.statusCode == 200) {
      return _msg(res.body, fallback: 'Contraseña actualizada.');
    }
    _throwResponse(res);
  }

  static String _msg(String body, {String fallback = 'Ocurrió un error. Intenta nuevamente.'}) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = (json['message'] ?? json['msg']) as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg;
    } catch (_) {}
    return fallback;
  }
}
