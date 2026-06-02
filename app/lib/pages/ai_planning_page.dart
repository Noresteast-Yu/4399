import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';

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
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _line2 = Color(0xFF73C92D);
  static const Color _ink = Color(0xFF0D1C2F);
  static const Color _muted = Color(0xFF667085);
  static const Color _surface = Color(0xFFEAF1FF);
  static const Color _green = Color(0xFF008C4A);
  static const Color _orange = Color(0xFFE57900);

  final ApiService _apiService = ApiService();

  late final String _startStation;
  late final String _endStation;
  late final bool _hasRoute;
  int _stepIndex = 0;
  Map<String, dynamic>? _arrival;
  Map<String, dynamic>? _arrivalQuery;
  _RouteSummary? _summary;
  List<_NavStep> _guideSteps = [];

  @override
  void initState() {
    super.initState();
    _startStation = widget.initialStartStation?.trim() ?? '';
    _endStation = widget.initialEndStation?.trim() ?? '';
    _hasRoute = _startStation.isNotEmpty && _endStation.isNotEmpty;
    if (_hasRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIndoorGuide());
    }
  }

  Future<void> _refreshArrival() async {
    final query = _currentArrivalQuery();
    final stopId = query['stopId']?.toString() ?? '';
    final stopName = query['stopName']?.toString() ?? '';
    if (stopId.isEmpty && stopName.isEmpty) {
      if (!mounted) return;
      setState(() {
        _arrival = null;
      });
      return;
    }

    final response = await _apiService.getMetroArrival(
      stopId: stopId,
      stopName: stopName.isNotEmpty ? stopName : _startStation,
      lineId: query['lineId']?.toString() ?? '',
      lineName: query['lineName']?.toString() ?? '',
      direction: _intFromJson(query['direction'], 0),
      cityCode: query['cityCode']?.toString() ?? '',
    );
    if (!mounted) return;
    setState(() {
      _arrival = response.success ? response.data : null;
    });
  }

  Map<String, dynamic> _currentArrivalQuery() {
    if (_guideSteps.isNotEmpty && _stepIndex < _guideSteps.length) {
      final query = _guideSteps[_stepIndex].arrivalQuery;
      if (query.isNotEmpty) return query;
    }
    return _arrivalQuery ?? const <String, dynamic>{};
  }

  Future<void> _loadIndoorGuide() async {
    final response = await _apiService.getIndoorGuide(
      from: _startStation,
      to: _endStation,
    );
    if (!mounted || !response.success) {
      await _refreshArrival();
      return;
    }

    final rawSteps = response.data?['steps'];
    if (rawSteps is! List) {
      await _refreshArrival();
      return;
    }

    final steps = rawSteps
        .whereType<Map>()
        .map((item) => _NavStep.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (steps.isEmpty) {
      await _refreshArrival();
      return;
    }

    final rawArrivalQuery = response.data?['arrivalQuery'];
    final rawSummary = response.data?['summary'];

    setState(() {
      if (rawArrivalQuery is Map) {
        _arrivalQuery = Map<String, dynamic>.from(rawArrivalQuery);
      }
      if (rawSummary is Map) {
        _summary =
            _RouteSummary.fromJson(Map<String, dynamic>.from(rawSummary));
      }
      _guideSteps = steps;
      if (_stepIndex >= _guideSteps.length) {
        _stepIndex = _guideSteps.length - 1;
      }
    });
    await _refreshArrival();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRoute) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
            Positioned.fill(child: _GuideBackground()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: _WaitingRouteState(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      );
    }

    if (_guideSteps.isEmpty) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
            Positioned.fill(child: _GuideBackground()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: _LoadingGuideState(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      );
    }

    final steps = _guideSteps;
    final step = steps[_stepIndex];
    final showSummary = _summary != null && _stepIndex == 0;

    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _GuideBackground()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  _ProgressPanel(status: _statusFor(step, steps)),
                  if (showSummary) ...[
                    const SizedBox(height: 12),
                    _RouteSummaryPanel(summary: _summary!),
                  ],
                  const SizedBox(height: 12),
                  _InstructionPanel(step: step),
                  const SizedBox(height: 12),
                  Expanded(child: _ScenePanel(step: step)),
                  const SizedBox(height: 12),
                  _StepControls(
                    canGoBack: _stepIndex > 0,
                    isLast: _stepIndex == steps.length - 1,
                    onBack: () {
                      setState(() => _stepIndex--);
                      _refreshArrival();
                    },
                    onNext: () {
                      if (_stepIndex < steps.length - 1) {
                        setState(() => _stepIndex++);
                        _refreshArrival();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  _ProgressStatus _statusFor(_NavStep step, List<_NavStep> steps) {
    if (step.stage == _StepStage.ride) {
      final total = step.totalStops <= 0 ? 1 : step.totalStops;
      final done = (total - step.remainingStops).clamp(0, total);
      return _ProgressStatus(
        leadText: '${step.remainingStops}站',
        title: '乘车中',
        subtitle: '到${step.targetStation}下车，提前靠近${step.doorHint}',
        progress: done / total,
        color: step.lineColor,
        icon: Icons.train_rounded,
      );
    }

    if (step.stage == _StepStage.transfer ||
        step.stage == _StepStage.transferWait) {
      final catchPlan = _catchPlanForStages(
        steps,
        _stepIndex,
        {_StepStage.transfer, _StepStage.transferWait},
        safetyBufferMinutes: 1,
      );
      return _ProgressStatus(
        leadText: '${catchPlan.trainMinutes}分钟',
        title: catchPlan.usesNextTrain
            ? '${step.lineName}赶不上，改按下一班'
            : '预计可赶上${step.lineName}当前班',
        subtitle:
            '换乘还要约${catchPlan.remainingWalkMinutes}分钟，已推进${catchPlan.completedWalkMinutes}分钟，预计余量${catchPlan.safeBufferMinutes}分钟',
        progress: catchPlan.progress,
        color: catchPlan.statusColor(step.lineColor),
        icon: Icons.transfer_within_a_station_rounded,
      );
    }

    if (step.stage == _StepStage.exit) {
      return _ProgressStatus(
        leadText: '到达',
        title: '按出口指引出站',
        subtitle: '推荐走${step.targetStation}',
        progress: 1,
        color: _green,
        icon: Icons.output_rounded,
      );
    }

    final catchPlan = _catchPlanForStages(
      steps,
      _stepIndex,
      {_StepStage.entry, _StepStage.platform},
      safetyBufferMinutes: 1,
    );

    return _ProgressStatus(
      leadText: '${catchPlan.trainMinutes}分钟',
      title: catchPlan.usesNextTrain
          ? '${step.lineName}赶不上，改按下一班'
          : '${step.lineName}当前班来得及',
      subtitle:
          '到站台还要约${catchPlan.remainingWalkMinutes}分钟，已推进${catchPlan.completedWalkMinutes}分钟，预计余量${catchPlan.safeBufferMinutes}分钟',
      progress: catchPlan.progress,
      color: catchPlan.statusColor(step.lineColor),
      icon: Icons.timer_rounded,
    );
  }

  _CatchPlan _catchPlanForStages(
    List<_NavStep> steps,
    int index,
    Set<_StepStage> stages, {
    required int safetyBufferMinutes,
  }) {
    final currentTrain = _currentTrainMinutes();
    final nextTrain = _nextTrainMinutes(currentTrain);
    final remainingWalk = _remainingMinutesForStages(steps, index, stages);
    final completedWalk = _completedMinutesForStages(steps, index, stages);
    final requiredMinutes = remainingWalk + safetyBufferMinutes;
    final usesNextTrain = currentTrain < requiredMinutes;
    final selectedTrain = usesNextTrain ? nextTrain : currentTrain;
    final buffer = selectedTrain - remainingWalk;
    final progress = selectedTrain <= 0
        ? 0.0
        : ((selectedTrain - remainingWalk) / selectedTrain).clamp(0.0, 0.95);

    return _CatchPlan(
      trainMinutes: selectedTrain,
      remainingWalkMinutes: remainingWalk,
      completedWalkMinutes: completedWalk,
      safeBufferMinutes: buffer < 0 ? 0 : buffer,
      usesNextTrain: usesNextTrain,
      progress: progress,
    );
  }

  int _remainingMinutesForStages(
    List<_NavStep> steps,
    int index,
    Set<_StepStage> stages,
  ) {
    var minutes = 0;
    for (var i = index; i < steps.length; i++) {
      if (!stages.contains(steps[i].stage)) {
        if (minutes > 0) break;
        continue;
      }
      minutes += steps[i].minutes;
    }
    return minutes <= 0 ? 1 : minutes;
  }

  int _completedMinutesForStages(
    List<_NavStep> steps,
    int index,
    Set<_StepStage> stages,
  ) {
    var minutes = 0;
    for (var i = 0; i < index; i++) {
      if (stages.contains(steps[i].stage)) {
        minutes += steps[i].minutes;
      }
    }
    return minutes;
  }

  int _currentTrainMinutes() {
    final value = _arrival?['currentArriveMinutes'];
    if (value is num) return value.round().clamp(1, 60);
    return int.tryParse(value?.toString() ?? '') ?? 5;
  }

  int _nextTrainMinutes(int currentTrainMinutes) {
    final value = _arrival?['nextArriveMinutes'] ??
        _arrival?['nextArrivalMinutes'] ??
        _arrival?['nextArriveSeconds'];
    if (value is num) {
      if (value > 60) return (value / 60).ceil().clamp(1, 90);
      return value.round().clamp(1, 90);
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      if (parsed > 60) return (parsed / 60).ceil().clamp(1, 90);
      return parsed.clamp(1, 90);
    }
    return (currentTrainMinutes + 7).clamp(2, 90);
  }
}

class _WaitingRouteState extends StatelessWidget {
  const _WaitingRouteState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _softPanel(),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Color(0xFFECE3F1),
                child: Icon(
                  Icons.route_rounded,
                  color: _AIPlanningPageState._line10,
                  size: 30,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '等待选择路线',
                      style: TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '请先在首页选择起点和终点，再开始站内指引。',
                      style: TextStyle(
                        color: _AIPlanningPageState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _LoadingGuideState extends StatelessWidget {
  const _LoadingGuideState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _softPanel(),
          child: const Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: _AIPlanningPageState._line10,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在生成站内指引',
                      style: TextStyle(
                        color: _AIPlanningPageState._ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '正在读取后端路线、换乘和到站信息。',
                      style: TextStyle(
                        color: _AIPlanningPageState._muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final _ProgressStatus status;

  const _ProgressPanel({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _softPanel(),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Text(
                  status.leadText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(status.icon, color: status.color, size: 20),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status.title,
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          color: _AIPlanningPageState._ink,
                          fontSize: 15,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: status.progress.clamp(0, 1),
                    minHeight: 9,
                    backgroundColor: const Color(0xFFE8E1EA),
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  status.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummaryPanel extends StatelessWidget {
  final _RouteSummary summary;

  const _RouteSummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _softPanel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${summary.durationMinutes}分钟',
                style: const TextStyle(
                  color: _AIPlanningPageState._line10,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final line in summary.lines)
                _LineChip(
                  label: line,
                  color: _lineColorForName(line),
                ),
              _InfoChip(
                icon: Icons.transfer_within_a_station_rounded,
                label: summary.transferText,
              ),
              _InfoChip(
                icon: Icons.door_sliding_rounded,
                label: summary.doorHint,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: _AIPlanningPageState._muted,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  summary.nextAction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LineChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _AIPlanningPageState._line10, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _AIPlanningPageState._ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  final _NavStep step;

  const _InstructionPanel({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _softPanel(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: step.lineColor.withOpacity(0.12),
            child: Icon(step.icon, color: step.lineColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    color: _AIPlanningPageState._ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step.detail,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePanel extends StatelessWidget {
  final _NavStep step;

  const _ScenePanel({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ScenePainter(color: step.lineColor)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.02),
                  Colors.black.withOpacity(0.42),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '实景占位',
                    style: TextStyle(
                      color: _AIPlanningPageState._muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.imageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  step.imageSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: _LineBadge(lineName: step.lineName, color: step.lineColor),
          ),
        ],
      ),
    );
  }
}

class _StepControls extends StatelessWidget {
  final bool canGoBack;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _StepControls({
    required this.canGoBack,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 106,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: canGoBack ? onBack : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('上一步'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AIPlanningPageState._line10,
              side: const BorderSide(color: Color(0xFFD8C2DA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 62,
            child: FilledButton.icon(
              onPressed: isLast ? null : onNext,
              icon: Icon(isLast
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded),
              label: Text(isLast ? '已到达' : '下一步'),
              style: FilledButton.styleFrom(
                backgroundColor: _AIPlanningPageState._line10,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE4DDE8),
                disabledForegroundColor: _AIPlanningPageState._muted,
                textStyle: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LineBadge extends StatelessWidget {
  final String lineName;
  final Color color;

  const _LineBadge({
    required this.lineName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        lineName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GuideBackground extends StatelessWidget {
  const _GuideBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF1FF), Color(0xFFF8F8FC)],
        ),
      ),
      child: CustomPaint(painter: _GuideBackgroundPainter()),
    );
  }
}

class _GuideBackgroundPainter extends CustomPainter {
  const _GuideBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFBFCBE2).withOpacity(0.26)
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScenePainter extends CustomPainter {
  final Color color;

  const _ScenePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()..color = const Color(0xFFDFE8F7);
    canvas.drawRect(Offset.zero & size, wall);

    final floor = Path()
      ..moveTo(0, size.height * 0.58)
      ..lineTo(size.width, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, Paint()..color = const Color(0xFFC6D2E4));

    final guideLine = Paint()
      ..color = color.withOpacity(0.75)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.76),
      Offset(size.width * 0.78, size.height * 0.45),
      guideLine,
    );

    final sign = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          size.width * 0.12, size.height * 0.12, size.width * 0.56, 42),
      const Radius.circular(8),
    );
    canvas.drawRRect(sign, Paint()..color = const Color(0xFF20304A));

    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width * 0.58, size.height * 0.12 + 21);
    canvas.drawLine(
        center.translate(-20, 0), center.translate(14, 0), arrowPaint);
    canvas.drawLine(
        center.translate(14, 0), center.translate(4, -9), arrowPaint);
    canvas.drawLine(
        center.translate(14, 0), center.translate(4, 9), arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

BoxDecoration _softPanel() {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.94),
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

enum _StepStage {
  entry,
  platform,
  ride,
  transfer,
  transferWait,
  exit,
}

class _NavStep {
  final _StepStage stage;
  final String lineName;
  final Color lineColor;
  final String title;
  final String detail;
  final String imageTitle;
  final String imageSubtitle;
  final int minutes;
  final IconData icon;
  final String targetStation;
  final int remainingStops;
  final int totalStops;
  final String doorHint;
  final Map<String, dynamic> arrivalQuery;

  const _NavStep({
    required this.stage,
    required this.lineName,
    required this.lineColor,
    required this.title,
    required this.detail,
    required this.imageTitle,
    required this.imageSubtitle,
    required this.minutes,
    required this.icon,
    this.targetStation = '',
    this.remainingStops = 0,
    this.totalStops = 0,
    this.arrivalQuery = const <String, dynamic>{},
    this.doorHint = '车门',
  });

  factory _NavStep.fromJson(Map<String, dynamic> json) {
    final rawArrivalQuery = json['arrivalQuery'];
    return _NavStep(
      stage: _stageFromJson(json['stage']),
      lineName: json['lineName']?.toString() ?? '10号线',
      lineColor: _colorFromJson(
        json['lineColor']?.toString(),
        _AIPlanningPageState._line10,
      ),
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      imageTitle: json['imageTitle']?.toString() ?? '',
      imageSubtitle: json['imageSubtitle']?.toString() ?? '',
      minutes: _intFromJson(json['minutes'], 1),
      icon: _iconFromJson(json['iconKey']?.toString()),
      targetStation: json['targetStation']?.toString() ?? '',
      remainingStops: _intFromJson(json['remainingStops'], 0),
      totalStops: _intFromJson(json['totalStops'], 0),
      arrivalQuery: rawArrivalQuery is Map
          ? Map<String, dynamic>.from(rawArrivalQuery)
          : const <String, dynamic>{},
      doorHint: json['doorHint']?.toString() ?? '车门',
    );
  }
}

class _RouteSummary {
  final String title;
  final int durationMinutes;
  final int transferCount;
  final String transferText;
  final String doorHint;
  final List<String> lines;
  final String nextAction;

  const _RouteSummary({
    required this.title,
    required this.durationMinutes,
    required this.transferCount,
    required this.transferText,
    required this.doorHint,
    required this.lines,
    required this.nextAction,
  });

  factory _RouteSummary.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return _RouteSummary(
      title: json['title']?.toString() ?? '',
      durationMinutes: _intFromJson(json['durationMinutes'], 0),
      transferCount: _intFromJson(json['transferCount'], 0),
      transferText: json['transferText']?.toString() ?? '无需换乘',
      doorHint: json['doorHint']?.toString() ?? '中部车门',
      lines: rawLines is List
          ? rawLines.map((item) => item.toString()).toList()
          : const <String>[],
      nextAction: json['nextAction']?.toString() ?? '',
    );
  }
}

_StepStage _stageFromJson(dynamic value) {
  switch (value?.toString()) {
    case 'entry':
      return _StepStage.entry;
    case 'platform':
      return _StepStage.platform;
    case 'ride':
      return _StepStage.ride;
    case 'transfer':
      return _StepStage.transfer;
    case 'transferWait':
      return _StepStage.transferWait;
    case 'exit':
      return _StepStage.exit;
    default:
      return _StepStage.entry;
  }
}

Color _colorFromJson(String? value, Color fallback) {
  final cleaned = value?.replaceAll('#', '').trim();
  if (cleaned == null || cleaned.length != 6) return fallback;
  final parsed = int.tryParse(cleaned, radix: 16);
  if (parsed == null) return fallback;
  return Color(0xFF000000 | parsed);
}

Color _lineColorForName(String lineName) {
  if (lineName.contains('2')) return _AIPlanningPageState._line2;
  if (lineName.contains('17')) return const Color(0xFFB58A00);
  if (lineName.contains('出站')) return _AIPlanningPageState._green;
  return _AIPlanningPageState._line10;
}

IconData _iconFromJson(String? value) {
  switch (value) {
    case 'login':
      return Icons.login_rounded;
    case 'escalator':
      return Icons.escalator_rounded;
    case 'turnRight':
      return Icons.turn_right_rounded;
    case 'turnLeft':
      return Icons.turn_left_rounded;
    case 'straight':
      return Icons.straight_rounded;
    case 'door':
      return Icons.door_sliding_rounded;
    case 'train':
      return Icons.train_rounded;
    case 'signpost':
      return Icons.signpost_rounded;
    case 'output':
      return Icons.output_rounded;
    default:
      return Icons.navigation_rounded;
  }
}

int _intFromJson(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class _ProgressStatus {
  final String leadText;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;
  final IconData icon;

  const _ProgressStatus({
    required this.leadText,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
  });
}

class _CatchPlan {
  final int trainMinutes;
  final int remainingWalkMinutes;
  final int completedWalkMinutes;
  final int safeBufferMinutes;
  final bool usesNextTrain;
  final double progress;

  const _CatchPlan({
    required this.trainMinutes,
    required this.remainingWalkMinutes,
    required this.completedWalkMinutes,
    required this.safeBufferMinutes,
    required this.usesNextTrain,
    required this.progress,
  });

  Color statusColor(Color lineColor) {
    if (usesNextTrain && safeBufferMinutes <= 0) {
      return const Color(0xFFBA1A1A);
    }
    if (usesNextTrain || safeBufferMinutes < 2) {
      return _AIPlanningPageState._orange;
    }
    return lineColor;
  }
}
