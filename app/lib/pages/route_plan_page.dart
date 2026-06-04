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
  final String? initialStartEntranceId;
  final String? initialStartEntranceName;
  final String? initialEndExitId;
  final String? initialEndExitName;

  const RoutePlanPage({
    super.key,
    this.initialStartStation,
    this.initialEndStation,
    this.initialStartEntranceId,
    this.initialStartEntranceName,
    this.initialEndExitId,
    this.initialEndExitName,
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
  bool _isGuideLoading = false;
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

      final response = await _apiService.getRoutePlans(
        start,
        end,
        preferences: preferencesJson,
        startEntranceId: widget.initialStartEntranceId,
        startEntranceName: widget.initialStartEntranceName,
        endExitId: widget.initialEndExitId,
        endExitName: widget.initialEndExitName,
      );

      if (response.success && response.data != null) {
        final routeData = response.data!;
        if (routeData.isNotEmpty) {
          setState(() {
            _routePlans = routeData
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          });
        } else {
          setState(() {
            _error = '后端没有返回可行路线，请检查站点名称或后端线路数据。';
          });
        }
      } else {
        setState(() {
          _error = response.error ?? '后端规划失败';
        });
      }
    } catch (e) {
      setState(() {
        _routePlans = [];
        _error = '后端规划接口异常：$e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                    label: Text(_isLoading ? '规划中...' : '后端智能规划'),
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
                  if (_textOf(plan['aiAdvice']).isNotEmpty ||
                      _textOf(plan['description']).isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacingS),
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: AppTheme.borderRadiusM,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              _textOf(plan['aiAdvice']).isNotEmpty
                                  ? _textOf(plan['aiAdvice'])
                                  : _textOf(plan['description']),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      if (plan['score'] != null)
                        _buildScoreBadge(context, plan['score']),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isGuideLoading
                            ? null
                            : () => _showIndoorGuideSheet(plan),
                        icon: _isGuideLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.transfer_within_a_station),
                        label: const Text('站内指引'),
                      ),
                    ],
                  ),
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

  Widget _buildScoreBadge(BuildContext context, dynamic rawScore) {
    final colorScheme = Theme.of(context).colorScheme;
    final score = rawScore is num
        ? rawScore.round()
        : int.tryParse(rawScore?.toString() ?? '') ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: AppTheme.borderRadiusM,
      ),
      child: Text(
        '匹配度 $score',
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Future<void> _showIndoorGuideSheet(Map<String, dynamic> plan) async {
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    if (start.isEmpty || end.isEmpty) return;

    setState(() => _isGuideLoading = true);
    final response = await _apiService.getIndoorGuide(
      from: start,
      to: end,
      startEntranceId: widget.initialStartEntranceId,
      startEntranceName: widget.initialStartEntranceName,
      endExitId: widget.initialEndExitId,
      endExitName: widget.initialEndExitName,
    );
    if (!mounted) return;
    setState(() => _isGuideLoading = false);

    if (!response.success || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error ?? '站内指引加载失败')),
      );
      return;
    }

    final rawSteps = response.data!['steps'];
    final steps = rawSteps is List
        ? rawSteps
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无站内指引步骤')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacingM,
                  10,
                  AppTheme.spacingM,
                  AppTheme.spacingL,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  Text(
                    '站内一点通',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    '${_textOf(plan['title']).isEmpty ? '已选路线' : _textOf(plan['title'])} · ${start} → $end',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  ...List.generate(
                    steps.length,
                    (index) => _IndoorGuideStepTile(
                      index: index,
                      total: steps.length,
                      step: steps[index],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _textOf(dynamic value) => value?.toString().trim() ?? '';

  List<Widget> _buildSegments(BuildContext context, Map<String, dynamic> plan) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final segments = (plan['segments'] as List?) ?? [];
    final widgets = <Widget>[];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final segmentColor = _colorFromHex(segment['color']?.toString()) ??
          (segment['type'] == 'walk'
              ? colorScheme.tertiary
              : colorScheme.primary);
      final stops = segment['stops'];
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
                color: segmentColor.withOpacity(0.16),
                borderRadius: AppTheme.borderRadiusS,
              ),
              child: Icon(
                segment['type'] == 'walk'
                    ? Icons.directions_walk
                    : Icons.subway,
                size: 16,
                color: segmentColor,
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
                  if (stops is num && stops > 0)
                    Text(
                      '共${stops.toInt()}站',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
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

Color? _colorFromHex(String? value) {
  if (value == null || value.isEmpty) return null;
  final cleaned = value.replaceFirst('#', '');
  if (cleaned.length != 6) return null;
  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}

class _IndoorGuideStepTile extends StatelessWidget {
  final int index;
  final int total;
  final Map<String, dynamic> step;

  const _IndoorGuideStepTile({
    required this.index,
    required this.total,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final title = step['title']?.toString() ?? '站内步骤';
    final detail = step['detail']?.toString() ?? '';
    final imageTitle = step['imageTitle']?.toString() ?? '';
    final imageSubtitle = step['imageSubtitle']?.toString() ?? '';
    final minutes = step['minutes'];
    final lineColor =
        _colorFromHex(step['lineColor']?.toString()) ?? colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppTheme.borderRadiusL,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: lineColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (index + 1 < total)
                Container(
                  width: 2,
                  height: 44,
                  margin: const EdgeInsets.only(top: 8),
                  color: colorScheme.outlineVariant,
                ),
            ],
          ),
          SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (minutes != null)
                      Text(
                        '${minutes}分钟',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (detail.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingS),
                  Text(
                    detail,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (imageTitle.isNotEmpty || imageSubtitle.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingS),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: AppTheme.borderRadiusM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageTitle.isNotEmpty)
                          Text(
                            imageTitle,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (imageSubtitle.isNotEmpty)
                          Text(
                            imageSubtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
