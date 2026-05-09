import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/components/home/shanghai_metro_map.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final NetworkManager _networkManager = NetworkManager();

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
        _networkManager.get('/common-routes/user/default'),
        _networkManager.get('/travel-alerts'),
      ]).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('请求超时');
        },
      );

      final routesResponse = results[0].data;
      final alertsResponse = results[1].data;

      if (mounted) {
        setState(() {
          _commonRoutes = routesResponse is List
              ? List<Map<String, dynamic>>.from(routesResponse)
              : [];
          _travelAlerts = alertsResponse is List
              ? List<Map<String, dynamic>>.from(alertsResponse)
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能出行'),
        backgroundColor: AppTheme.primaryColor,
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
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.borderRadiusL,
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      const Text(
                        '快捷规划',
                        style: AppTheme.headline3,
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
                          context.go('/route-plan');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppTheme.spacingM),

              // 常用路线卡片
              const Text(
                '常用路线',
                style: AppTheme.headline3,
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
                                  elevation: 2,
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
                                              style: AppTheme.bodyText1,
                                            ),
                                            SizedBox(height: AppTheme.spacingS),
                                            Text(
                                              '${route['time']} · ${route['distance']}',
                                              style: AppTheme.bodyText2,
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
              const Text(
                '实时出行提醒',
                style: AppTheme.headline3,
              ),
              SizedBox(height: AppTheme.spacingM),
              Column(
                children: _travelAlerts.map((alert) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                    margin: EdgeInsets.only(bottom: AppTheme.spacingM),
                    color: alert['type'] == 'delay'
                        ? AppTheme.warningColor.withOpacity(0.1)
                        : AppTheme.errorColor.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert['title'],
                            style: AppTheme.bodyText1,
                          ),
                          SizedBox(height: AppTheme.spacingS),
                          Text(
                            alert['message'],
                            style: AppTheme.bodyText2,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: AppTheme.spacingM),

              // 核心功能快捷入口
              const Text(
                '快捷功能',
                style: AppTheme.headline3,
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
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: AppTheme.borderRadiusL,
                          ),
                          child: Icon(
                            item['icon'],
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Flexible(
                          child: Text(
                            item['title'],
                            style: AppTheme.bodyText2,
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
