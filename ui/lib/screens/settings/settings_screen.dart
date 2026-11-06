import 'package:flutter/material.dart';
import '../../services/settings_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/lang.dart';
import '../faq_screen.dart';
import '../privacy_screen.dart';

/// Configuración funcional: idioma, tema oscuro y notificaciones.
/// Todo persiste en el dispositivo (shared_preferences) y se aplica al instante.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final settings = SettingsStore.instance;
        return Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Icon(Icons.settings_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(tr('set_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
              SwitchListTile(
                value: settings.notifsEnabled,
                onChanged: settings.setNotifs,
                title: Text(tr('notifs')),
                subtitle: Text(tr('notifs_sub')),
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                value: settings.isDark,
                onChanged: settings.setDark,
                title: Text(tr('dark')),
                subtitle: Text(tr('dark_sub')),
                activeThumbColor: AppColors.primary,
              ),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: Text(tr('language')),
                trailing: DropdownButton<String>(
                  value: settings.lang,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: 'es', child: Text(tr('spanish'))),
                    DropdownMenuItem(value: 'en', child: Text(tr('english'))),
                  ],
                  onChanged: (v) {
                    if (v != null) settings.setLang(v);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(tr('faq_title')),
                subtitle: Text(tr('faq_help_sub')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FaqScreen())),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(tr('privacy_title')),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
              ),
              const Divider(),
              Padding(padding: const EdgeInsets.all(16), child: Text(tr('set_note'), style: const TextStyle(color: AppColors.textMedium, fontSize: 12))),
            ],
          ),
        );
      },
    );
  }
}
