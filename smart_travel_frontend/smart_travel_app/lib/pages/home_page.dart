import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/components/home/shanghai_metro_map.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _startController =
      TextEditingController(text: '同济大学');
  final TextEditingController _endController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _commonRoutes = [];
  List<Map<String, dynamic>> _travelAlerts = [];
  bool _isLoading = true;
  String? _error;

  // 核心功能快捷入口
  final List<Map<String, dynamic>> _quickAccess = [
    {
      'icon': Icons.subway,
      'title': '地铁设施',
      'route': '/subway-service',
    },
    {
      'icon': Icons.access_time,
      'title': '换乘时间',
      'route': '/transfer-time',
    },
    {
      'icon': Icons.navigation,
      'title': '智能规划',
      'route': '/route-plan',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _apiService.getCommonRoutes('default'),
        _apiService.getTravelAlerts(),
      ]).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('请求超时');
        },
      );

      final routesResponse = results[0];
      final alertsResponse = results[1];

      if (mounted) {
        setState(() {
          _commonRoutes = routesResponse.success && routesResponse.data != null
              ? List<Map<String, dynamic>>.from(routesResponse.data!)
              : [];
          _travelAlerts = alertsResponse.success && alertsResponse.data != null
              ? List<Map<String, dynamic>>.from(alertsResponse.data!)
              : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _commonRoutes = [];
          _travelAlerts = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2),
            border: Border.all(color: colorScheme.primary, width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '地铁跑酷换乘助手',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上海地铁地图
              ShanghaiMetroMap(
                onStationSelected: (station, isStart) {
                  if (isStart) {
                    _startController.text = station;
                  } else {
                    _endController.text = station;
                  }
                },
                initialStartStation: _startController.text.isNotEmpty
                    ? _startController.text
                    : null,
                initialEndStation:
                    _endController.text.isNotEmpty ? _endController.text : null,
              ),
              SizedBox(height: AppTheme.spacingM),
              // 快捷规划入口
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusL,
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      Text(
                        '快捷规划',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      CommonInput(
                        hintText: '请输入起点',
                        controller: _startController,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      CommonInput(
                        hintText: '请输入终点',
                        controller: _endController,
                        prefixIcon: const Icon(Icons.location_off),
                      ),
                      SizedBox(height: AppTheme.spacingL),
                      CommonButton(
                        text: '开始规划',
                        onPressed: () {
                          context.go(
                              '/route-plan?start=${Uri.encodeComponent(_startController.text)}&end=${Uri.encodeComponent(_endController.text)}');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingM),

              // 常用路线卡片
              Text(
                '常用路线',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Card(
                          child: Padding(
                            padding: EdgeInsets.all(AppTheme.spacingM),
                            child: Column(
                              children: [
                                Text('加载失败: $_error'),
                                TextButton(
                                  onPressed: _loadData,
                                  child: const Text('重试'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _commonRoutes.isEmpty
                          ? const Card(
                              child: Padding(
                                padding: EdgeInsets.all(AppTheme.spacingM),
                                child: Text('暂无常用路线'),
                              ),
                            )
                          : Column(
                              children: _commonRoutes.map((route) {
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppTheme.borderRadiusM,
                                  ),
                                  margin: EdgeInsets.only(
                                      bottom: AppTheme.spacingM),
                                  child: Padding(
                                    padding: EdgeInsets.all(AppTheme.spacingM),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${route['start']} → ${route['end']}',
                                              style: textTheme.bodyLarge,
                                            ),
                                            SizedBox(height: AppTheme.spacingS),
                                            Text(
                                              '${route['time']} · ${route['distance']}',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        CommonButton(
                                          text: '导航',
                                          onPressed: () {
                                            // 发起导航
                                          },
                                          isPrimary: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

              SizedBox(height: AppTheme.spacingM),

              // 实时出行看板
              Text(
                '实时出行提醒',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
              Column(
                children: _travelAlerts.map((alert) {
                  final isWarning = alert['type'] == 'delay';
                  final alertColor = isWarning
                      ? colorScheme.tertiaryContainer
                      : colorScheme.errorContainer;
                  final alertOnColor = isWarning
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onErrorContainer;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                    margin: EdgeInsets.only(bottom: AppTheme.spacingM),
                    color: alertColor,
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'],
                            style: textTheme.bodyLarge?.copyWith(
                              color: alertOnColor,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingS),
                          Text(
                            alert['message'],
                            style: textTheme.bodyMedium?.copyWith(
                              color: alertOnColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppTheme.spacingM),

              // 核心功能快捷入口
              Text(
                '快捷功能',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
              GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _quickAccess.map((item) {
                  return GestureDetector(
                    onTap: () {
                      context.go(item['route']);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: AppTheme.borderRadiusL,
                          ),
                          child: Icon(
                            item['icon'],
                            color: colorScheme.onSecondaryContainer,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Flexible(
                          child: Text(
                            item['title'],
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
