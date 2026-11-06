import 'package:flutter/foundation.dart';

/// Configuración de red: URL base del backend Flask.
///
/// - Local (desktop/web): http://127.0.0.1:5000
/// - Emulador Android en debug: http://10.0.2.2:5000
/// - Producción: https://solaro-jboy.onrender.com
class ApiConfig {
  ApiConfig._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _productionBaseUrl = 'https://solaro-jboy.onrender.com';

  static final String baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : _defaultBaseUrl;

  static String get _defaultBaseUrl {
    if (kIsWeb) {
      return kReleaseMode ? _productionBaseUrl : 'http://127.0.0.1:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return kDebugMode ? 'http://10.0.2.2:5000' : _productionBaseUrl;
    }

    return 'http://127.0.0.1:5000';
  }

  // 45s: Render gratuito "duerme" el backend y el primer arranque tarda.
  static const Duration timeout = Duration(seconds: 45);
}
