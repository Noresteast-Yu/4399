import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/components/home/shanghai_full_metro_map.dart';
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
  Map<String, dynamic>? _metroArrival;
  String? _metroArrivalError;
  bool _isLoading = true;
  bool _isArrivalLoading = false;
  String? _error;

  String _selectedMetroStopId = 'mock-l10-wujiaochang';
  String _selectedMetroStopName = '五角场';
  int _selectedMetroDirection = 0;

  final List<Map<String, String>> _line10Stops = const [
    {'id': 'mock-l10-hongqiao-railway', 'name': '虹桥火车站'},
    {'id': 'mock-l10-hongqiao-t2', 'name': '虹桥2号航站楼'},
    {'id': 'mock-l10-hongqiao-t1', 'name': '虹桥1号航站楼'},
    {'id': 'mock-l10-shanghai-zoo', 'name': '上海动物园'},
    {'id': 'mock-l10-longxi-road', 'name': '龙溪路'},
    {'id': 'mock-l10-shuicheng-road', 'name': '水城路'},
    {'id': 'mock-l10-yili-road', 'name': '伊犁路'},
    {'id': 'mock-l10-songyuan-road', 'name': '宋园路'},
    {'id': 'mock-l10-hongqiao-road', 'name': '虹桥路'},
    {'id': 'mock-l10-jiaotong-university', 'name': '交通大学'},
    {'id': 'mock-l10-shanghai-library', 'name': '上海图书馆'},
    {'id': 'mock-l10-south-shaanxi-road', 'name': '陕西南路'},
    {'id': 'mock-l10-xintiandi', 'name': '一大会址·新天地'},
    {'id': 'mock-l10-laoximen', 'name': '老西门'},
    {'id': 'mock-l10-yuyuan', 'name': '豫园'},
    {'id': 'mock-l10-east-nanjing-road', 'name': '南京东路'},
    {'id': 'mock-l10-tiantong-road', 'name': '天潼路'},
    {'id': 'mock-l10-north-sichuan-road', 'name': '四川北路'},
    {'id': 'mock-l10-hailun-road', 'name': '海伦路'},
    {'id': 'mock-l10-youdian-xincun', 'name': '邮电新村'},
    {'id': 'mock-l10-siping-road', 'name': '四平路'},
    {'id': 'mock-l10-tongji-university', 'name': '同济大学'},
    {'id': 'mock-l10-guoquan-road', 'name': '国权路'},
    {'id': 'mock-l10-wujiaochang', 'name': '五角场'},
    {'id': 'mock-l10-jiangwan-stadium', 'name': '江湾体育场'},
    {'id': 'mock-l10-sanmen-road', 'name': '三门路'},
    {'id': 'mock-l10-yingao-east-road', 'name': '殷高东路'},
    {'id': 'mock-l10-xinjiangwan-city', 'name': '新江湾城'},
    {'id': 'mock-l10-guofan-road', 'name': '国帆路'},
    {'id': 'mock-l10-shuangjiang-road', 'name': '双江路'},
    {'id': 'mock-l10-gaoqiao-west', 'name': '高桥西'},
    {'id': 'mock-l10-gaoqiao', 'name': '高桥'},
    {'id': 'mock-l10-gangcheng-road', 'name': '港城路'},
    {'id': 'mock-l10-jilong-road', 'name': '基隆路'},
    {'id': 'mock-l10-hangzhong-road', 'name': '航中路'},
    {'id': 'mock-l10-ziteng-road', 'name': '紫藤路'},
    {'id': 'mock-l10-longbai-xincun', 'name': '龙柏新村'},
  ];

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
        _isArrivalLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _apiService.getCommonRoutes('default'),
        _apiService.getTravelAlerts(),
        _apiService.getMetroArrival(
          stopId: _selectedMetroStopId,
          stopName: _selectedMetroStopName,
          direction: _selectedMetroDirection,
        ),
      ]).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('请求超时');
        },
      );

      final routesResponse = results[0] as ApiResponse<List<dynamic>>;
      final alertsResponse = results[1] as ApiResponse<List<dynamic>>;
      final arrivalResponse = results[2] as ApiResponse<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _commonRoutes = routesResponse.success && routesResponse.data != null
              ? List<Map<String, dynamic>>.from(routesResponse.data!)
              : [];
          _travelAlerts = alertsResponse.success && alertsResponse.data != null
              ? List<Map<String, dynamic>>.from(alertsResponse.data!)
              : [];
          _metroArrival =
              arrivalResponse.success && arrivalResponse.data != null
                  ? Map<String, dynamic>.from(arrivalResponse.data!)
                  : null;
          _metroArrivalError =
              arrivalResponse.success ? null : arrivalResponse.error;
          _isLoading = false;
          _isArrivalLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isArrivalLoading = false;
          _commonRoutes = [];
          _travelAlerts = [];
        });
      }
    }
  }

  Future<void> _loadMetroArrival() async {
    setState(() {
      _isArrivalLoading = true;
      _metroArrivalError = null;
    });

    final response = await _apiService.getMetroArrival(
      stopId: _selectedMetroStopId,
      stopName: _selectedMetroStopName,
      direction: _selectedMetroDirection,
    );

    if (!mounted) return;
    setState(() {
      _metroArrival = response.success && response.data != null
          ? Map<String, dynamic>.from(response.data!)
          : null;
      _metroArrivalError = response.success ? null : response.error;
      _isArrivalLoading = false;
    });
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
              ShanghaiFullMetroMap(
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
              _buildMetroArrivalCard(colorScheme, textTheme),
              SizedBox(height: AppTheme.spacingM),
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
                        text: 'AI智能规划',
                        onPressed: () {
                          context.go(
                              '/ai-planning?start=${Uri.encodeComponent(_startController.text)}&end=${Uri.encodeComponent(_endController.text)}');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingM),
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
                                            final start =
                                                route['start'] as String? ?? '';
                                            final end =
                                                route['end'] as String? ?? '';
                                            context.go(
                                                '/route-plan?start=${Uri.encodeComponent(start)}&end=${Uri.encodeComponent(end)}');
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
                            (alert['title'] ?? '出行提醒').toString(),
                            style: textTheme.bodyLarge?.copyWith(
                              color: alertOnColor,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingS),
                          Text(
                            (alert['message'] ?? alert['content'] ?? '暂无详情')
                                .toString(),
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
                      context.push(item['route'] as String);
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

  Widget _buildMetroArrivalCard(ColorScheme colorScheme, TextTheme textTheme) {
    final arrival = _metroArrival;
    final hasData = arrival != null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusL,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMetroStopId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '站点',
                      border: OutlineInputBorder(),
                    ),
                    items: _line10Stops.map((stop) {
                      return DropdownMenuItem<String>(
                        value: stop['id'],
                        child: Text(stop['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = _line10Stops
                          .firstWhere((stop) => stop['id'] == value);
                      setState(() {
                        _selectedMetroStopId = selected['id']!;
                        _selectedMetroStopName = selected['name']!;
                      });
                      _loadMetroArrival();
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacingS),
                SizedBox(
                  width: 132,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMetroDirection,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '方向',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('往基隆路')),
                      DropdownMenuItem(value: 1, child: Text('反方向')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedMetroDirection = value;
                      });
                      _loadMetroArrival();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AppTheme.borderRadiusM,
                  ),
                  child:
                      Icon(Icons.train, color: colorScheme.onPrimaryContainer),
                ),
                SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '10号线 $_selectedMetroStopName到站',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      if (_isArrivalLoading)
                        Text(
                          '正在连接模拟到站 API...',
                          style: textTheme.bodyMedium,
                        )
                      else if (hasData) ...[
                        Text(
                          '最近一班 ${arrival['currentArriveMinutes'] ?? '?'} 分钟后，下一班 ${arrival['nextArriveMinutes'] ?? '?'} 分钟后',
                          style: textTheme.bodyMedium,
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Text(
                          '列车位置：${arrival['trainLocation'] ?? '未知'} → ${arrival['trainNextStop'] ?? '未知'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else
                        Text(
                          _metroArrivalError ?? '模拟到站 API 未连接',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新到站时间',
                  onPressed: _loadMetroArrival,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
