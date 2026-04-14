import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class RoutePlanPage extends StatefulWidget {
  const RoutePlanPage({super.key});

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  // 路线方案
  final List<Map<String, dynamic>> _routePlans = [
    {
      'id': '1',
      'title': '最快路线',
      'time': '30分钟',
      'transfers': '1次换乘',
      'distance': '12公里',
      'segments': [
        {'type': 'walk', 'distance': '500米', 'time': '7分钟'},
        {'type': 'subway', 'distance': '10公里', 'time': '20分钟'},
        {'type': 'walk', 'distance': '500米', 'time': '3分钟'},
      ],
    },
    {
      'id': '2',
      'title': '最少换乘',
      'time': '35分钟',
      'transfers': '0次换乘',
      'distance': '15公里',
      'segments': [
        {'type': 'walk', 'distance': '300米', 'time': '5分钟'},
        {'type': 'subway', 'distance': '14公里', 'time': '28分钟'},
        {'type': 'walk', 'distance': '200米', 'time': '2分钟'},
      ],
    },
    {
      'id': '3',
      'title': '最省体力',
      'time': '40分钟',
      'transfers': '1次换乘',
      'distance': '13公里',
      'segments': [
        {'type': 'walk', 'distance': '200米', 'time': '3分钟'},
        {'type': 'subway', 'distance': '12公里', 'time': '25分钟'},
        {'type': 'walk', 'distance': '100米', 'time': '2分钟'},
      ],
    },
  ];
  
  int _selectedPlanIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '智能出行规划'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 起终点设置
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
                          child: const Icon(Icons.location_on, color: Colors.white),
                        ),
                        SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            '北京南站',
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
                          child: const Icon(Icons.location_off, color: Colors.white),
                        ),
                        SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            '中关村',
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
            
            // 路线方案选择
            Row(
              children: _routePlans.map((plan) {
                int index = _routePlans.indexOf(plan);
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
                        plan['title'],
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
            
            // 路线详情
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
                      _routePlans[_selectedPlanIndex]['title'],
                      style: AppTheme.headline3,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '用时: ${_routePlans[_selectedPlanIndex]['time']}',
                          style: AppTheme.bodyText2,
                        ),
                        Text(
                          '换乘: ${_routePlans[_selectedPlanIndex]['transfers']}',
                          style: AppTheme.bodyText2,
                        ),
                        Text(
                          '距离: ${_routePlans[_selectedPlanIndex]['distance']}',
                          style: AppTheme.bodyText2,
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    const Divider(),
                    SizedBox(height: AppTheme.spacingM),
                    // 分段详情
                    ..._routePlans[_selectedPlanIndex]['segments'].map((segment) {
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
                                  segment['type'] == 'walk' ? '步行' : '地铁',
                                  style: AppTheme.bodyText1,
                                ),
                              ),
                              Text(
                                '${segment['distance']} · ${segment['time']}',
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
