import 'package:flutter/material.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

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

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': '10号线运营调整通知',
      'content': '因设备检修，10号线虹桥火车站至虹桥路站区间将于明日凌晨0:00-4:00暂停运营，请提前规划出行路线。',
      'time': '2小时前',
      'type': 'route',
      'isRead': false,
    },
    {
      'id': '2',
      'title': '2号线延误提醒',
      'content': '2号线徐泾东站往浦东国际机场方向因信号故障，预计延误15分钟，请合理安排出行时间。',
      'time': '5小时前',
      'type': 'delay',
      'isRead': false,
    },
    {
      'id': '3',
      'title': '新线路开通通知',
      'content': '上海地铁19号线将于下月正式开通运营，连接虹桥枢纽与浦东机场，敬请期待！',
      'time': '1天前',
      'type': 'promotion',
      'isRead': true,
    },
    {
      'id': '4',
      'title': '系统升级完成',
      'content': '地铁跑酷换乘助手已完成系统升级，新增实时拥挤度查询功能，欢迎体验！',
      'time': '2天前',
      'type': 'system',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(
        title: '消息通知',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
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
                  (value) => setState(() => _routeUpdates = value),
                ),
                _buildSwitchOption(
                  context,
                  '延误提醒',
                  '接收线路延误、故障等实时提醒',
                  _delayAlerts,
                  (value) => setState(() => _delayAlerts = value),
                ),
                _buildSwitchOption(
                  context,
                  '维护通知',
                  '接收设备检修、线路维护等通知',
                  _maintenanceNotices,
                  (value) => setState(() => _maintenanceNotices = value),
                ),
                _buildSwitchOption(
                  context,
                  '优惠活动',
                  '接收优惠券、活动等推广信息',
                  _promotionAlerts,
                  (value) => setState(() => _promotionAlerts = value),
                ),
                _buildSwitchOption(
                  context,
                  '系统消息',
                  '接收系统升级、功能更新等通知',
                  _systemMessages,
                  (value) => setState(() => _systemMessages = value),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '通知列表',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            SizedBox(height: AppTheme.spacingM),
            ..._notifications.map((notification) => _buildNotificationCard(
                  context,
                  notification,
                )),
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
        SizedBox(height: AppTheme.spacingM),
        Card(
          shape: RoundedRectangleBorder(
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
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusM,
      ),
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: AppTheme.borderRadiusM,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            SizedBox(width: AppTheme.spacingM),
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
                  SizedBox(height: 4),
                  Text(
                    notification['content'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification['time'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
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
