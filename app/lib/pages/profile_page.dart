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
    {'title': '服务配置', 'icon': Icons.dns, 'route': '/profile/api-settings'},
    {'title': '出行偏好', 'icon': Icons.settings, 'route': '/profile/preferences'},
    {'title': '行动能力设置', 'icon': Icons.accessibility, 'route': '/profile/ability'},
    {'title': '行李设置', 'icon': Icons.business_center, 'route': '/profile/luggage'},
    {'title': '外观', 'icon': Icons.palette, 'route': '/profile/theme'},
    {'title': '消息通知', 'icon': Icons.notifications, 'route': '/profile/notifications'},
  ];

  final List<Map<String, dynamic>> _helperFunctions = [
    {'title': '帮助中心', 'icon': Icons.help, 'route': '/profile/help-center'},
    {'title': '意见反馈', 'icon': Icons.feedback, 'route': '/profile/feedback'},
    {'title': '关于APP', 'icon': Icons.info, 'route': '/profile/about'},
    {'title': '用户协议', 'icon': Icons.description, 'route': '/profile/user-agreement'},
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
        if (data is Map && data['success'] == true) {
          final routesData = data['data'];
          _commonRoutes = routesData is List
              ? List<Map<String, dynamic>>.from(routesData)
              : [];
        } else if (data is List) {
          _commonRoutes = List<Map<String, dynamic>>.from(data);
        } else {
          _commonRoutes = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddRouteDialog() async {
    final startController = TextEditingController();
    final endController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加常用路线'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: startController,
              decoration: const InputDecoration(
                labelText: '起点',
                hintText: '请输入起点站名',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            SizedBox(height: AppTheme.spacingM),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: '终点',
                hintText: '请输入终点站名',
                prefixIcon: Icon(Icons.location_off),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final start = startController.text.trim();
              final end = endController.text.trim();

              if (start.isEmpty || end.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入起点和终点'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final response = await _networkManager.post(
                  '/common-routes/add',
                  data: {'start': start, 'end': end},
                );

                if (response.data is Map && response.data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('添加成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCommonRoutes();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.data['error'] ?? '添加失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('添加失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoute(Map<String, dynamic> route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${route['start']} → ${route['end']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _networkManager.delete(
        '/common-routes/${route['id']}',
      );

      if (response.data is Map && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCommonRoutes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['error'] ?? '删除失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToRoute(Map<String, dynamic> route) {
    final start = route['start'] ?? '';
    final end = route['end'] ?? '';

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('路线信息不完整'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.push(
      '/route-plan?start=${Uri.encodeComponent(start)}&end=${Uri.encodeComponent(end)}',
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '常用路线',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: colorScheme.primary),
                  onPressed: _showAddRouteDialog,
                  tooltip: '添加常用路线',
                ),
              ],
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
                              Icon(
                                Icons.cloud_off,
                                size: 32,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(height: AppTheme.spacingS),
                              Text(
                                '后端服务未连接',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: AppTheme.spacingXS),
                              Text(
                                '请前往 个人中心 → 设置 → 服务配置 设置后端地址',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: _loadCommonRoutes,
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _commonRoutes.isEmpty
                        ? Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingL),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.route,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  Text(
                                    '暂无常用路线',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacingS),
                                  Text(
                                    '点击 + 按钮添加常用路线',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
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
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${route['start'] ?? ''} → ${route['end'] ?? ''}',
                                              style:
                                                  textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (route['time'] != null ||
                                                route['distance'] != null)
                                              SizedBox(height: 4),
                                            if (route['time'] != null ||
                                                route['distance'] != null)
                                              Text(
                                                '${route['time'] ?? ''}${route['time'] != null && route['distance'] != null ? ' · ' : ''}${route['distance'] ?? ''}',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.navigation,
                                              color: colorScheme.primary,
                                            ),
                                            onPressed: () =>
                                                _navigateToRoute(route),
                                            tooltip: '导航',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: colorScheme.error,
                                            ),
                                            onPressed: () =>
                                                _deleteRoute(route),
                                            tooltip: '删除',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
            SizedBox(height: AppTheme.spacingL),
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
