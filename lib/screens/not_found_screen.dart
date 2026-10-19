import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/lang.dart';
import '../widgets/solar_buttons.dart';
import '../widgets/solar_logo.dart';
import 'auth/auth_screen.dart';
import '../layout/app_shell.dart';
import '../services/session_store.dart';

/// 404 dentro de la app para rutas web desconocidas.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  Future<void> _goHome(BuildContext context) async {
    final token = await SessionStore.validToken();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => (token != null && token.isNotEmpty) ? const AppShell() : const AuthScreen()),
      (route) => false,
    );
  }

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
                    Center(
                      child: Text('404', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: context.tDark)),
                    ),
                    const SizedBox(height: 4),
                    Text(tr('notfound_title'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.tDark)),
                    const SizedBox(height: 6),
                    Text(tr('notfound_sub'), textAlign: TextAlign.center, style: TextStyle(color: context.tMed, fontSize: 13)),
                    const SizedBox(height: 16),
                    SolarPrimaryButton(label: tr('go_home'), icon: Icons.home_outlined, onPressed: () => _goHome(context)),
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
