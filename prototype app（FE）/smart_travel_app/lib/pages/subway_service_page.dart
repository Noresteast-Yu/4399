import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class SubwayServicePage extends StatefulWidget {
  const SubwayServicePage({super.key});

  @override
  State<SubwayServicePage> createState() => _SubwayServicePageState();
}

class _SubwayServicePageState extends State<SubwayServicePage> {
  // 站点设施
  final List<Map<String, dynamic>> _facilities = [
    {'name': '卫生间', 'icon': Icons.wc, 'location': '站厅层东侧'},
    {'name': '电梯', 'icon': Icons.elevator, 'location': '站台中部'},
    {'name': '扶梯', 'icon': Icons.escalator, 'location': '站厅层南北两侧'},
    {'name': '便利店', 'icon': Icons.store, 'location': '站厅层西侧'},
    {'name': '无障碍设施', 'icon': Icons.accessibility, 'location': '全站覆盖'},
  ];
  
  // 客流拥挤度
  final List<Map<String, dynamic>> _crowdLevels = [
    {'time': '07:00-09:00', 'level': '拥挤', 'color': AppTheme.errorColor},
    {'time': '09:00-17:00', 'level': '适中', 'color': AppTheme.warningColor},
    {'time': '17:00-19:00', 'level': '拥挤', 'color': AppTheme.errorColor},
    {'time': '19:00-23:00', 'level': '宽松', 'color': AppTheme.secondaryColor},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '地铁人性化服务'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 站点信息
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
                      '北京南站',
                      style: AppTheme.headline2,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        const Icon(Icons.train),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '地铁4号线、14号线',
                          style: AppTheme.bodyText1,
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        const Icon(Icons.access_time),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '首班车: 05:30, 末班车: 23:30',
                          style: AppTheme.bodyText2,
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Row(
                      children: [
                        const Icon(Icons.info),
                        SizedBox(width: AppTheme.spacingS),
                        Text(
                          '发车间隔: 2-5分钟',
                          style: AppTheme.bodyText2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 站点设施
            const Text(
              '站内设施',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _facilities.length,
              itemBuilder: (context, index) {
                final facility = _facilities[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.borderRadiusM,
                  ),
                  margin: EdgeInsets.only(
                    right: AppTheme.spacingS,
                    bottom: AppTheme.spacingS,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingM),
                    child: Row(
                      children: [
                        Icon(
                          facility['icon'],
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                facility['name'],
                                style: AppTheme.bodyText1,
                              ),
                              Text(
                                facility['location'],
                                style: AppTheme.bodyText2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 客流拥挤度
            const Text(
              '客流拥挤度',
              style: AppTheme.headline3,
            ),
            SizedBox(height: AppTheme.spacingM),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: _crowdLevels.map((level) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            level['time'],
                            style: AppTheme.bodyText1,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingM,
                              vertical: AppTheme.spacingS,
                            ),
                            decoration: BoxDecoration(
                              color: level['color'].withOpacity(0.1),
                              borderRadius: AppTheme.borderRadiusS,
                            ),
                            child: Text(
                              level['level'],
                              style: TextStyle(
                                color: level['color'],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}
