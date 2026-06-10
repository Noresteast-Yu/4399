import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';

/// TDD 测试集: ThemeProvider
///
/// 覆盖主题设置 load/set 持久化和 themeModeEnum 映射
void main() {
  late ThemeProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    provider = ThemeProvider();
  });

  // =========================================================================
  // 默认值（加载前）
  // =========================================================================
  group('加载前默认值', () {
    test('themeMode 默认 system', () {
      expect(provider.themeMode, ThemeModeOption.system);
    });

    test('themeColor 默认 system', () {
      expect(provider.themeColor, ThemeColorOption.system);
    });

    test('fontSize 默认 medium', () {
      expect(provider.fontSize, FontSizeOption.medium);
    });
  });

  // =========================================================================
  // loadSettings
  // =========================================================================
  group('loadSettings', () {
    test('无持久化数据时保持默认值', () async {
      await provider.loadSettings();
      expect(provider.themeMode, ThemeModeOption.system);
      expect(provider.themeColor, ThemeColorOption.system);
      expect(provider.fontSize, FontSizeOption.medium);
    });

    test('加载持久化的 themeMode=dark', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
      });
      await provider.loadSettings();
      expect(provider.themeMode, ThemeModeOption.dark);
    });

    test('加载持久化的 themeColor=blue', () async {
      SharedPreferences.setMockInitialValues({
        'theme_color': 'blue',
      });
      await provider.loadSettings();
      expect(provider.themeColor, ThemeColorOption.blue);
    });

    test('加载持久化的 font_size=largest', () async {
      SharedPreferences.setMockInitialValues({
        'font_size': 'largest',
      });
      await provider.loadSettings();
      expect(provider.fontSize, FontSizeOption.largest);
    });

    test('加载所有持久化值', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'theme_color': 'orange',
        'font_size': 'larger',
      });
      await provider.loadSettings();
      expect(provider.themeMode, ThemeModeOption.dark);
      expect(provider.themeColor, ThemeColorOption.orange);
      expect(provider.fontSize, FontSizeOption.larger);
    });

    test('无效字符串回退到 orElse 默认值', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'garbage_value',
        'theme_color': 'not_a_color',
        'font_size': 'xxx',
      });
      await provider.loadSettings();
      // firstWhere with orElse → uses defaults
      expect(provider.themeMode, ThemeModeOption.system);
      expect(provider.themeColor, ThemeColorOption.system);
      expect(provider.fontSize, FontSizeOption.medium);
    });

    test('loadSettings 触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.loadSettings();
      expect(count, 1);
    });
  });

  // =========================================================================
  // setThemeMode
  // =========================================================================
  group('setThemeMode', () {
    test('设置为 light', () async {
      await provider.setThemeMode(ThemeModeOption.light);
      expect(provider.themeMode, ThemeModeOption.light);
    });

    test('设置为 dark', () async {
      await provider.setThemeMode(ThemeModeOption.dark);
      expect(provider.themeMode, ThemeModeOption.dark);
    });

    test('设置后持久化到 SharedPreferences', () async {
      await provider.setThemeMode(ThemeModeOption.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.setThemeMode(ThemeModeOption.light);
      expect(count, 1);
    });
  });

  // =========================================================================
  // setThemeColor
  // =========================================================================
  group('setThemeColor', () {
    test('设置为 green', () async {
      await provider.setThemeColor(ThemeColorOption.green);
      expect(provider.themeColor, ThemeColorOption.green);
    });

    test('持久化到 SharedPreferences', () async {
      await provider.setThemeColor(ThemeColorOption.red);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_color'), 'red');
    });

    test('覆盖之前的值', () async {
      await provider.setThemeColor(ThemeColorOption.blue);
      await provider.setThemeColor(ThemeColorOption.purple);
      expect(provider.themeColor, ThemeColorOption.purple);
    });

    test('触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.setThemeColor(ThemeColorOption.orange);
      expect(count, 1);
    });
  });

  // =========================================================================
  // setFontSize
  // =========================================================================
  group('setFontSize', () {
    test('设置为 smallest', () async {
      await provider.setFontSize(FontSizeOption.smallest);
      expect(provider.fontSize, FontSizeOption.smallest);
    });

    test('持久化到 SharedPreferences', () async {
      await provider.setFontSize(FontSizeOption.largest);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('font_size'), 'largest');
    });

    test('触发 notifyListeners', () async {
      int count = 0;
      provider.addListener(() => count++);
      await provider.setFontSize(FontSizeOption.larger);
      expect(count, 1);
    });
  });

  // =========================================================================
  // themeModeEnum getter
  // =========================================================================
  group('themeModeEnum', () {
    test('ThemeModeOption.light → ThemeMode.light', () async {
      await provider.setThemeMode(ThemeModeOption.light);
      expect(provider.themeModeEnum, ThemeMode.light);
    });

    test('ThemeModeOption.dark → ThemeMode.dark', () async {
      await provider.setThemeMode(ThemeModeOption.dark);
      expect(provider.themeModeEnum, ThemeMode.dark);
    });

    test('ThemeModeOption.system → ThemeMode.system', () async {
      await provider.setThemeMode(ThemeModeOption.system);
      expect(provider.themeModeEnum, ThemeMode.system);
    });

    test('默认值为 ThemeMode.system', () {
      expect(provider.themeModeEnum, ThemeMode.system);
    });
  });

  // =========================================================================
  // 综合
  // =========================================================================
  group('综合生命周期', () {
    test('load → modify → reload 保持持久化值', () async {
      // 初始加载
      await provider.loadSettings();
      expect(provider.themeMode, ThemeModeOption.system);

      // 修改
      await provider.setThemeMode(ThemeModeOption.dark);
      await provider.setThemeColor(ThemeColorOption.green);
      await provider.setFontSize(FontSizeOption.largest);

      // 新实例加载（模拟重启）
      final newProvider = ThemeProvider();
      await newProvider.loadSettings();

      expect(newProvider.themeMode, ThemeModeOption.dark);
      expect(newProvider.themeColor, ThemeColorOption.green);
      expect(newProvider.fontSize, FontSizeOption.largest);
    });
  });
}
