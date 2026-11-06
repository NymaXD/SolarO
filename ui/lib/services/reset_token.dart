import 'dart:convert';

/// Lee el JWT de recuperación SIN verificar firma (eso lo hace el backend).
/// Solo sirve para decidir UX: mostrar el formulario o "enlace inválido".
/// La validez real la impone POST /auth/reset-password al enviar.
class ResetTokenInfo {
  final DateTime? expiresAt;
  final String? jti;
  const ResetTokenInfo({this.expiresAt, this.jti});

  bool get isExpired {
    if (expiresAt == null) return true; // sin exp legible = inválido
    return DateTime.now().isAfter(expiresAt!);
  }
}

ResetTokenInfo? tryParseResetToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
    final exp = payload['exp'];
    final jti = payload['jti'];
    if (exp is! num) return ResetTokenInfo(jti: jti is String ? jti : null);
    return ResetTokenInfo(
      expiresAt: DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt()),
      jti: jti is String ? jti : null,
    );
  } catch (_) {
    return null; // token malformado
  }
}
