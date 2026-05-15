import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/services/api_service.dart';

class HighSpeedRailPage extends StatefulWidget {
  const HighSpeedRailPage({super.key});

  @override
  State<HighSpeedRailPage> createState() => _HighSpeedRailPageState();
}

class _HighSpeedRailPageState extends State<HighSpeedRailPage> {
  final TextEditingController _trainNumberController = TextEditingController();
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _trainInfo;
  List<Map<String, dynamic>> _carriages = [];
  Map<String, dynamic>? _guideInfo;
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _trainNumberController.dispose();
    super.dispose();
  }

  Future<void> _searchTrain() async {
    final trainNumber = _trainNumberController.text.trim();
    if (trainNumber.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _hasSearched = true;
        _guideInfo = null;
      });

      final response = await _apiService.getTrainInfo(trainNumber);

      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _trainInfo = data;
          _carriages = data['carriages'] != null
              ? List<Map<String, dynamic>>.from(data['carriages'])
              : [];
          _isLoading = false;
        });

        _loadGuideInfo(trainNumber);
      } else {
        setState(() {
          _error = response.error ?? '未找到车次信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '网络异常: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGuideInfo(String trainNumber) async {
    try {
      final response = await _apiService.getTrainGuide(
        trainNumber: trainNumber,
        destination: _trainInfo?['end'] ?? '',
        currentCarriage: '10',
      );
      if (response.success && response.data != null) {
        setState(() {
          _guideInfo = response.data!;
        });
      }
    } catch (e) {
      // 引导信息加载失败不影响主体显示
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(title: '高铁精准下车引导'),
      body: SingleChildScrollView(
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
                    CommonInput(
                      hintText: '请输入车次号',
                      controller: _trainNumberController,
                      prefixIcon: const Icon(Icons.train),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    CommonButton(
                      text: '查询',
                      onPressed: _searchTrain,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacingL),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      Text('加载失败: $_error'),
                      TextButton(
                        onPressed: _searchTrain,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_hasSearched && _trainInfo == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingM),
                  child: Text('未找到车次信息'),
                ),
              )
            else if (_trainInfo != null) ...[
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
                        _trainInfo!['number'] ?? '',
                        style: textTheme.headlineMedium,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _trainInfo!['start'] ?? '',
                                  style: textTheme.bodyLarge,
                                ),
                                Text(
                                  _trainInfo!['departure'] ?? '',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward,
                              color: colorScheme.onSurfaceVariant),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _trainInfo!['end'] ?? '',
                                  style: textTheme.bodyLarge,
                                ),
                                Text(
                                  _trainInfo!['arrival'] ?? '',
                                  style: textTheme.bodyMedium,
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
                          Icon(Icons.location_on,
                              color: colorScheme.onSurfaceVariant),
                          SizedBox(width: AppTheme.spacingS),
                          Text(
                            '停靠站台: ${_trainInfo!['platform'] ?? ''}',
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          Icon(Icons.directions,
                              color: colorScheme.onSurfaceVariant),
                          SizedBox(width: AppTheme.spacingS),
                          Text(
                            '开门方向: ${_trainInfo!['doorDirection'] ?? ''}',
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              if (_guideInfo != null)
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
                          style: textTheme.titleLarge,
                        ),
                        SizedBox(height: AppTheme.spacingM),
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: AppTheme.borderRadiusM,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color: colorScheme.onPrimaryContainer,
                                size: 30,
                              ),
                              SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '推荐车厢: ${_guideInfo!['recommendedCarriage'] ?? ''}',
                                      style: textTheme.bodyLarge,
                                    ),
                                    Text(
                                      _guideInfo!['reason'] ?? '',
                                      style: textTheme.bodyMedium,
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
              Text(
                '车厢信息',
                style: textTheme.titleLarge,
              ),
              SizedBox(height: AppTheme.spacingM),
              ...(_carriages.map((carriage) {
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
                              '车厢: ${carriage['number'] ?? ''}',
                              style: textTheme.bodyLarge,
                            ),
                            Text(
                              carriage['type'] ?? '',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        Text(
                          carriage['distance'] ?? '',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList()),
            ],
          ],
        ),
      ),
    );
  }
}
