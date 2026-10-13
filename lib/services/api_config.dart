/// Configuración de red: URL base del backend Flask.
///
/// - Local (desktop/web): http://127.0.0.1:5000
/// - Emulador Android: http://10.0.2.2:5000 (ver docs/api-contract.md del backend)
/// - Producción (Vercel): pasar con --dart-define, ej:
///   flutter build web --release --dart-define=API_BASE_URL=https://tu-backend.vercel.app
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  // 45s: Render gratuito "duerme" el backend y el primer arranque tarda.
  static const Duration timeout = Duration(seconds: 45);
}
