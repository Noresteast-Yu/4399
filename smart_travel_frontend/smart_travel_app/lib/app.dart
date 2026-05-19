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
        colorScheme: lightDynamic.copyWith(
          primary: lightDynamic.primary.withOpacity(0.9),
          primaryContainer: lightDynamic.primaryContainer.withOpacity(0.85),
          secondary: lightDynamic.secondary.withOpacity(0.9),
          secondaryContainer: lightDynamic.secondaryContainer.withOpacity(0.85),
          tertiary: lightDynamic.tertiary.withOpacity(0.9),
          tertiaryContainer: lightDynamic.tertiaryContainer.withOpacity(0.85),
          surface: lightDynamic.surface.withOpacity(0.95),
          surfaceContainer: lightDynamic.surfaceContainer.withOpacity(0.9),
          surfaceContainerHigh:
              lightDynamic.surfaceContainerHigh.withOpacity(0.92),
          surfaceContainerHighest:
              lightDynamic.surfaceContainerHighest.withOpacity(0.95),
        ),
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
        colorScheme: darkDynamic.copyWith(
          primary: darkDynamic.primary.withOpacity(0.95),
          primaryContainer: darkDynamic.primaryContainer.withOpacity(0.9),
          secondary: darkDynamic.secondary.withOpacity(0.95),
          secondaryContainer: darkDynamic.secondaryContainer.withOpacity(0.9),
          tertiary: darkDynamic.tertiary.withOpacity(0.95),
          tertiaryContainer: darkDynamic.tertiaryContainer.withOpacity(0.9),
          surface: darkDynamic.surface.withOpacity(0.98),
          surfaceContainer: darkDynamic.surfaceContainer.withOpacity(0.95),
          surfaceContainerHigh:
              darkDynamic.surfaceContainerHigh.withOpacity(0.97),
          surfaceContainerHighest:
              darkDynamic.surfaceContainerHighest.withOpacity(0.98),
        ),
        textTheme:
            AppTheme.applyFontSize(AppTheme.darkTheme.textTheme, fontSize),
      );
    }

    return AppTheme.generateDarkTheme(themeColor, fontSize: fontSize);
  }
}
