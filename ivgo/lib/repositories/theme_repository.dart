import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeRepository {
  ThemeRepository({
    Future<SharedPreferences> Function()? sharedPreferencesFactory,
  }) : _sharedPreferencesFactory = sharedPreferencesFactory ?? SharedPreferences.getInstance;

  static const String _storageKey = 'themeMode';

  final Future<SharedPreferences> Function() _sharedPreferencesFactory;

  Future<ThemeMode> getThemeMode() async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();
    final String? stored = sharedPreferences.getString(_storageKey);

    switch (stored) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferences sharedPreferences = await _sharedPreferencesFactory();
    final String value;

    switch (mode) {
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.dark:
        value = 'dark';
      case ThemeMode.system:
        value = 'system';
    }

    await sharedPreferences.setString(_storageKey, value);
  }
}
