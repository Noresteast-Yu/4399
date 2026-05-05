import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';

class TransferTimePage extends StatefulWidget {
  const TransferTimePage({super.key});

  @override
  State<TransferTimePage> createState() => _TransferTimePageState();
}

class _TransferTimePageState extends State<TransferTimePage> {
  // 倒计时
  int _remainingTime = 300; // 5分钟
  
  // 行程进度
  final List<Map<String, dynamic>> _progressSteps = [
    {'title': '换乘步行', 'progress': 60, 'time': '3分钟'},
    {'title': '站台候车', 'progress': 30, 'time': '1分钟'},
    {'title': '上车', 'progress': 10, 'time': '30秒'},
  ];

  @override
  void initState() {
    super.initState();
    // 启动倒计时
    startCountdown();
  }
  
  void startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 格式化时间
    String formatTime(int seconds) {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    
    bool isEmergency = _remainingTime < 120; // 2分钟以下为紧急

    return Scaffold(
      appBar: const TopNavBar(title: '换乘时间管理'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 实时换乘倒计时
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.borderRadiusL,
              ),
              color: isEmergency ? AppTheme.errorColor.withOpacity(0.1) : null,
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  children: [
                    Text(
                      '剩余换乘时间',
                      style: AppTheme.headline3,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      formatTime(_remainingTime),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? AppTheme.errorColor : AppTheme.primaryColor,
                      ),
                    ),
                    if (isEmergency)
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacingM),
                        child: Text(
                          '时间紧张，请快速换乘！',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 行程进度
            const Text(
              '行程进度',
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
                  children: _progressSteps.map((step) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                step['title'],
                                style: AppTheme.bodyText1,
                              ),
                              Text(
                                step['time'],
                                style: AppTheme.bodyText2,
                              ),
                            ],
                          ),
                          SizedBox(height: AppTheme.spacingS),
                          LinearProgressIndicator(
                            value: step['progress'] / 100,
                            backgroundColor: AppTheme.textTertiary,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.spacingL),
            
            // 最优路线
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
                      '最优换乘路线',
                      style: AppTheme.headline3,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        const Icon(Icons.navigation),
                        SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            '从当前位置 → 换乘通道 → 2号线站台',
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
            
            // 兜底方案
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
                      '备选方案',
                      style: AppTheme.headline3,
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      '下一班次: 10:30',
                      style: AppTheme.bodyText1,
                    ),
                    Text(
                      '预计到达时间: 11:45',
                      style: AppTheme.bodyText2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
