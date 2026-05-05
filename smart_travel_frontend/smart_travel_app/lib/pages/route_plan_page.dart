import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class RoutePlanPage extends StatefulWidget {
  const RoutePlanPage({super.key});

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  final NetworkManager _networkManager = NetworkManager();

  List<Map<String, dynamic>> _routePlans = [];
  int _selectedPlanIndex = 0;
  bool _isLoading = true;
  String? _error;
  String _start = '北京南站';
  String _end = '中关村';

  @override
  void initState() {
    super.initState();
    _loadRoutePlans();
  }

  Future<void> _loadRoutePlans() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _networkManager.post('/route-plan/plan', data: {
        'start': _start,
        'end': _end,
      });

      final data = response.data;
      setState(() {
        _routePlans = data is List ? List<Map<String, dynamic>>.from(data) : [];
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
    return Scaffold(
      appBar: const TopNavBar(title: '智能出行规划'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败: $_error'),
                      TextButton(
                        onPressed: _loadRoutePlans,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _routePlans.isEmpty
                  ? const Center(child: Text('暂无路线数据'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.borderRadiusL,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingM),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          borderRadius: AppTheme.borderRadiusM,
                                        ),
                                        child: const Icon(Icons.location_on,
                                            color: Colors.white),
                                      ),
                                      SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: Text(
                                          _start,
                                          style: AppTheme.bodyText1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  const Divider(),
                                  SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor,
                                          borderRadius: AppTheme.borderRadiusM,
                                        ),
                                        child: const Icon(Icons.location_off,
                                            color: Colors.white),
                                      ),
                                      SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: Text(
                                          _end,
                                          style: AppTheme.bodyText1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingL),
                          Row(
                            children: _routePlans.asMap().entries.map((entry) {
                              int index = entry.key;
                              var plan = entry.value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedPlanIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingM,
                                      vertical: AppTheme.spacingS,
                                    ),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingXS,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedPlanIndex == index
                                          ? AppTheme.primaryColor
                                          : AppTheme.surface,
                                      borderRadius: AppTheme.borderRadiusM,
                                      border: Border.all(
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    child: Text(
                                      plan['title'] ?? '',
                                      style: TextStyle(
                                        color: _selectedPlanIndex == index
                                            ? AppTheme.surface
                                            : AppTheme.primaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: AppTheme.spacingL),
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.borderRadiusL,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(AppTheme.spacingM),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _routePlans[_selectedPlanIndex]['title'] ??
                                        '',
                                    style: AppTheme.headline3,
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '用时: ${_routePlans[_selectedPlanIndex]['time'] ?? ''}',
                                        style: AppTheme.bodyText2,
                                      ),
                                      Text(
                                        '换乘: ${_routePlans[_selectedPlanIndex]['transfers'] ?? ''}',
                                        style: AppTheme.bodyText2,
                                      ),
                                      Text(
                                        '距离: ${_routePlans[_selectedPlanIndex]['distance'] ?? ''}',
                                        style: AppTheme.bodyText2,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  const Divider(),
                                  SizedBox(height: AppTheme.spacingM),
                                  ...((_routePlans[_selectedPlanIndex]
                                              ['segments'] as List?) ??
                                          [])
                                      .map((segment) {
                                    return Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              segment['type'] == 'walk'
                                                  ? Icons.directions_walk
                                                  : Icons.subway,
                                              color: AppTheme.primaryColor,
                                            ),
                                            SizedBox(width: AppTheme.spacingM),
                                            Expanded(
                                              child: Text(
                                                segment['type'] == 'walk'
                                                    ? '步行'
                                                    : '地铁',
                                                style: AppTheme.bodyText1,
                                              ),
                                            ),
                                            Text(
                                              '${segment['distance'] ?? ''} · ${segment['time'] ?? ''}',
                                              style: AppTheme.bodyText2,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: AppTheme.spacingM),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
