import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../theme/lang.dart';
import 'api_config.dart';

/// Error de autenticación con mensaje listo para mostrar en UI.
/// El mensaje viene del backend (`message`) o es de conectividad.
class AuthException implements Exception {
  final String message;
  final int statusCode; // 0 = error de red/timeout (sin respuesta HTTP)
  const AuthException(this.message, [this.statusCode = 0]);
  @override
  String toString() => 'AuthException: $message';
}

/// Usuario mínimo devuelto por POST /auth/login.
class AuthUser {
  final int id;
  final String nombre;
  final String email;
  const AuthUser({required this.id, required this.nombre, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id_usuario'] as num).toInt(),
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  Map<String, String> toJson() => {'id_usuario': '$id', 'nombre': nombre, 'email': email};

  factory AuthUser.fromPrefs(Map<String, String> prefs) => AuthUser(
        id: int.tryParse(prefs['id_usuario'] ?? '') ?? 0,
        nombre: prefs['nombre'] ?? '',
        email: prefs['email'] ?? '',
      );
}

/// Resultado del login: token JWT + usuario.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

/// Par de tokens renovados por POST /auth/refresh.
class RefreshedTokens {
  final String accessToken;
  final String refreshToken;
  const RefreshedTokens({required this.accessToken, required this.refreshToken});
}

/// Llamadas a POST /auth/login (contrato Backend v1.1).
/// El backend exige EXACTAMENTE {email, contrasena}: ni más ni menos claves.
class AuthService {
  final http.Client _client;
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthSession> login({required String email, required String contrasena}) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim().toLowerCase(), 'contrasena': contrasena}),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw AuthException(tr('err_timeout'));
    } on SocketException {
      throw AuthException(tr('err_noconn'));
    } on http.ClientException {
      throw AuthException(tr('err_network'));
    }

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      final refresh = body['refresh_token'] as String?;
      final userJson = body['user'] as Map<String, dynamic>?;
      if (token == null ||
          token.isEmpty ||
          refresh == null ||
          refresh.isEmpty ||
          userJson == null) {
        throw AuthException(tr('err_unexpected'));
      }
      return AuthSession(
        accessToken: token,
        refreshToken: refresh,
        user: AuthUser.fromJson(userJson),
      );
    }

    // 400/401/422/500: mostrar el "message" del backend tal cual.
    throw AuthException(_backendMessage(res.body));
  }

  /// Renueva el par de tokens con POST /auth/refresh (Bearer = refresh token).
  Future<RefreshedTokens> refreshTokens(String refreshToken) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
            headers: {'Authorization': 'Bearer $refreshToken'},
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw AuthException(tr('err_timeout'));
    } on SocketException {
      throw AuthException(tr('err_noconn'));
    } on http.ClientException {
      throw AuthException(tr('err_network'));
    }

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final token = body['access_token'] as String?;
      final refresh = body['refresh_token'] as String?;
      if (token == null ||
          token.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        throw AuthException(tr('err_unexpected'));
      }
      return RefreshedTokens(accessToken: token, refreshToken: refresh);
    }
    throw AuthException(_backendMessage(res.body), res.statusCode);
  }

  /// Registro real contra POST /auth/register.
  /// El backend exige EXACTAMENTE {nombre, email, contrasena} y política
  /// de clave (8+, mayúscula, minúscula, número). 201 = creado (sin token).
  Future<void> register({required String nombre, required String email, required String contrasena}) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre.trim(),
              'email': email.trim().toLowerCase(),
              'contrasena': contrasena,
            }),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw AuthException(tr('err_timeout'));
    } on SocketException {
      throw AuthException(tr('err_noconn'));
    } on http.ClientException {
      throw AuthException(tr('err_network'));
    }

    if (res.statusCode == 201) return;
    // 400/409/422/500: mostrar el "message" del backend tal cual.
    throw AuthException(_backendMessage(res.body));
  }

  /// Recuperación real contra POST /auth/forgot-password.
  /// El backend responde 200 siempre con un mensaje genérico (no revela
  /// si el correo existe). Devuelve ese mensaje para mostrarlo.
  Future<String> forgotPassword({required String email}) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw AuthException(tr('err_timeout'));
    } on SocketException {
      throw AuthException(tr('err_noconn'));
    } on http.ClientException {
      throw AuthException(tr('err_network'));
    }

    if (res.statusCode == 200) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = body['message'] as String?;
        if (msg != null && msg.trim().isNotEmpty) return msg;
      } catch (_) {}
      return tr('forgot_generic');
    }
    throw AuthException(_backendMessage(res.body));
  }

  /// Restablece la contraseña con el token del enlace del correo.
  /// POST /auth/reset-password con `Bearer` igual al token y `{contrasena}`.
  Future<String> resetPassword({required String token, required String contrasena}) async {
    late http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'contrasena': contrasena}),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw AuthException(tr('err_timeout'));
    } on SocketException {
      throw AuthException(tr('err_noconn'));
    } on http.ClientException {
      throw AuthException(tr('err_network'));
    }

    if (res.statusCode == 200) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final msg = body['message'] as String?;
        if (msg != null && msg.trim().isNotEmpty) return msg;
      } catch (_) {}
      return tr('pass_updated_generic');
    }
    throw AuthException(_backendMessage(res.body), res.statusCode);
  }

  static String _backendMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = (json['message'] ?? json['msg']) as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg;
    } catch (_) {
      // cuerpo no-JSON: mensaje genérico abajo
    }
    return tr('err_generic');
  }
}
