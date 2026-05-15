import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final NetworkManager _networkManager = NetworkManager();

  List<Map<String, dynamic>> _commonRoutes = [];
  bool _isLoading = true;
  String? _error;

  final List<Map<String, dynamic>> _settings = [
    {'title': '出行偏好', 'icon': Icons.settings, 'route': '/preferences'},
    {'title': '行动能力设置', 'icon': Icons.accessibility, 'route': '/ability'},
    {'title': '行李设置', 'icon': Icons.business_center, 'route': '/luggage'},
    {'title': '外观', 'icon': Icons.palette, 'route': '/theme'},
    {'title': '消息通知', 'icon': Icons.notifications, 'route': '/notifications'},
  ];

  final List<Map<String, dynamic>> _helperFunctions = [
    {'title': '帮助中心', 'icon': Icons.help},
    {'title': '意见反馈', 'icon': Icons.feedback, 'route': '/feedback'},
    {'title': '关于APP', 'icon': Icons.info, 'route': '/about'},
    {'title': '用户协议', 'icon': Icons.description},
  ];

  @override
  void initState() {
    super.initState();
    _loadCommonRoutes();
  }

  Future<void> _loadCommonRoutes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _networkManager.get('/common-routes/user/default');
      final data = response.data;

      setState(() {
        _commonRoutes =
            data is List ? List<Map<String, dynamic>>.from(data) : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(title: '个人中心'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息
            Card(
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
                        color: colorScheme.primaryContainer,
                        borderRadius: AppTheme.borderRadiusXL,
                      ),
                      child: Icon(
                        Icons.person,
                        color: colorScheme.onPrimaryContainer,
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
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '地铁跑酷换乘助手用户',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacingL),

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
                                onPressed: _loadCommonRoutes,
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
                                margin:
                                    EdgeInsets.only(bottom: AppTheme.spacingM),
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.spacingM),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${route['start'] ?? ''} → ${route['end'] ?? ''}',
                                        style: textTheme.bodyLarge,
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

            SizedBox(height: AppTheme.spacingL),

            // 设置
            Text(
              '设置',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Column(
                children: _settings.map((setting) {
                  return ListTile(
                    leading: Icon(
                      setting['icon'],
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(setting['title']),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      if (setting['route'] != null) {
                        context.push(setting['route']);
                      }
                    },
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: AppTheme.spacingL),

            // 辅助功能
            Text(
              '辅助功能',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Column(
                children: _helperFunctions.map((function) {
                  return ListTile(
                    leading: Icon(
                      function['icon'],
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(function['title']),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      if (function['route'] != null) {
                        context.push(function['route']);
                      }
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
