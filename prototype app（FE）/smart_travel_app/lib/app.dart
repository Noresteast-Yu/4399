import 'package:flutter/material.dart';
import 'package:smart_travel_app/routes/app_router.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class SmartTravelApp extends StatelessWidget {
  const SmartTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '智能出行',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
