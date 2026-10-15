import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

/// Persistencia local de la sesión (JWT + usuario).
/// Funciona en Android/iOS/Web/Windows/macOS (en web usa localStorage).
/// TODO-BACKEND: si agregan refresh tokens o POST /auth/logout, gestionarlos aquí.
class SessionStore {
  SessionStore._();
  static const _kToken = 'solaro.access_token';
  static const _kId = 'solaro.id_usuario';
  static const _kNombre = 'solaro.nombre';
  static const _kEmail = 'solaro.email';

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, session.accessToken);
    await prefs.setString(_kId, '${session.user.id}');
    await prefs.setString(_kNombre, session.user.nombre);
    await prefs.setString(_kEmail, session.user.email);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    return (token == null || token.isEmpty) ? null : token;
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
    await prefs.remove(_kId);
    await prefs.remove(_kNombre);
    await prefs.remove(_kEmail);
  }
}
