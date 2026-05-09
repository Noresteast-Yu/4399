import 'package:flutter/material.dart';

class AppTheme {
  // 品牌色
  static const Color primaryColor = Color(0xFF006C49);
  static const Color secondaryColor = Color(0xFF4F6353);
  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color warningColor = Color(0xFFFF9500);
  static const Color infoColor = Color(0xFF5AC8FA);

  // 中性色
  static const Color background = Color(0xFFFBFDF8);
  static const Color surface = Color(0xFFFBFDF8);
  static const Color textPrimary = Color(0xFF191C19);
  static const Color textSecondary = Color(0xFF404943);
  static const Color textTertiary = Color(0xFF707973);

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
  static const BorderRadius borderRadiusS =
      BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadiusM =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadiusL =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(16));

  // MD3 色彩系统
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF006C49),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF96F7C5),
    onPrimaryContainer: Color(0xFF002113),
    secondary: Color(0xFF4F6353),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD1E8D3),
    onSecondaryContainer: Color(0xFF0D1F14),
    tertiary: Color(0xFF3D6373),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC0E8F9),
    onTertiaryContainer: Color(0xFF001F28),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFBFDF8),
    onBackground: Color(0xFF191C19),
    surface: Color(0xFFFBFDF8),
    onSurface: Color(0xFF191C19),
    surfaceVariant: Color(0xFFDBE5DD),
    onSurfaceVariant: Color(0xFF404943),
    outline: Color(0xFF707973),
    outlineVariant: Color(0xFFBFC9C2),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2E312E),
    onInverseSurface: Color(0xFFEFF1ED),
    inversePrimary: Color(0xFF7ADBAD),
    surfaceTint: Color(0xFF006C49),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7ADBAD),
    onPrimary: Color(0xFF003823),
    primaryContainer: Color(0xFF005234),
    onPrimaryContainer: Color(0xFF96F7C5),
    secondary: Color(0xFFB5CCB7),
    onSecondary: Color(0xFF223527),
    secondaryContainer: Color(0xFF384B3C),
    onSecondaryContainer: Color(0xFFD1E8D3),
    tertiary: Color(0xFFA4CCDF),
    onTertiary: Color(0xFF053544),
    tertiaryContainer: Color(0xFF234B5C),
    onTertiaryContainer: Color(0xFFC0E8F9),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF191C19),
    onBackground: Color(0xFFE1E3DF),
    surface: Color(0xFF191C19),
    onSurface: Color(0xFFE1E3DF),
    surfaceVariant: Color(0xFF404943),
    onSurfaceVariant: Color(0xFFBFC9C2),
    outline: Color(0xFF89938C),
    outlineVariant: Color(0xFF404943),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E3DF),
    onInverseSurface: Color(0xFF2E312E),
    inversePrimary: Color(0xFF006C49),
    surfaceTint: Color(0xFF7ADBAD),
  );

  // MD3 亮主题
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

  // MD3 暗主题
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
