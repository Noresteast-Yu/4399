import 'package:flutter/material.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';

class AppTheme {
  // 品牌色
  static const Color secondaryColor = Color(0xFF585E72);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color warningColor = Color(0xFFE4BE00);
  static const Color infoColor = Color(0xFF5AC8FA);

  // 指示性颜色
  static const Color colorPositive = Color(0xFF46C705);
  static const Color colorMedium = Color(0xFFE4BE00);
  static const Color colorNegative = Color(0xFFE40000);
  static const Color colorUnknown = Color(0xFF808080);

  // 暗色指示性颜色
  static const Color darkColorPositive = Color(0xFF88D867);
  static const Color darkColorMedium = Color(0xFFE7CA3F);
  static const Color darkColorNegative = Color(0xFFFF795B);
  static const Color darkColorUnknown = Color(0xFFBFBFBF);

  // 中性色
  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color textPrimary = Color(0xFF1A1B21);
  static const Color textSecondary = Color(0xFF45464F);
  static const Color textTertiary = Color(0xFF757680);

  // 字体字号
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

  // 字体大小倍率
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

  // 根据字体大小倍率缩放 TextTheme 的字号
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
      default:
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
    final base = lightTheme.copyWith(
      colorScheme: generateLightColorScheme(color),
    );
    return base.copyWith(
      textTheme: applyFontSize(base.textTheme, fontSize),
    );
  }

  // 生成暗主题
  static ThemeData generateDarkTheme(ThemeColorOption color,
      {FontSizeOption fontSize = FontSizeOption.medium}) {
    final base = darkTheme.copyWith(
      colorScheme: generateDarkColorScheme(color),
    );
    return base.copyWith(
      textTheme: applyFontSize(base.textTheme, fontSize),
    );
  }

  // 兼容旧版本的静态主题（基于 BarcodeScanner 蓝色主题）
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF4A5C92),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBE1FF),
    onPrimaryContainer: Color(0xFF00174A),
    secondary: Color(0xFF585E72),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDDE1F9),
    onSecondaryContainer: Color(0xFF161B2C),
    tertiary: Color(0xFF745471),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFD6F8),
    onTertiaryContainer: Color(0xFF2B122B),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFAF8FF),
    onBackground: Color(0xFF1A1B21),
    surface: Color(0xFFFAF8FF),
    onSurface: Color(0xFF1A1B21),
    surfaceVariant: Color(0xFFE2E2EC),
    onSurfaceVariant: Color(0xFF45464F),
    outline: Color(0xFF757680),
    outlineVariant: Color(0xFFC5C6D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2F3036),
    onInverseSurface: Color(0xFFF1F0F7),
    inversePrimary: Color(0xFFB4C5FF),
    surfaceTint: Color(0xFF4A5C92),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB4C5FF),
    onPrimary: Color(0xFF1A2E60),
    primaryContainer: Color(0xFF324478),
    onPrimaryContainer: Color(0xFFDBE1FF),
    secondary: Color(0xFFC1C6DD),
    onSecondary: Color(0xFF2A3042),
    secondaryContainer: Color(0xFF414659),
    onSecondaryContainer: Color(0xFFDDE1F9),
    tertiary: Color(0xFFE2BBDC),
    onTertiary: Color(0xFF422741),
    tertiaryContainer: Color(0xFF5A3D58),
    onTertiaryContainer: Color(0xFFFFD6F8),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF121318),
    onBackground: Color(0xFFE3E2E9),
    surface: Color(0xFF121318),
    onSurface: Color(0xFFE3E2E9),
    surfaceVariant: Color(0xFF45464F),
    onSurfaceVariant: Color(0xFFC5C6D0),
    outline: Color(0xFF8F909A),
    outlineVariant: Color(0xFF45464F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE3E2E9),
    onInverseSurface: Color(0xFF2F3036),
    inversePrimary: Color(0xFF4A5C92),
    surfaceTint: Color(0xFFB4C5FF),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
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

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
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
}
