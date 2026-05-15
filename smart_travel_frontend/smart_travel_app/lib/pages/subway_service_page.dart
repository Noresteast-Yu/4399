import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/services/api_service.dart';

class SubwayServicePage extends StatefulWidget {
  const SubwayServicePage({super.key});

  @override
  State<SubwayServicePage> createState() => _SubwayServicePageState();
}

class _SubwayServicePageState extends State<SubwayServicePage> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _stationInfo;
  List<Map<String, dynamic>> _facilities = [];
  List<Map<String, dynamic>> _crowdLevels = [];
  bool _isLoading = true;
  String? _error;
  String _stationId = 'tongji_university';

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

      final response = await _apiService.getStationInfo(_stationId);

      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _stationInfo = data;
          _facilities = data['facilities'] != null
              ? List<Map<String, dynamic>>.from(data['facilities'])
              : [];
          _crowdLevels = data['crowdLevels'] != null
              ? List<Map<String, dynamic>>.from(data['crowdLevels'])
              : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? '加载失败';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                                    style: textTheme.headlineMedium,
                                  ),
                                  SizedBox(height: AppTheme.spacingM),
                                  Row(
                                    children: [
                                      Icon(Icons.train,
                                          color: colorScheme.onSurfaceVariant),
                                      SizedBox(width: AppTheme.spacingS),
                                      Expanded(
                                        child: Text(
                                          (_stationInfo!['lines'] as List?)
                                                  ?.join('、') ??
                                              '',
                                          style: textTheme.bodyLarge,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingS),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          color: colorScheme.onSurfaceVariant),
                                      SizedBox(width: AppTheme.spacingS),
                                      Text(
                                        '首班车: ${_stationInfo!['firstTrain'] ?? ''}, 末班车: ${_stationInfo!['lastTrain'] ?? ''}',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingS),
                                  Row(
                                    children: [
                                      Icon(Icons.info,
                                          color: colorScheme.onSurfaceVariant),
                                      SizedBox(width: AppTheme.spacingS),
                                      Text(
                                        '发车间隔: ${_stationInfo!['interval'] ?? ''}',
                                        style: textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingL),
                          Text(
                            '站内设施',
                            style: textTheme.titleLarge,
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
                                        color: colorScheme.primary,
                                      ),
                                      SizedBox(width: AppTheme.spacingM),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              facility['name'] ?? '',
                                              style: textTheme.bodyLarge,
                                            ),
                                            Text(
                                              facility['location'] ?? '',
                                              style: textTheme.bodyMedium,
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
                          Text(
                            '客流拥挤度',
                            style: textTheme.titleLarge,
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
                                  final crowdLevel = level['level'] ?? '';
                                  final levelColor = _getCrowdLevelColor(
                                      colorScheme, crowdLevel);
                                  final levelContainerColor =
                                      _getCrowdLevelContainerColor(
                                          colorScheme, crowdLevel);

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        bottom: AppTheme.spacingM),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          level['time'] ?? '',
                                          style: textTheme.bodyLarge,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacingM,
                                            vertical: AppTheme.spacingS,
                                          ),
                                          decoration: BoxDecoration(
                                            color: levelContainerColor,
                                            borderRadius:
                                                AppTheme.borderRadiusS,
                                          ),
                                          child: Text(
                                            crowdLevel,
                                            style: TextStyle(
                                              color: levelColor,
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

  Color _getCrowdLevelColor(ColorScheme colorScheme, String level) {
    switch (level) {
      case '拥挤':
        return colorScheme.error;
      case '适中':
        return colorScheme.secondary;
      case '空旷':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurface;
    }
  }

  Color _getCrowdLevelContainerColor(ColorScheme colorScheme, String level) {
    switch (level) {
      case '拥挤':
        return colorScheme.errorContainer;
      case '适中':
        return colorScheme.secondaryContainer;
      case '空旷':
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.surfaceVariant;
    }
  }
}
