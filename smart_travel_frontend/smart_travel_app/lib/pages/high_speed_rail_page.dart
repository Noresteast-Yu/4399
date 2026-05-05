import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class HighSpeedRailPage extends StatefulWidget {
  const HighSpeedRailPage({super.key});

  @override
  State<HighSpeedRailPage> createState() => _HighSpeedRailPageState();
}

class _HighSpeedRailPageState extends State<HighSpeedRailPage> {
  final TextEditingController _trainNumberController = TextEditingController();
  final NetworkManager _networkManager = NetworkManager();

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
      });

      final response =
          await _networkManager.get('/high-speed-rail/train/$trainNumber');
      final data = response.data;

      setState(() {
        _trainInfo = Map<String, dynamic>.from(data);
        _carriages = _trainInfo!['carriages'] != null
            ? List<Map<String, dynamic>>.from(_trainInfo!['carriages'])
            : [];
        _isLoading = false;
      });

      _loadGuideInfo(trainNumber);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGuideInfo(String trainNumber) async {
    try {
      final response =
          await _networkManager.post('/high-speed-rail/guide', data: {
        'trainNumber': trainNumber,
        'destination': _trainInfo?['end'] ?? '',
        'currentCarriage': '10',
      });
      setState(() {
        _guideInfo = Map<String, dynamic>.from(response.data);
      });
    } catch (e) {
      // 引导信息加载失败不影响主体显示
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                  _trainInfo!['start'] ?? '',
                                  style: AppTheme.bodyText1,
                                ),
                                Text(
                                  _trainInfo!['departure'] ?? '',
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
                                  _trainInfo!['end'] ?? '',
                                  style: AppTheme.bodyText1,
                                ),
                                Text(
                                  _trainInfo!['arrival'] ?? '',
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
                            '停靠站台: ${_trainInfo!['platform'] ?? ''}',
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
                            '开门方向: ${_trainInfo!['doorDirection'] ?? ''}',
                            style: AppTheme.bodyText1,
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
                                      '推荐车厢: ${_guideInfo!['recommendedCarriage'] ?? ''}',
                                      style: AppTheme.bodyText1,
                                    ),
                                    Text(
                                      _guideInfo!['reason'] ?? '',
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
              const Text(
                '车厢信息',
                style: AppTheme.headline3,
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
                              style: AppTheme.bodyText1,
                            ),
                            Text(
                              carriage['type'] ?? '',
                              style: AppTheme.bodyText2,
                            ),
                          ],
                        ),
                        Text(
                          carriage['distance'] ?? '',
                          style: AppTheme.bodyText2,
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
