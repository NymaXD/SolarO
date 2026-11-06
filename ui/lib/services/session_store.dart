import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Persistencia local de la sesión (JWT + usuario).
/// Funciona en Android/iOS/Web/Windows/macOS (en web usa localStorage).
class SessionStore {
  SessionStore._();
  static const _kToken = 'solaro.access_token';
  static const _kRefresh = 'solaro.refresh_token';
  static const _kId = 'solaro.id_usuario';
  static const _kNombre = 'solaro.nombre';
  static const _kEmail = 'solaro.email';

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, session.accessToken);
    await prefs.setString(_kRefresh, session.refreshToken);
    await prefs.setString(_kId, '${session.user.id}');
    await prefs.setString(_kNombre, session.user.nombre);
    await prefs.setString(_kEmail, session.user.email);
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kRefresh);
    return (token == null || token.isEmpty) ? null : token;
  }

  /// Devuelve un access token vigente. Si expiró (o está por expirar en 30 s),
  /// lo renueva con el refresh token y guarda el par nuevo.
  static Future<String?> validToken() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kToken);
    if (access == null || access.isEmpty) return null;

    final expMs = _expirationMs(access);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (expMs == null || expMs - now > 30000) return access;

    final refresh = prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty) return access;

    try {
      final renewed = await AuthService().refreshTokens(refresh);
      await saveTokens(renewed.accessToken, renewed.refreshToken);
      return renewed.accessToken;
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await clear();
        return null;
      }
      rethrow;
    }
  }

  static int? _expirationMs(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = (map['exp'] as num?)?.toInt();
      return exp == null ? null : exp * 1000;
    } catch (_) {
      return null;
    }
  }

  /// Actualiza solo nombre/email (p. ej. tras PUT /users/me).
  static Future<void> updateUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kId, '${user.id}');
    await prefs.setString(_kNombre, user.nombre);
    await prefs.setString(_kEmail, user.email);
  }

  static Future<AuthUser?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_kEmail);
    if (email == null || email.isEmpty) return null;
    return AuthUser.fromPrefs({
      'id_usuario': prefs.getString(_kId) ?? '',
      'nombre': prefs.getString(_kNombre) ?? '',
      'email': email,
    });
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kId);
    await prefs.remove(_kNombre);
    await prefs.remove(_kEmail);
  }
}
