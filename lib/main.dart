import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'layout/app_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/not_found_screen.dart';
import 'services/session_store.dart';
import 'services/settings_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/lang.dart';
import 'widgets/solar_buttons.dart';
import 'widgets/solar_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.instance.load();
  // 500 / error inesperado: pantalla amable sin trazas técnicas.
  ErrorWidget.builder = (_) => const _CrashScreen();
  runApp(const SolarOApp());
}

/// Pantalla global de error: mensaje claro + salida al inicio.
/// No muestra detalles técnicos (van solo a la consola).
class _CrashScreen extends StatelessWidget {
  const _CrashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(child: SolarLogo(fontSize: 24)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.warning.withValues(alpha: 0.15)),
                      child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(tr('crash_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.tDark)),
                    const SizedBox(height: 6),
                    Text(tr('crash_sub'), textAlign: TextAlign.center, style: TextStyle(color: context.tMed, fontSize: 13)),
                    const SizedBox(height: 16),
                    SolarPrimaryButton(
                      label: tr('go_home'),
                      icon: Icons.home_outlined,
                      onPressed: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Raíz SolarO:
/// - URL /reset-password?t=... (enlace del correo) abre esa pantalla.
/// - Otra ruta web desconocida abre el 404 de la app.
/// - Si hay JWT guardado entra al AppShell, si no al Auth.
/// - Tema e idioma reaccionan a SettingsStore.
class SolarOApp extends StatelessWidget {
  const SolarOApp({super.key});

  static bool _isUnknownWebRoute() {
    if (!kIsWeb) return false;
    final path = Uri.base.path.replaceAll('/', '');
    return path.isNotEmpty && path != 'reset-password';
  }

  @override
  Widget build(BuildContext context) {
    final resetToken = ResetPasswordScreen.tokenFromUrl();
    final Widget start;
    if (resetToken != null) {
      start = ResetPasswordScreen(token: resetToken);
    } else if (_isUnknownWebRoute()) {
      start = const NotFoundScreen();
    } else {
      start = FutureBuilder<String?>(
        future: SessionStore.readToken(),
        builder: (context, snap) {
          if (!snap.hasData && snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final token = snap.data;
          if (token != null && token.isNotEmpty) return const AppShell();
          return const AuthScreen();
        },
      );
    }
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final settings = SettingsStore.instance;
        return MaterialApp(
          title: 'SolarO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Escalado de texto acotado para que el diseño no se rompa en accesibilidad extrema.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1.0).clamp(0.85, 1.15))),
              child: child!,
            );
          },
          home: start,
        );
      },
    );
  }
}
