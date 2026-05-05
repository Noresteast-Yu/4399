import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class HighSpeedRailPage extends StatefulWidget {
  const HighSpeedRailPage({super.key});

  @override
  State<HighSpeedRailPage> createState() => _HighSpeedRailPageState();
}

class _HighSpeedRailPageState extends State<HighSpeedRailPage> {
  final TextEditingController _trainNumberController = TextEditingController();
  
  // 车次信息
  final Map<String, dynamic> _trainInfo = {
    'number': 'G102',
    'start': '北京南站',
    'end': '上海虹桥站',
    'departure': '08:00',
    'arrival': '13:00',
    'platform': '5',
    'doorDirection': '左侧',
    'stations': [
      '北京南站',
      '济南西站',
      '南京南站',
      '上海虹桥站',
    ],
  };
  
  // 车厢信息
  final List<Map<String, dynamic>> _carriages = [
    {'number': '1', 'type': '商务座', 'distance': '100米'},
    {'number': '2-3', 'type': '一等座', 'distance': '80米'},
    {'number': '4-15', 'type': '二等座', 'distance': '60米'},
    {'number': '16', 'type': '餐车', 'distance': '40米'},
    {'number': '17', 'type': '无障碍车厢', 'distance': '20米'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '高铁精准下车引导'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 车次查询
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    CommonInput(
                      hintText: '请输入车次号',
                      controller: _trainNumberController,
                      prefixIcon: const Icon(Icons.train),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    CommonButton(
                      text: '查询',
                      onPressed: () {
                        // 查询车次
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 车次信息
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
                      _trainInfo['number'],
                      style: AppTheme.headline2,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _trainInfo['start'],
                                style: AppTheme.bodyText1,
                              ),
                              Text(
                                _trainInfo['departure'],
                                style: AppTheme.bodyText2,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _trainInfo['end'],
                                style: AppTheme.bodyText1,
                              ),
                              Text(
                                _trainInfo['arrival'],
                                style: AppTheme.bodyText2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    const Divider(),
                    SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        const Icon(Icons.location_on),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '停靠站台: ${_trainInfo['platform']}',
                          style: AppTheme.bodyText1,
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        const Icon(Icons.directions),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '开门方向: ${_trainInfo['doorDirection']}',
                          style: AppTheme.bodyText1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 最优下车引导
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
                      '最优下车位置',
                      style: AppTheme.headline3,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: AppTheme.borderRadiusM,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                          SizedBox(width: AppTheme.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '推荐车厢: 17号',
                                  style: AppTheme.bodyText1,
                                ),
                                Text(
                                  '距离换乘口最近',
                                  style: AppTheme.bodyText2,
                                ),
                              ],
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
            
            // 车厢信息
            const Text(
              '车厢信息',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            Column(
              children: _carriages.map((carriage) {
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
                              '车厢: ${carriage['number']}',
                              style: AppTheme.bodyText1,
                            ),
                            Text(
                              carriage['type'],
                              style: AppTheme.bodyText2,
                            ),
                          ],
                        ),
                        Text(
                          carriage['distance'],
                          style: AppTheme.bodyText2,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
