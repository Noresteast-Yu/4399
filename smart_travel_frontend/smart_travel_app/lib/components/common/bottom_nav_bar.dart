import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  
  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/route-plan');
            break;
          case 2:
            context.go('/subway-service');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '首页',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.navigation),
          label: '规划',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.subway),
          label: '服务',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '我的',
        ),
      ],
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondary,
      type: BottomNavigationBarType.fixed,
    );
  }
}
