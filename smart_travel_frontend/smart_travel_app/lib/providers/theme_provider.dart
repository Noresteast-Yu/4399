import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption {
  light,
  dark,
  system,
}

enum ThemeColorOption {
  system,
  blue,
  orange,
  green,
  red,
  purple,
}

enum FontSizeOption {
  smallest,
  smaller,
  medium,
  larger,
  largest,
}

class ThemeProvider extends ChangeNotifier {
  ThemeModeOption _themeMode = ThemeModeOption.system;
  ThemeColorOption _themeColor = ThemeColorOption.system;
  FontSizeOption _fontSize = FontSizeOption.medium;
  SharedPreferences? _prefs;

  ThemeModeOption get themeMode => _themeMode;
  ThemeColorOption get themeColor => _themeColor;
  FontSizeOption get fontSize => _fontSize;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> loadSettings() async {
    final prefs = await _prefsInstance;
    _themeMode = ThemeModeOption.values.firstWhere(
      (e) => e.name == prefs.getString('theme_mode'),
      orElse: () => ThemeModeOption.system,
    );
    _themeColor = ThemeColorOption.values.firstWhere(
      (e) => e.name == prefs.getString('theme_color'),
      orElse: () => ThemeColorOption.system,
    );
    _fontSize = FontSizeOption.values.firstWhere(
      (e) => e.name == prefs.getString('font_size'),
      orElse: () => FontSizeOption.medium,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeOption mode) async {
    _themeMode = mode;
    final prefs = await _prefsInstance;
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setThemeColor(ThemeColorOption color) async {
    _themeColor = color;
    final prefs = await _prefsInstance;
    await prefs.setString('theme_color', color.name);
    notifyListeners();
  }

  Future<void> setFontSize(FontSizeOption size) async {
    _fontSize = size;
    final prefs = await _prefsInstance;
    await prefs.setString('font_size', size.name);
    notifyListeners();
  }

  ThemeMode get themeModeEnum {
    switch (_themeMode) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}
