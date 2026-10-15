import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en ESTE navegador los links de recuperación ya usados.
/// El JWT es stateless y el backend no marca un solo uso, así que sin esto
/// un enlace reutilizado (aún vigente) mostraría el formulario y solo fallaría
/// al enviar. Con esto, al reabrirlo sale directo "enlace no válido".
/// En otro navegador/dispositivo seguirá mostrando el form y el backend
/// responderá 422 al enviar (ya manejado en la pantalla).
class UsedTokensStore {
  UsedTokensStore._();
  static const _kUsed = 'solaro.used_reset_tokens'; // "jti:expMillis"

  static Future<Set<String>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kUsed)?.toSet() ?? {};
  }

  static Future<void> _prune() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final kept = ((prefs.getStringList(_kUsed) ?? []).where((e) {
      final exp = int.tryParse(e.split(':').last);
      return exp != null && exp > now;
    })).toList();
    await prefs.setStringList(_kUsed, kept);
  }

  static Future<bool> isUsed(String jti) async {
    await _prune();
    return (await _loadRaw()).any((e) => e.startsWith('$jti:'));
  }

  static Future<void> markUsed(String jti, DateTime? expiresAt) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _loadRaw();
    final exp = (expiresAt ?? DateTime.now().add(const Duration(minutes: 15))).millisecondsSinceEpoch;
    raw.add('$jti:$exp');
    await prefs.setStringList(_kUsed, raw.toList());
    await _prune();
  }
}
