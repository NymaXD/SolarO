import 'package:flutter/material.dart';

/// Paleta SolarO extraída de los mockups (azul profundo + amarillo solar).
/// Todo el UI debe consumir estos tokens, nunca colores hardcodeados.
class AppColors {
  AppColors._();

  // Azules
  static const Color primary = Color(0xFF1B3BBB); // azul principal sidebar / fondo móvil
  static const Color primaryDark = Color(0xFF10227A); // header, texto sobre claro
  static const Color primaryDeep = Color(0xFF0B185C); // fondo degradado inferior
  static const Color primaryLight = Color(0xFF3B5BFF);
  static const Color onPrimary = Colors.white;

  // Amarillo solar (CTA)
  static const Color accent = Color(0xFFFFC400);
  static const Color accentDark = Color(0xFFE6AC00);
  static const Color onAccent = Color(0xFF0B185C);

  // Superficies
  static const Color background = Color(0xFFF2F5FF); // fondo desktop
  static const Color card = Colors.white;
  static const Color cardBlue = Color(0xFF1B3BBB); // cards en móvil oscuro
  static const Color divider = Color(0xFFE2E8F5);

  // Texto
  static const Color textDark = Color(0xFF0E1B4D);
  static const Color textMedium = Color(0xFF5A6B9C);
  static const Color textLight = Color(0xFFB9C4E8);
  static const Color textOnBlue = Colors.white;

  // Paleta modo oscuro (noche solar: fondo navy + superficies elevadas + amarillo)
  static const Color bgDark = Color(0xFF0A1230);
  static const Color surfaceDark = Color(0xFF151D45);
  static const Color surfaceDark2 = Color(0xFF1C2656);
  static const Color borderDark = Color(0xFF2C3770);
  static const Color textWhite = Color(0xFFF2F5FF);
  static const Color mutedDark = Color(0xFFA3AEDB);
  static const Color primaryBright = Color(0xFF7C96FF);

  // Estados
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Iconos electrodomésticos (pasteles del mockup)
  static const Color iconBlue = Color(0xFF3B82F6);
  static const Color iconPink = Color(0xFFEC4899);
  static const Color iconCyan = Color(0xFF06B6D4);
  static const Color iconPurple = Color(0xFF8B5CF6);
  static const Color iconYellow = Color(0xFFF59E0B);

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDeep],
  );

  static const LinearGradient yellowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFD54D), accent],
  );
}

/// Atajos según brillo actual. Úsalos en vez de colores fijos claros
/// para que todo se lea bien en modo claro Y oscuro.
extension DarkX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get tDark => isDark ? AppColors.textWhite : AppColors.textDark;
  Color get tMed => isDark ? AppColors.mutedDark : AppColors.textMedium;
  Color get cardBg => isDark ? AppColors.surfaceDark : Colors.white;
  Color get border => isDark ? AppColors.borderDark : AppColors.divider;
  Color get inputBg => isDark ? AppColors.surfaceDark2 : Colors.white;
}
