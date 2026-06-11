import 'package:flutter/material.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';

class AppTheme {
  static const Color secondaryColor = Color(0xFF585E72);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color warningColor = Color(0xFFE4BE00);
  static const Color infoColor = Color(0xFF5AC8FA);

  static const Color colorPositive = Color(0xFF46C705);
  static const Color colorMedium = Color(0xFFE4BE00);
  static const Color colorNegative = Color(0xFFE40000);
  static const Color colorUnknown = Color(0xFF808080);

  static const Color darkColorPositive = Color(0xFF88D867);
  static const Color darkColorMedium = Color(0xFFE7CA3F);
  static const Color darkColorNegative = Color(0xFFFF795B);
  static const Color darkColorUnknown = Color(0xFFBFBFBF);

  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color textPrimary = Color(0xFF1A1B21);
  static const Color textSecondary = Color(0xFF45464F);
  static const Color textTertiary = Color(0xFF757680);

  static const TextStyle headline1 = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headline2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle headline3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  static double getFontSizeMultiplier(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.smallest:
        return 0.8;
      case FontSizeOption.smaller:
        return 0.9;
      case FontSizeOption.medium:
        return 1.0;
      case FontSizeOption.larger:
        return 1.15;
      case FontSizeOption.largest:
        return 1.3;
    }
  }

  static TextTheme scaleTextTheme(TextTheme base, double multiplier) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontSize: (base.displayLarge!.fontSize ?? headline1.fontSize!) *
              multiplier),
      displayMedium: base.displayMedium?.copyWith(
          fontSize: (base.displayMedium!.fontSize ?? headline2.fontSize!) *
              multiplier),
      displaySmall: base.displaySmall?.copyWith(
          fontSize: (base.displaySmall!.fontSize ?? headline3.fontSize!) *
              multiplier),
      headlineLarge: base.headlineLarge?.copyWith(
          fontSize: (base.headlineLarge!.fontSize ?? headline1.fontSize!) *
              multiplier),
      headlineMedium: base.headlineMedium?.copyWith(
          fontSize: (base.headlineMedium!.fontSize ?? headline2.fontSize!) *
              multiplier),
      headlineSmall: base.headlineSmall?.copyWith(
          fontSize: (base.headlineSmall!.fontSize ?? headline3.fontSize!) *
              multiplier),
      titleLarge: base.titleLarge?.copyWith(
          fontSize:
              (base.titleLarge!.fontSize ?? bodyText1.fontSize!) * multiplier),
      titleMedium: base.titleMedium?.copyWith(
          fontSize:
              (base.titleMedium!.fontSize ?? bodyText2.fontSize!) * multiplier),
      titleSmall: base.titleSmall?.copyWith(
          fontSize:
              (base.titleSmall!.fontSize ?? caption.fontSize!) * multiplier),
      bodyLarge: base.bodyLarge?.copyWith(
          fontSize:
              (base.bodyLarge!.fontSize ?? bodyText1.fontSize!) * multiplier),
      bodyMedium: base.bodyMedium?.copyWith(
          fontSize:
              (base.bodyMedium!.fontSize ?? bodyText2.fontSize!) * multiplier),
      bodySmall: base.bodySmall?.copyWith(
          fontSize:
              (base.bodySmall!.fontSize ?? caption.fontSize!) * multiplier),
      labelLarge: base.labelLarge?.copyWith(
          fontSize:
              (base.labelLarge!.fontSize ?? bodyText1.fontSize!) * multiplier),
      labelMedium: base.labelMedium?.copyWith(
          fontSize:
              (base.labelMedium!.fontSize ?? bodyText2.fontSize!) * multiplier),
      labelSmall: base.labelSmall?.copyWith(
          fontSize:
              (base.labelSmall!.fontSize ?? caption.fontSize!) * multiplier),
    );
  }

  // 根据字体大小选项缩放 TextTheme
  static TextTheme applyFontSize(TextTheme base, FontSizeOption fontSize) {
    final multiplier = getFontSizeMultiplier(fontSize);
    return scaleTextTheme(base, multiplier);
  }

  // 间距规则
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;

  // 圆角规范
  static const BorderRadius borderRadiusS =
      BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadiusM =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusL =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(16));

  // MD3 主题色种子
  static const Color md3DefaultSeed = Color(0xFF6750A4); // MD3 标准默认色
  static const Color blueSeed = Color(0xFF2196F3);
  static const Color greenSeed = Color(0xFF4CAF50);
  static const Color orangeSeed = Color(0xFFFF9800);
  static const Color redSeed = Color(0xFFF44336);
  static const Color purpleSeed = Color(0xFF9C27B0);

  // 主题色映射
  static Color getSeedColor(ThemeColorOption color) {
    switch (color) {
      case ThemeColorOption.blue:
        return blueSeed;
      case ThemeColorOption.orange:
        return orangeSeed;
      case ThemeColorOption.green:
        return greenSeed;
      case ThemeColorOption.red:
        return redSeed;
      case ThemeColorOption.purple:
        return purpleSeed;
      case ThemeColorOption.system:
        return md3DefaultSeed;
    }
  }

  // 动态生成亮色主题方案
  static ColorScheme generateLightColorScheme(ThemeColorOption color) {
    final seedColor = getSeedColor(color);
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
  }

  // 动态生成暗色主题方案
  static ColorScheme generateDarkColorScheme(ThemeColorOption color) {
    final seedColor = getSeedColor(color);
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
  }

  // 生成亮主题
  static ThemeData generateLightTheme(ThemeColorOption color,
      {FontSizeOption fontSize = FontSizeOption.medium}) {
    final colorScheme = generateLightColorScheme(color);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        bodyLarge: bodyText1,
        bodyMedium: bodyText2,
        bodySmall: caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
    return base.copyWith(
      textTheme: applyFontSize(base.textTheme, fontSize),
    );
  }

  // 生成暗主题
  static ThemeData generateDarkTheme(ThemeColorOption color,
      {FontSizeOption fontSize = FontSizeOption.medium}) {
    final colorScheme = generateDarkColorScheme(color);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        displayLarge: headline1,
        displayMedium: headline2,
        displaySmall: headline3,
        bodyLarge: bodyText1,
        bodyMedium: bodyText2,
        bodySmall: caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
    return base.copyWith(
      textTheme: applyFontSize(base.textTheme, fontSize),
    );
  }

  // 默认亮色主题（MD3 标准配色）
  static ThemeData get lightTheme => generateLightTheme(ThemeColorOption.system);

  // 默认暗色主题（MD3 标准配色）
  static ThemeData get darkTheme => generateDarkTheme(ThemeColorOption.system);
}
