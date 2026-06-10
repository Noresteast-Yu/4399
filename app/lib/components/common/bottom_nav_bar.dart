import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: colorScheme.surfaceContainerHighest,
      indicatorColor: colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go(NavigationMemory.routePlanLocation ?? '/route-plan');
            break;
          case 2:
            context.go('/subway-service');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: '首页',
        ),
        NavigationDestination(
          icon: Icon(Icons.navigation),
          label: '规划',
        ),
        NavigationDestination(
          icon: Icon(Icons.subway),
          label: '服务',
        ),
        NavigationDestination(
          icon: Icon(Icons.person),
          label: '设置',
        ),
      ],
    );
  }
}
