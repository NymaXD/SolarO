import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Configuración (solo UI switches locales, listo para persistir).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifs = true;
  bool _dark = false;
  String _lang = 'Español';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(children: [Icon(Icons.settings_outlined, color: AppColors.primary), SizedBox(width: 8), Text('Configuración', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
          ),
          SwitchListTile(value: _notifs, onChanged: (v) => setState(() => _notifs = v), title: const Text('Notificaciones'), subtitle: const Text('Avisos de consumo (local demo)'), activeThumbColor: AppColors.primary),
          SwitchListTile(value: _dark, onChanged: (v) => setState(() => _dark = v), title: const Text('Tema oscuro'), subtitle: const Text('Solo UI, se aplicará con ThemeMode'), activeThumbColor: AppColors.primary),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Idioma'),
            trailing: DropdownButton<String>(
              value: _lang,
              underline: const SizedBox(),
              items: const [DropdownMenuItem(value: 'Español', child: Text('Español')), DropdownMenuItem(value: 'English', child: Text('English'))],
              onChanged: (v) => setState(() => _lang = v ?? 'Español'),
            ),
          ),
          const Divider(),
          const Padding(padding: EdgeInsets.all(16), child: Text('Los cambios se guardarán en backend / local cuando se conecte.', style: TextStyle(color: AppColors.textMedium, fontSize: 12))),
        ],
      ),
    );
  }
}
