import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'layout/app_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'services/session_store.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.instance.load();
  runApp(const SolarOApp());
}

/// Raíz SolarO:
/// - Si la URL es /reset-password?t=... (enlace del correo) abre esa pantalla.
/// - Si hay JWT guardado entra al AppShell, si no al Auth.
/// - Tema e idioma reaccionan a SettingsStore.
class SolarOApp extends StatelessWidget {
  const SolarOApp({super.key});

  @override
  Widget build(BuildContext context) {
    final resetToken = ResetPasswordScreen.tokenFromUrl();
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
          home: resetToken != null
              ? ResetPasswordScreen(token: resetToken)
              : FutureBuilder<String?>(
                  future: SessionStore.readToken(),
                  builder: (context, snap) {
                    if (!snap.hasData && snap.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    final token = snap.data;
                    if (token != null && token.isNotEmpty) return const AppShell();
                    return const AuthScreen();
                  },
                ),
        );
      },
    );
  }
}
