import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  
  // 常用路线数据
  final List<Map<String, dynamic>> _commonRoutes = [
    {
      'id': '1',
      'start': '北京南站',
      'end': '中关村',
      'time': '30分钟',
      'distance': '12公里',
    },
    {
      'id': '2',
      'start': '上海虹桥站',
      'end': '陆家嘴',
      'time': '45分钟',
      'distance': '18公里',
    },
  ];
  
  // 实时出行提醒
  final List<Map<String, dynamic>> _travelAlerts = [
    {
      'type': 'delay',
      'title': 'G102次列车晚点',
      'message': '预计晚点15分钟',
    },
    {
      'type': 'control',
      'title': '地铁2号线临时管制',
      'message': '因设备检修，部分站点暂停服务',
    },
  ];
  
  // 核心功能快捷入口
  final List<Map<String, dynamic>> _quickAccess = [
    {
      'icon': Icons.subway,
      'title': '地铁设施',
      'route': '/subway-service',
    },
    {
      'icon': Icons.train,
      'title': '高铁引导',
      'route': '/high-speed-rail',
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能出行'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            
            SizedBox(height: AppTheme.spacingL),
            
            // 常用路线卡片
            const Text(
              '常用路线',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            Column(
              children: _commonRoutes.map((route) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusM,
                  ),
                  margin: EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
            
            SizedBox(height: AppTheme.spacingL),
            
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
            
            SizedBox(height: AppTheme.spacingL),
            
            // 核心功能快捷入口
            const Text(
              '快捷功能',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickAccess.length,
              itemBuilder: (context, index) {
                final item = _quickAccess[index];
                return GestureDetector(
                  onTap: () {
                    context.go(item['route']);
                  },
                  child: Column(
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
                      Text(
                        item['title'],
                        style: AppTheme.bodyText2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0),
    );
  }
}
