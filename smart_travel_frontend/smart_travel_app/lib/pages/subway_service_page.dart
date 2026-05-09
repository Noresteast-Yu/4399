import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/utils/network_manager.dart';

class SubwayServicePage extends StatefulWidget {
  const SubwayServicePage({super.key});

  @override
  State<SubwayServicePage> createState() => _SubwayServicePageState();
}

class _SubwayServicePageState extends State<SubwayServicePage> {
  final NetworkManager _networkManager = NetworkManager();

  Map<String, dynamic>? _stationInfo;
  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _crowdLevels = [];
  bool _isLoading = true;
  String? _error;
  String _stationId = 'beijing_south';

  @override
  void initState() {
    super.initState();
    _loadStationInfo();
  }

  Future<void> _loadStationInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response =
          await _networkManager.get('/subway-service/station/$_stationId');
      final data = response.data;

      setState(() {
        _stationInfo = Map<String, dynamic>.from(data);
        _facilities = _stationInfo!['facilities'] != null
            ? List<Map<String, dynamic>>.from(_stationInfo!['facilities'])
            : [];
        _crowdLevels = _stationInfo!['crowdLevels'] != null
            ? List<Map<String, dynamic>>.from(_stationInfo!['crowdLevels'])
            : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getFacilityIcon(String? iconName) {
    switch (iconName) {
      case 'wc':
        return Icons.wc;
      case 'elevator':
        return Icons.elevator;
      case 'escalator':
        return Icons.escalator;
      case 'store':
        return Icons.store;
      case 'accessibility':
        return Icons.accessibility;
      default:
        return Icons.help;
    }
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case '拥挤':
        return AppTheme.errorColor;
      case '适中':
         return AppTheme.secondaryColor;
       case '空旷':
         return AppTheme.textTertiary;
      default:
        return AppTheme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '地铁人性化服务'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('加载失败: $_error'),
                      TextButton(
                        onPressed: _loadStationInfo,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _stationInfo == null
                  ? const Center(child: Text('暂无站点数据'))
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _stationInfo!['name'] ?? '未知站点',
                                    style: AppTheme.headline2,
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    children: [
                                      const Icon(Icons.train),
                                      SizedBox(width: AppTheme.spacingS),
                                      Expanded(
                                        child: Text(
                                          (_stationInfo!['lines'] as List?)
                                                  ?.join('、') ??
                                              '',
                                          style: AppTheme.bodyText1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingS),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time),
                                      SizedBox(width: AppTheme.spacingS),
                                      Text(
                                        '首班车: ${_stationInfo!['firstTrain'] ?? ''}, 末班车: ${_stationInfo!['lastTrain'] ?? ''}',
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
                                        '发车间隔: ${_stationInfo!['interval'] ?? ''}',
                                        style: AppTheme.bodyText2,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingL),
                          const Text(
                            '站内设施',
                            style: AppTheme.headline3,
                          ),
                          SizedBox(height: AppTheme.spacingM),
                          GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
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
                                        _getFacilityIcon(facility['icon']),
                                        color: AppTheme.primaryColor,
                                      ),
                                      SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              facility['name'] ?? '',
                                              style: AppTheme.bodyText1,
                                            ),
                                            Text(
                                              facility['location'] ?? '',
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
                                    padding: EdgeInsets.only(
                                        bottom: AppTheme.spacingM),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          level['time'] ?? '',
                                          style: AppTheme.bodyText1,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingM,
                                            vertical: AppTheme.spacingS,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _getLevelColor(level['level'])
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                AppTheme.borderRadiusS,
                                          ),
                                          child: Text(
                                            level['level'] ?? '',
                                            style: TextStyle(
                                              color: _getLevelColor(
                                                  level['level']),
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
