import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/lang.dart';

/// Ajustes persistentes (idioma, tema, notificaciones).
/// Se cargan antes del runApp y todo cambio notifica para reconstruir la app.
class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  static const _kLang = 'solaro.lang';
  static const _kDark = 'solaro.dark';
  static const _kNotifs = 'solaro.notifs';

  String _lang = 'es';
  bool _dark = false;
  bool _notifs = true;

  String get lang => _lang;
  bool get isDark => _dark;
  bool get notifsEnabled => _notifs;
  ThemeMode get themeMode => _dark ? ThemeMode.dark : ThemeMode.light;
  Locale get locale => Locale(_lang);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = (prefs.getString(_kLang) == 'en') ? 'en' : 'es';
    _dark = prefs.getBool(_kDark) ?? false;
    _notifs = prefs.getBool(_kNotifs) ?? true;
    AppLang.current = _lang;
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    if (lang != 'es' && lang != 'en') return;
    _lang = lang;
    AppLang.current = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, lang);
  }

  Future<void> setDark(bool value) async {
    _dark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, value);
  }

  Future<void> setNotifs(bool value) async {
    _notifs = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifs, value);
  }
}
