import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 常用路线
  final List<Map<String, dynamic>> _commonRoutes = [
    {'id': '1', 'start': '北京南站', 'end': '中关村'},
    {'id': '2', 'start': '上海虹桥站', 'end': '陆家嘴'},
  ];

  // 设置项
  final List<Map<String, dynamic>> _settings = [
    {'title': '出行偏好', 'icon': Icons.settings, 'route': '/preferences'},
    {'title': '行动能力设置', 'icon': Icons.accessibility, 'route': '/ability'},
    {'title': '行李设置', 'icon': Icons.business_center, 'route': '/luggage'},
    {'title': '字体大小', 'icon': Icons.text_fields, 'route': '/font'},
    {'title': '夜间模式', 'icon': Icons.nights_stay, 'route': '/theme'},
    {'title': '消息通知', 'icon': Icons.notifications, 'route': '/notifications'},
  ];

  // 辅助功能
  final List<Map<String, dynamic>> _helperFunctions = [
    {'title': '帮助中心', 'icon': Icons.help},
    {'title': '意见反馈', 'icon': Icons.feedback},
    {'title': '关于APP', 'icon': Icons.info},
    {'title': '用户协议', 'icon': Icons.description},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '个人中心'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: AppTheme.borderRadiusXL,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '用户',
                            style: AppTheme.headline3,
                          ),
                          Text(
                            '智能出行用户',
                            style: AppTheme.bodyText2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacingL),

            // 常用路线
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
                        Text(
                          '${route['start']} → ${route['end']}',
                          style: AppTheme.bodyText1,
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: AppTheme.spacingL),

            // 设置
            const Text(
              '设置',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Column(
                children: _settings.map((setting) {
                  return ListTile(
                    leading: Icon(setting['icon']),
                    title: Text(setting['title']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 导航到设置页面
                    },
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: AppTheme.spacingL),

            // 辅助功能
            const Text(
              '辅助功能',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Column(
                children: _helperFunctions.map((function) {
                  return ListTile(
                    leading: Icon(function['icon']),
                    title: Text(function['title']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 导航到对应页面
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }
}
