import 'package:flutter/material.dart';
import '../services/settings_store.dart';
import '../theme/app_colors.dart';

/// Switch compacto ES/EN. `dark=true` para fondos azules.
class LangSwitcher extends StatelessWidget {
  final bool dark;
  const LangSwitcher({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        final lang = SettingsStore.instance.lang;
        final active = dark ? Colors.white : AppColors.primaryDark;
        final idle = dark ? Colors.white60 : AppColors.textMedium;
        TextStyle style(bool on) => TextStyle(
              fontSize: 12.5,
              fontWeight: on ? FontWeight.w800 : FontWeight.w500,
              color: on ? active : idle,
              decoration: on ? TextDecoration.underline : TextDecoration.none,
            );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => SettingsStore.instance.setLang('es'),
              child: Text('ES', style: style(lang == 'es')),
            ),
            Text('|', style: TextStyle(color: idle, fontSize: 12)),
            TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () => SettingsStore.instance.setLang('en'),
              child: Text('EN', style: style(lang == 'en')),
            ),
          ],
        );
      },
    );
  }
}
