import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  static final AppState instance = AppState._();
  AppState._();

  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('tr');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = (prefs.getBool('isDarkTheme') ?? false) ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(prefs.getString('locale') ?? 'tr');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = _themeMode == ThemeMode.dark;
    await prefs.setBool('isDarkTheme', !isDark);
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final isEn = _locale.languageCode == 'en';
    await prefs.setString('locale', isEn ? 'tr' : 'en');
    _locale = Locale(isEn ? 'tr' : 'en');
    notifyListeners();
  }
}
