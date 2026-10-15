import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de diseño SolarO. Un único ThemeData claro + estados hover/focus/error.
class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Roboto'; // sistema; sustituible por Poppins sin romper layout

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.card,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,

      // ---- Texto ----
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.1),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.textDark),
        bodyMedium: TextStyle(fontSize: 13.5, color: AppColors.textMedium),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.textMedium),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),

      // ---- AppBar ----
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textDark),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
      ),

      // ---- Inputs ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF93A0C4), fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.textMedium, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 2)),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return AppColors.error;
          if (states.contains(WidgetState.focused)) return AppColors.primary;
          return AppColors.textMedium;
        }),
      ),

      // ---- Botones ----
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 50)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return const Color(0xFFE2E8F5);
            if (s.contains(WidgetState.hovered)) return AppColors.accentDark;
            if (s.contains(WidgetState.pressed)) return AppColors.accentDark;
            return AppColors.accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return AppColors.textMedium;
            return AppColors.onAccent;
          }),
          elevation: WidgetStateProperty.all(0),
          overlayColor: WidgetStateProperty.all(const Color(0x22000000)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return AppColors.primaryDark;
            return AppColors.primary;
          }),
          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700)),
          overlayColor: WidgetStateProperty.all(const Color(0x141B3BBB)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return const BorderSide(color: AppColors.primary, width: 1.5);
            return const BorderSide(color: AppColors.divider);
          }),
          foregroundColor: WidgetStateProperty.all(AppColors.textDark),
        ),
      ),

      // ---- Cards ----
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
      ),

      // ---- Navegación ----
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.primary,
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
      ),

      // ---- Transiciones ----
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Tema oscuro completo: superficies navy, texto claro, acento amarillo.
  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: AppColors.primaryBright,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgDark,
      canvasColor: AppColors.surfaceDark,
      splashFactory: InkSparkle.splashFactory,

      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textWhite, height: 1.1),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textWhite),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textWhite),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textWhite),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textWhite),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.textWhite),
        bodyMedium: TextStyle(fontSize: 13.5, color: AppColors.mutedDark),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.mutedDark),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark2,
        hintStyle: const TextStyle(color: AppColors.mutedDark, fontSize: 13.5),
        labelStyle: const TextStyle(color: AppColors.mutedDark, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error, width: 2)),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) return AppColors.error;
          if (states.contains(WidgetState.focused)) return AppColors.accent;
          return AppColors.mutedDark;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) => AppColors.mutedDark),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 50)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          backgroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return AppColors.borderDark;
            if (s.contains(WidgetState.hovered)) return AppColors.accentDark;
            if (s.contains(WidgetState.pressed)) return AppColors.accentDark;
            return AppColors.accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.disabled)) return AppColors.mutedDark;
            return AppColors.onAccent;
          }),
          elevation: WidgetStateProperty.all(0),
          overlayColor: WidgetStateProperty.all(const Color(0x22000000)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return AppColors.accent;
            return AppColors.primaryBright;
          }),
          textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w700)),
          overlayColor: WidgetStateProperty.all(const Color(0x14FFC400)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          side: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) return const BorderSide(color: AppColors.accent, width: 1.5);
            return const BorderSide(color: AppColors.borderDark);
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textWhite),
        contentTextStyle: TextStyle(fontSize: 13.5, color: AppColors.mutedDark),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: AppColors.bgDark),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceDark2,
        textStyle: TextStyle(color: AppColors.textWhite, fontSize: 13.5),
      ),
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textWhite,
        iconColor: AppColors.mutedDark,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderDark),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.accent.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);
          }
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white60);
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.primary,
        selectedIconTheme: IconThemeData(color: AppColors.accent),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.accent;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return AppColors.accent.withValues(alpha: 0.4);
          return null;
        }),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
