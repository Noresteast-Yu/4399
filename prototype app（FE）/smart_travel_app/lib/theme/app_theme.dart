import 'package:flutter/material.dart';

class AppTheme {
  // 品牌色
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color secondaryColor = Color(0xFF34C759);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color infoColor = Color(0xFF5AC8FA);
  
  // 中性色
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  
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
  
  // 间距规则
  static const double spacingXS = 4;
  static const double spacingS = 8;
  static const double spacingM = 16;
  static const double spacingL = 24;
  static const double spacingXL = 32;
  
  // 圆角规范
  static const BorderRadius borderRadiusS = BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadiusM = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusL = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusXL = BorderRadius.all(Radius.circular(16));
  
  // 亮主题
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: background,
      surface: surface,
    ),
    textTheme: const TextTheme(
      displayLarge: headline1,
      displayMedium: headline2,
      displaySmall: headline3,
      bodyLarge: bodyText1,
      bodyMedium: bodyText2,
      bodySmall: caption,
    ),
  );
  
  // 暗主题
  static final ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: const Color(0xFF1C1C1E),
      surface: const Color(0xFF2C2C2E),
    ),
    textTheme: const TextTheme(
      displayLarge: headline1,
      displayMedium: headline2,
      displaySmall: headline3,
      bodyLarge: bodyText1,
      bodyMedium: bodyText2,
      bodySmall: caption,
    ),
  );
}
