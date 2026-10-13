import 'package:flutter/material.dart';
import 'layout/app_shell.dart';
import 'services/session_store.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolarOApp());
}

/// Raíz SolarO: si hay JWT guardado entra directo al AppShell, si no al Auth.
class SolarOApp extends StatelessWidget {
  const SolarOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SolarO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Escalado de texto acotado para que el diseño no se rompa en accesibilidad extrema.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1.0).clamp(0.85, 1.15))),
          child: child!,
        );
      },
      home: FutureBuilder<String?>(
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
  }
}
