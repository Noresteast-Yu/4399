import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

/// TDD 测试集: AppTheme 纯函数
///
/// 覆盖主题计算的核心无副作用函数
void main() {
  // =========================================================================
  // getFontSizeMultiplier
  // =========================================================================
  group('getFontSizeMultiplier', () {
    test('smallest 返回 0.8', () {
      expect(
          AppTheme.getFontSizeMultiplier(FontSizeOption.smallest), 0.8);
    });

    test('smaller 返回 0.9', () {
      expect(AppTheme.getFontSizeMultiplier(FontSizeOption.smaller), 0.9);
    });

    test('medium 返回 1.0', () {
      expect(AppTheme.getFontSizeMultiplier(FontSizeOption.medium), 1.0);
    });

    test('larger 返回 1.15', () {
      expect(AppTheme.getFontSizeMultiplier(FontSizeOption.larger), 1.15);
    });

    test('largest 返回 1.3', () {
      expect(AppTheme.getFontSizeMultiplier(FontSizeOption.largest), 1.3);
    });

    test('所有 multiplier 为正且单调递增', () {
      final multipliers = FontSizeOption.values
          .map((o) => AppTheme.getFontSizeMultiplier(o))
          .toList();
      for (final m in multipliers) {
        expect(m, greaterThan(0));
      }
      for (int i = 1; i < multipliers.length; i++) {
        expect(multipliers[i], greaterThan(multipliers[i - 1]));
      }
    });
  });

  // =========================================================================
  // scaleTextTheme
  // =========================================================================
  group('scaleTextTheme', () {
    late TextTheme baseTheme;

    setUp(() {
      baseTheme = const TextTheme(
        displayLarge: TextStyle(fontSize: 34),
        displayMedium: TextStyle(fontSize: 28),
        displaySmall: TextStyle(fontSize: 22),
        headlineLarge: TextStyle(fontSize: 34),
        headlineMedium: TextStyle(fontSize: 28),
        headlineSmall: TextStyle(fontSize: 22),
        titleLarge: TextStyle(fontSize: 17),
        titleMedium: TextStyle(fontSize: 15),
        titleSmall: TextStyle(fontSize: 12),
        bodyLarge: TextStyle(fontSize: 17),
        bodyMedium: TextStyle(fontSize: 15),
        bodySmall: TextStyle(fontSize: 12),
        labelLarge: TextStyle(fontSize: 17),
        labelMedium: TextStyle(fontSize: 15),
        labelSmall: TextStyle(fontSize: 12),
      );
    });

    test('multiplier=1.0 保持字号不变', () {
      final scaled = AppTheme.scaleTextTheme(baseTheme, 1.0);
      expect(scaled.displayLarge?.fontSize, 34);
      expect(scaled.displayMedium?.fontSize, 28);
      expect(scaled.bodyLarge?.fontSize, 17);
    });

    test('multiplier=2.0 字号翻倍', () {
      final scaled = AppTheme.scaleTextTheme(baseTheme, 2.0);
      expect(scaled.displayLarge?.fontSize, 68);
      expect(scaled.displayMedium?.fontSize, 56);
      expect(scaled.bodyMedium?.fontSize, 30);
    });

    test('multiplier=0.5 字号减半', () {
      final scaled = AppTheme.scaleTextTheme(baseTheme, 0.5);
      expect(scaled.displayLarge?.fontSize, 17);
      expect(scaled.displayMedium?.fontSize, 14);
      expect(scaled.bodySmall?.fontSize, 6);
    });

    test('所有 13 个 text style slot 都被缩放', () {
      final scaled = AppTheme.scaleTextTheme(baseTheme, 1.5);
      expect(scaled.displayLarge?.fontSize, 34 * 1.5);
      expect(scaled.displayMedium?.fontSize, 28 * 1.5);
      expect(scaled.displaySmall?.fontSize, 22 * 1.5);
      expect(scaled.headlineLarge?.fontSize, 34 * 1.5);
      expect(scaled.headlineMedium?.fontSize, 28 * 1.5);
      expect(scaled.headlineSmall?.fontSize, 22 * 1.5);
      expect(scaled.titleLarge?.fontSize, 17 * 1.5);
      expect(scaled.titleMedium?.fontSize, 15 * 1.5);
      expect(scaled.titleSmall?.fontSize, 12 * 1.5);
      expect(scaled.bodyLarge?.fontSize, 17 * 1.5);
      expect(scaled.bodyMedium?.fontSize, 15 * 1.5);
      expect(scaled.bodySmall?.fontSize, 12 * 1.5);
      expect(scaled.labelLarge?.fontSize, 17 * 1.5);
      expect(scaled.labelMedium?.fontSize, 15 * 1.5);
      expect(scaled.labelSmall?.fontSize, 12 * 1.5);
    });

    test('null fontSize 时使用 fallback 值', () {
      final themeWithNulls = TextTheme(
        displayLarge: baseTheme.displayLarge?.copyWith(fontSize: null),
        displayMedium: baseTheme.displayMedium?.copyWith(fontSize: null),
        displaySmall: baseTheme.displaySmall?.copyWith(fontSize: null),
        headlineLarge: baseTheme.headlineLarge?.copyWith(fontSize: null),
        headlineMedium: baseTheme.headlineMedium?.copyWith(fontSize: null),
        headlineSmall: baseTheme.headlineSmall?.copyWith(fontSize: null),
        titleLarge: baseTheme.titleLarge?.copyWith(fontSize: null),
        titleMedium: baseTheme.titleMedium?.copyWith(fontSize: null),
        titleSmall: baseTheme.titleSmall?.copyWith(fontSize: null),
        bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: null),
        bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: null),
        bodySmall: baseTheme.bodySmall?.copyWith(fontSize: null),
        labelLarge: baseTheme.labelLarge?.copyWith(fontSize: null),
        labelMedium: baseTheme.labelMedium?.copyWith(fontSize: null),
        labelSmall: baseTheme.labelSmall?.copyWith(fontSize: null),
      );
      final scaled = AppTheme.scaleTextTheme(themeWithNulls, 2.0);
      // Fallback: headline1=34, headline2=28, headline3=22, bodyText1=17, bodyText2=15, caption=12
      expect(scaled.displayLarge?.fontSize, 68);  // headline1(34) * 2
      expect(scaled.headlineLarge?.fontSize, 68);
      expect(scaled.displayMedium?.fontSize, 56); // headline2(28) * 2
      expect(scaled.bodyLarge?.fontSize, 34);     // bodyText1(17) * 2
      expect(scaled.bodySmall?.fontSize, 24);     // caption(12) * 2
    });
  });

  // =========================================================================
  // applyFontSize
  // =========================================================================
  group('applyFontSize', () {
    test('等于 getFontSizeMultiplier + scaleTextTheme 的组合', () {
      final base = const TextTheme(bodyLarge: TextStyle(fontSize: 17));
      final result = AppTheme.applyFontSize(base, FontSizeOption.larger);
      final multiplier = AppTheme.getFontSizeMultiplier(FontSizeOption.larger);
      final expected = AppTheme.scaleTextTheme(base, multiplier);

      expect(result.bodyLarge?.fontSize, expected.bodyLarge?.fontSize);
    });
  });

  // =========================================================================
  // getSeedColor
  // =========================================================================
  group('getSeedColor', () {
    test('system → md3DefaultSeed (紫色)', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.system),
          AppTheme.md3DefaultSeed);
      expect(AppTheme.getSeedColor(ThemeColorOption.system),
          const Color(0xFF6750A4));
    });

    test('blue → blueSeed', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.blue),
          const Color(0xFF2196F3));
    });

    test('orange → orangeSeed', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.orange),
          const Color(0xFFFF9800));
    });

    test('green → greenSeed', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.green),
          const Color(0xFF4CAF50));
    });

    test('red → redSeed', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.red),
          const Color(0xFFF44336));
    });

    test('purple → purpleSeed', () {
      expect(AppTheme.getSeedColor(ThemeColorOption.purple),
          const Color(0xFF9C27B0));
    });

    test('6 种颜色互不相同', () {
      final colors = ThemeColorOption.values
          .map((o) => AppTheme.getSeedColor(o))
          .toSet();
      expect(colors.length, 6);
    });
  });

  // =========================================================================
  // generateLightColorScheme / generateDarkColorScheme
  // =========================================================================
  group('ColorScheme 生成', () {
    test('generateLightColorScheme 返回 light 亮度', () {
      final scheme =
          AppTheme.generateLightColorScheme(ThemeColorOption.system);
      expect(scheme.brightness, Brightness.light);
    });

    test('generateDarkColorScheme 返回 dark 亮度', () {
      final scheme =
          AppTheme.generateDarkColorScheme(ThemeColorOption.system);
      expect(scheme.brightness, Brightness.dark);
    });

    test('不同 seed 产生不同的 light scheme', () {
      final blue = AppTheme.generateLightColorScheme(ThemeColorOption.blue);
      final red = AppTheme.generateLightColorScheme(ThemeColorOption.red);
      expect(blue.primary, isNot(red.primary));
    });

    test('不同 seed 产生不同的 dark scheme', () {
      final blue = AppTheme.generateDarkColorScheme(ThemeColorOption.blue);
      final red = AppTheme.generateDarkColorScheme(ThemeColorOption.red);
      expect(blue.primary, isNot(red.primary));
    });

    test('light scheme 和 dark scheme 不同', () {
      final light =
          AppTheme.generateLightColorScheme(ThemeColorOption.system);
      final dark = AppTheme.generateDarkColorScheme(ThemeColorOption.system);
      expect(light.primary, isNot(dark.primary));
    });

    test('所有 6 种 seed 都能正常生成 light scheme', () {
      for (final color in ThemeColorOption.values) {
        final scheme = AppTheme.generateLightColorScheme(color);
        expect(scheme.brightness, Brightness.light);
        expect(scheme.primary, isNotNull);
      }
    });

    test('所有 6 种 seed 都能正常生成 dark scheme', () {
      for (final color in ThemeColorOption.values) {
        final scheme = AppTheme.generateDarkColorScheme(color);
        expect(scheme.brightness, Brightness.dark);
        expect(scheme.primary, isNotNull);
      }
    });
  });

  // =========================================================================
  // generateLightTheme / generateDarkTheme
  // =========================================================================
  group('ThemeData 生成', () {
    test('generateLightTheme 使用 Material 3', () {
      final theme =
          AppTheme.generateLightTheme(ThemeColorOption.system);
      expect(theme.useMaterial3, true);
    });

    test('generateDarkTheme 使用 Material 3', () {
      final theme =
          AppTheme.generateDarkTheme(ThemeColorOption.system);
      expect(theme.useMaterial3, true);
    });

    test('generateLightTheme 的 colorScheme 亮度为 light', () {
      final theme =
          AppTheme.generateLightTheme(ThemeColorOption.blue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('generateDarkTheme 的 colorScheme 亮度为 dark', () {
      final theme =
          AppTheme.generateDarkTheme(ThemeColorOption.blue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('不同 fontSize 生成不同 textTheme', () {
      final small = AppTheme.generateLightTheme(ThemeColorOption.system,
          fontSize: FontSizeOption.smallest);
      final large = AppTheme.generateLightTheme(ThemeColorOption.system,
          fontSize: FontSizeOption.largest);
      expect(
          small.textTheme.bodyLarge?.fontSize,
          lessThan(
              large.textTheme.bodyLarge?.fontSize ?? double.infinity));
    });

    test('默认 fontSize 为 medium (1.0)', () {
      final theme =
          AppTheme.generateLightTheme(ThemeColorOption.system);
      final baseSize = AppTheme.lightTheme.textTheme.bodyLarge?.fontSize;
      expect(theme.textTheme.bodyLarge?.fontSize, baseSize);
    });
  });

  // =========================================================================
  // 静态主题常量
  // =========================================================================
  group('静态主题常量', () {
    test('lightTheme 使用 Material 3', () {
      expect(AppTheme.lightTheme.useMaterial3, true);
    });

    test('darkTheme 使用 Material 3', () {
      expect(AppTheme.darkTheme.useMaterial3, true);
    });

    test('lightTheme colorScheme 亮度为 light', () {
      expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('darkTheme colorScheme 亮度为 dark', () {
      expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('lightTheme textTheme 配置正确', () {
      final tt = AppTheme.lightTheme.textTheme;
      expect(tt.displayLarge?.fontSize, 34);
      expect(tt.displayMedium?.fontSize, 28);
      expect(tt.displaySmall?.fontSize, 22);
      expect(tt.bodyLarge?.fontSize, 17);
      expect(tt.bodyMedium?.fontSize, 15);
      expect(tt.bodySmall?.fontSize, 12);
    });
  });

  // =========================================================================
  // 静态颜色常量
  // =========================================================================
  group('静态颜色常量', () {
    test('errorColor 红色', () {
      expect(AppTheme.errorColor, const Color(0xFFBA1A1A));
    });

    test('warningColor 黄色', () {
      expect(AppTheme.warningColor, const Color(0xFFE4BE00));
    });

    test('语义颜色互不相同', () {
      final set = {
        AppTheme.colorPositive,
        AppTheme.colorMedium,
        AppTheme.colorNegative,
        AppTheme.colorUnknown,
      };
      expect(set.length, 4);
    });

    test('暗色语义颜色互不相同', () {
      final set = {
        AppTheme.darkColorPositive,
        AppTheme.darkColorMedium,
        AppTheme.darkColorNegative,
        AppTheme.darkColorUnknown,
      };
      expect(set.length, 4);
    });

    test('spacing 常量递增', () {
      expect(AppTheme.spacingS, greaterThan(AppTheme.spacingXS));
      expect(AppTheme.spacingM, greaterThan(AppTheme.spacingS));
      expect(AppTheme.spacingL, greaterThan(AppTheme.spacingM));
      expect(AppTheme.spacingXL, greaterThan(AppTheme.spacingL));
    });
  });
}
