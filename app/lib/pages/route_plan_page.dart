import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/providers/user_preferences_provider.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/services/api_service.dart';

class RoutePlanPage extends StatefulWidget {
  final String? initialStartStation;
  final String? initialEndStation;

  const RoutePlanPage({
    super.key,
    this.initialStartStation,
    this.initialEndStation,
  });

  @override
  State<RoutePlanPage> createState() => _RoutePlanPageState();
}

class _RoutePlanPageState extends State<RoutePlanPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  List<Map<String, dynamic>> _routePlans = [];
  int _selectedPlanIndex = 0;
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStartStation != null) {
      _startController.text = widget.initialStartStation!;
    }
    if (widget.initialEndStation != null) {
      _endController.text = widget.initialEndStation!;
    }
    if (widget.initialStartStation != null &&
        widget.initialEndStation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _planRoute();
      });
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _planRoute() async {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入起点和终点'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final start = _startController.text.trim();
    final end = _endController.text.trim();

    // #region debug-point 5
    print('[DEBUG] _planRoute called: start=$start, end=$end');
    // #endregion

    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _hasSearched = true;
        _routePlans = [];
        _selectedPlanIndex = 0;
      });

      // Get user preferences from provider
      final preferences =
          Provider.of<UserPreferencesProvider>(context, listen: false);
      final preferencesJson = preferences.toJson();

      // #region debug-point 6
      print('[DEBUG] User preferences: $preferencesJson');
      print('[DEBUG] Calling ApiService.getRoutePlans with preferences...');
      // #endregion
      final response = await _apiService.getRoutePlans(
        start,
        end,
        preferences: preferencesJson,
      );
      // #region debug-point 7
      print(
          '[DEBUG] ApiService response: success=${response.success}, data=${response.data}, error=${response.error}');
      // #endregion

      if (response.success && response.data != null) {
        final routeData = response.data!;
        if (routeData.isNotEmpty) {
          setState(() {
            _routePlans =
                routeData.map((e) => e as Map<String, dynamic>).toList();
          });
          // #region debug-point 8
          print('[DEBUG] Routes loaded from API: ${_routePlans.length} routes');
          // #endregion
        } else {
          setState(() {
            _routePlans = [];
          });
          // #region debug-point 9
          print('[DEBUG] API returned empty');
          // #endregion
        }
      } else {
        setState(() {
          _routePlans = [];
          _error = response.error ?? '规划失败';
        });
        // #region debug-point 10
        print('[DEBUG] API call failed. Error: ${response.error}');
        // #endregion
      }
    } catch (e) {
      setState(() {
        _routePlans = [];
        _error = '网络异常';
      });
      // #region debug-point 11
      print('[DEBUG] Exception caught: $e');
      // #endregion
    } finally {
      setState(() {
        _isLoading = false;
      });
      // #region debug-point 12
      print('[DEBUG] Loading finished, _isLoading=false');
      // #endregion
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const TopNavBar(title: '路线规划'),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacingM),
            color: colorScheme.surfaceContainer,
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: InputDecoration(
                    labelText: '起点站',
                    hintText: '请输入起点站',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingM),
                TextField(
                  controller: _endController,
                  decoration: InputDecoration(
                    labelText: '终点站',
                    hintText: '请输入终点站',
                    prefixIcon: const Icon(Icons.location_off),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _planRoute,
                    icon: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isLoading ? '规划中...' : 'AI 智能规划'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding:
                          EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadiusM,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasSearched && !_isLoading)
            Expanded(
              child: Column(
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      color: colorScheme.tertiaryContainer,
                      child: Row(
                        children: [
                          Icon(Icons.offline_bolt,
                              color: colorScheme.onTertiaryContainer),
                          SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: _routePlans.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.route,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: AppTheme.spacingM),
                                Text(
                                  '暂无路线数据',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildRouteList(context),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildRouteList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.spacingM),
      itemCount: _routePlans.length,
      itemBuilder: (context, index) {
        final plan = _routePlans[index];
        final isSelected = _selectedPlanIndex == index;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPlanIndex = index;
            });
          },
          child: Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacingM),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerLow,
              borderRadius: AppTheme.borderRadiusL,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (index == 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: AppTheme.borderRadiusS,
                                ),
                                child: Text(
                                  '推荐',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            Text(
                              plan['title'] ?? '路线 ${index + 1}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.access_time,
                            plan['time'] ?? '--',
                          ),
                          SizedBox(width: 8),
                          _buildInfoChip(
                            context,
                            Icons.swap_horiz,
                            '${plan['transfers'] ?? 0}次',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  const Divider(height: 1),
                  SizedBox(height: AppTheme.spacingM),
                  ..._buildSegments(context, plan),
                  if (plan['description'] != null) ...[
                    SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: AppTheme.borderRadiusM,
                      ),
                      child: Text(
                        plan['description'],
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSegments(BuildContext context, Map<String, dynamic> plan) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segments = (plan['segments'] as List?) ?? [];
    final widgets = <Widget>[];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      if (i > 0) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(left: 28),
            child: Container(
              height: 20,
              width: 2,
              color: colorScheme.outlineVariant,
            ),
          ),
        );
      }
      widgets.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: segment['type'] == 'walk'
                    ? colorScheme.tertiaryContainer
                    : colorScheme.primaryContainer,
                borderRadius: AppTheme.borderRadiusS,
              ),
              child: Icon(
                segment['type'] == 'walk'
                    ? Icons.directions_walk
                    : Icons.subway,
                size: 16,
                color: segment['type'] == 'walk'
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment['line'] ??
                        (segment['type'] == 'walk' ? '步行' : '地铁'),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (segment['description'] != null)
                    Text(
                      segment['description'],
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  segment['time'] ?? '',
                  style: textTheme.bodySmall,
                ),
                if (segment['distance'] != null)
                  Text(
                    segment['distance'],
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return widgets;
  }
}
