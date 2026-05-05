import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class TransferTimePage extends StatefulWidget {
  const TransferTimePage({super.key});

  @override
  State<TransferTimePage> createState() => _TransferTimePageState();
}

class _TransferTimePageState extends State<TransferTimePage> {
  final NetworkManager _networkManager = NetworkManager();

  int _remainingTime = 0;
  List<Map<String, dynamic>> _progressSteps = [];
  String _optimalRoute = '';
  String? _nextTrain;
  String? _estimatedArrival;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTransfer();
  }

  Future<void> _startTransfer() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response =
          await _networkManager.post('/transfer-time/start', data: {
        'from': 'current',
        'to': 'target',
        'remainingTime': 300,
      });

      final data = response.data;

      setState(() {
        _remainingTime = data['remainingTime'] ?? 300;
        _progressSteps = data['progressSteps'] != null
            ? List<Map<String, dynamic>>.from(data['progressSteps'])
            : [];
        _optimalRoute = data['optimalRoute'] ?? '';
        if (data['alternativePlan'] != null) {
          _nextTrain = data['alternativePlan']['nextTrain'];
          _estimatedArrival = data['alternativePlan']['estimatedArrival'];
        }
        _isLoading = false;
      });

      _startCountdown();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _remainingTime = 300;
        _progressSteps = [
          {'title': '换乘步行', 'progress': 60, 'time': '3分钟'},
          {'title': '站台候车', 'progress': 30, 'time': '1分钟'},
          {'title': '上车', 'progress': 10, 'time': '30秒'},
        ];
        _optimalRoute = '从当前位置 → 换乘通道 → 2号线站台';
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_remainingTime > 0 && mounted) {
        setState(() {
          _remainingTime--;
        });
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formatTime(int seconds) {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    bool isEmergency = _remainingTime < 120;

    return Scaffold(
      appBar: const TopNavBar(title: '换乘时间管理'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          children: [
                            Text('加载失败: $_error',
                                style: TextStyle(color: AppTheme.errorColor)),
                            TextButton(
                              onPressed: _startTransfer,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.borderRadiusL,
                    ),
                    color: isEmergency
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : null,
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
                              color: isEmergency
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      step['title'] ?? '',
                                      style: AppTheme.bodyText1,
                                    ),
                                    Text(
                                      step['time'] ?? '',
                                      style: AppTheme.bodyText2,
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppTheme.spacingS),
                                LinearProgressIndicator(
                                  value: (step['progress'] ?? 0) / 100,
                                  backgroundColor: AppTheme.textTertiary,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                                  _optimalRoute.isNotEmpty
                                      ? _optimalRoute
                                      : '路线规划中...',
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
                            '下一班次: ${_nextTrain ?? '暂无'}',
                            style: AppTheme.bodyText1,
                          ),
                          Text(
                            '预计到达时间: ${_estimatedArrival ?? '暂无'}',
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
