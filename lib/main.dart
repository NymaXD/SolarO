import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolarOApp());
}

/// Raíz SolarO: solo Theme + Auth (frontend puro, sin servicios).
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
      home: const AuthScreen(),
    );
  }
}
