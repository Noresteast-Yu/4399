import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class MapNavigationPage extends StatefulWidget {
  const MapNavigationPage({super.key});

  @override
  State<MapNavigationPage> createState() => _MapNavigationPageState();
}

class _MapNavigationPageState extends State<MapNavigationPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(title: '地图导航'),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: colorScheme.surfaceContainer,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      '地图导航功能',
                      style: textTheme.headlineSmall,
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Text(
                      '高德地图SDK在Web平台暂不支持',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(AppTheme.spacingM),
            color: colorScheme.surfaceContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('开始导航'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('暂停'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('结束'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
