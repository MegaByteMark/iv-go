import 'package:flutter/material.dart';
import 'package:ivgo/repositories/theme_repository.dart';

class FakeThemeRepository extends ThemeRepository {
  FakeThemeRepository({
    ThemeMode initialThemeMode = ThemeMode.system,
  }) : _themeMode = initialThemeMode;

  ThemeMode _themeMode;

  @override
  Future<ThemeMode> getThemeMode() async {
    return _themeMode;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
  }
}
