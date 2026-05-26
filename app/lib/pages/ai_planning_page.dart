import 'package:flutter/material.dart';
import 'package:smart_travel_app/services/ai_planning_service.dart';
import 'package:smart_travel_app/theme/app_theme.dart';
import 'package:smart_travel_app/components/common/common_button.dart';
import 'package:smart_travel_app/components/common/common_input.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';

class AIPlanningPage extends StatefulWidget {
  final String? initialStartStation;
  final String? initialEndStation;

  const AIPlanningPage({
    super.key,
    this.initialStartStation,
    this.initialEndStation,
  });

  @override
  State<AIPlanningPage> createState() => _AIPlanningPageState();
}

class _AIPlanningPageState extends State<AIPlanningPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  bool _isLoading = false;
  AIPlanResult? _result;
  String? _error;
  bool _preferFastest = true;
  bool _preferLessTransfers = false;
  bool _avoidCrowded = false;

  @override
  void initState() {
    super.initState();
    _startController.text = widget.initialStartStation ?? '';
    _endController.text = widget.initialEndStation ?? '';
    final hasInitialStations = widget.initialStartStation != null &&
        widget.initialStartStation!.isNotEmpty &&
        widget.initialEndStation != null &&
        widget.initialEndStation!.isNotEmpty;
    if (hasInitialStations) {
      _isLoading = true;
      _startPlanning();
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _startPlanning() async {
    final start = _startController.text.trim();
    final end = _endController.text.trim();

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入起终点站名')),
      );
      return;
    }

    if (start == end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('起终点不能相同')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final result = await AIPlanningService.planRoute(
        startStation: start,
        endStation: end,
        preferences: {
          'preferFastest': _preferFastest,
          'preferLessTransfers': _preferLessTransfers,
          'avoidCrowded': _avoidCrowded,
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI智能规划'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'AI正在为你智能规划最优路线...',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在分析路线数据',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputSection(colorScheme, textTheme),
                    SizedBox(height: AppTheme.spacingM),
                    _buildPreferencesSection(colorScheme, textTheme),
                    SizedBox(height: AppTheme.spacingM),
                    CommonButton(
                      text: '开始AI智能规划',
                      onPressed: _startPlanning,
                    ),
                    if (_error != null) ...[
                      SizedBox(height: AppTheme.spacingM),
                      _buildErrorSection(colorScheme, textTheme),
                    ],
                    if (_result != null) ...[
                      SizedBox(height: AppTheme.spacingL),
                      _buildResultSection(colorScheme, textTheme),
                    ],
                    SizedBox(height: AppTheme.spacingXL),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusL,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
                SizedBox(width: 8),
                Text(
                  'AI智能路线规划',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingM),
            CommonInput(
              controller: _startController,
              hintText: '请输入起点站名',
              prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
            ),
            SizedBox(height: AppTheme.spacingM),
            CommonInput(
              controller: _endController,
              hintText: '请输入终点站名',
              prefixIcon: Icon(Icons.flag, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(
      ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusL,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '出行偏好',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('最快路线'),
                  selected: _preferFastest,
                  onSelected: (v) => setState(() {
                    _preferFastest = v;
                    if (v) _preferLessTransfers = false;
                  }),
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.primary,
                ),
                FilterChip(
                  label: const Text('少换乘'),
                  selected: _preferLessTransfers,
                  onSelected: (v) => setState(() {
                    _preferLessTransfers = v;
                    if (v) _preferFastest = false;
                  }),
                  selectedColor: colorScheme.secondaryContainer,
                  checkmarkColor: colorScheme.secondary,
                ),
                FilterChip(
                  label: const Text('避开拥挤'),
                  selected: _avoidCrowded,
                  onSelected: (v) => setState(() => _avoidCrowded = v),
                  selectedColor: colorScheme.tertiaryContainer,
                  checkmarkColor: colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusM,
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            SizedBox(width: AppTheme.spacingS),
            Expanded(
              child: Text(
                '规划失败: $_error',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(ColorScheme colorScheme, TextTheme textTheme) {
    final result = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'AI规划结果',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'AI推荐',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacingM),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusL,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: AppTheme.spacingS),
                Text(
                  result.summary,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.access_time,
                      label: '${result.totalTimeMinutes}分钟',
                      color: colorScheme.primary,
                      backgroundColor: colorScheme.primaryContainer,
                    ),
                    SizedBox(width: 12),
                    _buildInfoChip(
                      icon: Icons.transfer_within_a_station,
                      label: result.transfers == 0
                          ? '无需换乘'
                          : '换乘${result.transfers}次',
                      color: colorScheme.tertiary,
                      backgroundColor: colorScheme.tertiaryContainer,
                    ),
                  ],
                ),
                if (result.steps.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingM),
                  const Divider(),
                  SizedBox(height: AppTheme.spacingM),
                  ...result.steps.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final step = entry.value;
                    final isTransfer = step.type == 'transfer';
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isTransfer
                                  ? Colors.orange.shade100
                                  : colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isTransfer
                                      ? Colors.orange.shade800
                                      : colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTransfer ? '换乘' : step.line,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isTransfer
                                        ? Colors.orange.shade800
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '${step.timeMinutes}分钟'
                                  '${step.stops != null ? ' · ${step.stops}站' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                if (result.tips.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingM),
                  const Divider(),
                  SizedBox(height: AppTheme.spacingM),
                  Text(
                    '出行建议',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingS),
                  ...result.tips.map((tip) => Padding(
                        padding: EdgeInsets.only(bottom: AppTheme.spacingXS),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: colorScheme.tertiary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
