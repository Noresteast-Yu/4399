import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/providers/theme_provider.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';
import 'package:smart_travel_app/routes/app_router.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class SmartTravelApp extends StatelessWidget {
  const SmartTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadSettings(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserPreferencesProvider()..loadPreferences(),
        ),
      ],
      child: Consumer2<ThemeProvider, UserPreferencesProvider>(
        builder: (context, themeProvider, userPreferences, child) {
          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp.router(
                title: '地铁跑酷换乘助手',
                theme: _buildLightTheme(
                  themeProvider.themeColor,
                  themeProvider.fontSize,
                  lightDynamic,
                ),
                darkTheme: _buildDarkTheme(
                  themeProvider.themeColor,
                  themeProvider.fontSize,
                  darkDynamic,
                ),
                themeMode: themeProvider.themeModeEnum,
                routerConfig: AppRouter.router,
              );
            },
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme(
    ThemeColorOption themeColor,
    FontSizeOption fontSize,
    ColorScheme? lightDynamic,
  ) {
    final useDynamicColor = themeColor == ThemeColorOption.system;

    if (useDynamicColor && lightDynamic != null) {
      return AppTheme.lightTheme.copyWith(
        colorScheme: lightDynamic,
        textTheme:
            AppTheme.applyFontSize(AppTheme.lightTheme.textTheme, fontSize),
      );
    }

    return AppTheme.generateLightTheme(themeColor, fontSize: fontSize);
  }

  ThemeData _buildDarkTheme(
    ThemeColorOption themeColor,
    FontSizeOption fontSize,
    ColorScheme? darkDynamic,
  ) {
    final useDynamicColor = themeColor == ThemeColorOption.system;

    if (useDynamicColor && darkDynamic != null) {
      return AppTheme.darkTheme.copyWith(
        colorScheme: darkDynamic,
        textTheme:
            AppTheme.applyFontSize(AppTheme.darkTheme.textTheme, fontSize),
      );
    }

    return AppTheme.generateDarkTheme(themeColor, fontSize: fontSize);
  }
}
