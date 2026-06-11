import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _routeUpdates = true;
  bool _delayAlerts = true;
  bool _maintenanceNotices = true;
  bool _promotionAlerts = false;
  bool _systemMessages = true;
  bool _isLoadingSettings = true;
  bool _isLoadingNotifications = true;
  String? _errorMessage;

  static const _keyRouteUpdates = 'notif_route_updates';
  static const _keyDelayAlerts = 'notif_delay_alerts';
  static const _keyMaintenance = 'notif_maintenance';
  static const _keyPromotion = 'notif_promotion';
  static const _keySystem = 'notif_system';

  List<Map<String, dynamic>> _notifications = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _routeUpdates = prefs.getBool(_keyRouteUpdates) ?? true;
      _delayAlerts = prefs.getBool(_keyDelayAlerts) ?? true;
      _maintenanceNotices = prefs.getBool(_keyMaintenance) ?? true;
      _promotionAlerts = prefs.getBool(_keyPromotion) ?? false;
      _systemMessages = prefs.getBool(_keySystem) ?? true;
      _isLoadingSettings = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getTravelAlerts();

      if (response.success && response.data != null) {
        setState(() {
          _notifications = response.data!.map((alert) {
            final alertMap = alert as Map<String, dynamic>;
            return {
              'id': (alertMap['id'] ?? '').toString(),
              'title': alertMap['title'] ?? '出行提醒',
              'content': alertMap['content'] ?? '',
              'time': _formatTime(alertMap['createdAt'] ?? ''),
              'type': _mapAlertType(alertMap['type'] ?? 'service'),
              'severity': alertMap['severity'] ?? 'info',
              'isRead': false,
            };
          }).toList();
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _errorMessage = response.error ?? '获取通知失败';
          _isLoadingNotifications = false;
          _notifications = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络连接失败，请检查后端服务';
        _isLoadingNotifications = false;
        _notifications = [];
      });
    }
  }

  String _mapAlertType(String backendType) {
    switch (backendType.toLowerCase()) {
      case 'delay':
      case 'disruption':
        return 'delay';
      case 'maintenance':
      case 'construction':
        return 'maintenance';
      case 'promotion':
      case 'event':
        return 'promotion';
      case 'system':
        return 'system';
      case 'service':
      default:
        return 'route';
    }
  }

  String _formatTime(String createdAt) {
    if (createdAt.isEmpty) return '刚刚';
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) return '刚刚';
      if (difference.inMinutes < 60) return '${difference.inMinutes}分钟前';
      if (difference.inHours < 24) return '${difference.inHours}小时前';
      if (difference.inDays < 7) return '${difference.inDays}天前';
      return '${dateTime.month}-${dateTime.day}';
    } catch (e) {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '消息通知',
        showBack: true,
      ),
      body: _isLoadingSettings
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      '通知设置',
                      [
                        _buildSwitchOption(
                          context,
                          '路线更新',
                          '接收路线变更、临时调整等通知',
                          _routeUpdates,
                          (value) {
                            setState(() => _routeUpdates = value);
                            _saveSetting(_keyRouteUpdates, value);
                          },
                        ),
                        _buildSwitchOption(
                          context,
                          '延误提醒',
                          '接收线路延误、故障等实时提醒',
                          _delayAlerts,
                          (value) {
                            setState(() => _delayAlerts = value);
                            _saveSetting(_keyDelayAlerts, value);
                          },
                        ),
                        _buildSwitchOption(
                          context,
                          '维护通知',
                          '接收设备检修、线路维护等通知',
                          _maintenanceNotices,
                          (value) {
                            setState(() => _maintenanceNotices = value);
                            _saveSetting(_keyMaintenance, value);
                          },
                        ),
                        _buildSwitchOption(
                          context,
                          '优惠活动',
                          '接收优惠券、活动等推广信息',
                          _promotionAlerts,
                          (value) {
                            setState(() => _promotionAlerts = value);
                            _saveSetting(_keyPromotion, value);
                          },
                        ),
                        _buildSwitchOption(
                          context,
                          '系统消息',
                          '接收系统升级、功能更新等通知',
                          _systemMessages,
                          (value) {
                            setState(() => _systemMessages = value);
                            _saveSetting(_keySystem, value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '通知列表',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (var notification in _notifications) {
                                  notification['isRead'] = true;
                                }
                              });
                            },
                            child: Text(
                              '全部已读',
                              style: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    if (_isLoadingNotifications)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingXL),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorMessage != null)
                      _buildErrorWidget(context)
                    else if (_notifications.isEmpty)
                      _buildEmptyWidget(context)
                    else
                      ..._notifications.map(
                          (notification) => _buildNotificationCard(
                                context,
                                notification,
                              )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              _errorMessage ?? '加载失败',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingM),
            FilledButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              '暂无通知',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Card(
          shape: const RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusL,
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption(
    BuildContext context,
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      title: Text(
        title,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUnread = !notification['isRead'];

    IconData icon;
    Color iconColor;
    switch (notification['type']) {
      case 'route':
        icon = Icons.route;
        iconColor = colorScheme.primary;
        break;
      case 'delay':
        icon = Icons.warning_amber;
        iconColor = colorScheme.error;
        break;
      case 'maintenance':
        icon = Icons.build;
        iconColor = colorScheme.tertiary;
        break;
      case 'promotion':
        icon = Icons.local_offer;
        iconColor = colorScheme.tertiary;
        break;
      case 'system':
        icon = Icons.system_update;
        iconColor = colorScheme.secondary;
        break;
      default:
        icon = Icons.notifications;
        iconColor = colorScheme.primary;
    }

    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusM,
      ),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: AppTheme.borderRadiusM,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['content'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
