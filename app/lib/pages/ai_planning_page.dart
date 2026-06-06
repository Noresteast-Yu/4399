import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/services/api_service.dart';
import 'package:smart_travel_app/services/navigation_memory.dart';

class AIPlanningPage extends StatefulWidget {
  final String? initialStartStation;
  final String? initialEndStation;
  final String? initialStartEntranceId;
  final String? initialStartEntranceName;
  final String? initialEndExitId;
  final String? initialEndExitName;

  const AIPlanningPage({
    super.key,
    this.initialStartStation,
    this.initialEndStation,
    this.initialStartEntranceId,
    this.initialStartEntranceName,
    this.initialEndExitId,
    this.initialEndExitName,
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

  final ApiService _apiService = ApiService();

  late final String _startStation;
  late final String _endStation;
  late final String _startEntranceId;
  late final String _endExitId;
  late final String _startEntranceName;
  late final String _endExitName;
  late final bool _hasRoute;
  int _stepIndex = 0;
  _ProgressStatus? _stepStatus;
  _RouteSummary? _summary;
  List<_NavStep> _guideSteps = [];
  Timer? _statusRefreshTimer;
  int _statusRequestId = 0;

  @override
  void initState() {
    super.initState();
    _startStation = widget.initialStartStation?.trim() ?? '';
    _endStation = widget.initialEndStation?.trim() ?? '';
    _startEntranceId = widget.initialStartEntranceId?.trim() ?? '';
    _endExitId = widget.initialEndExitId?.trim() ?? '';
    _startEntranceName = widget.initialStartEntranceName?.trim() ?? '';
    _endExitName = widget.initialEndExitName?.trim() ?? '';
    _hasRoute = _startStation.isNotEmpty && _endStation.isNotEmpty;
    if (_hasRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIndoorGuide());
    }
  }

  Future<void> _refreshStepStatus() async {
    if (!_hasRoute || _guideSteps.isEmpty) return;
    final requestedStepIndex = _stepIndex;
    final requestId = ++_statusRequestId;
    final response = await _apiService.getIndoorGuideProgress(
      from: _startStation,
      to: _endStation,
      stepIndex: requestedStepIndex,
      startEntranceId: _startEntranceId,
      startEntranceName: _startEntranceName,
      endExitId: _endExitId,
      endExitName: _endExitName,
    );
    if (!mounted ||
        requestedStepIndex != _stepIndex ||
        requestId != _statusRequestId) {
      return;
    }
    final rawStatus = response.data?['status'];
    setState(() {
      _stepStatus = response.success && rawStatus is Map
          ? _ProgressStatus.fromJson(Map<String, dynamic>.from(rawStatus))
          : null;
    });
  }

  Future<void> _loadIndoorGuide() async {
    final response = await _apiService.getIndoorGuide(
      from: _startStation,
      to: _endStation,
      startEntranceId: _startEntranceId,
      startEntranceName: _startEntranceName,
      endExitId: _endExitId,
      endExitName: _endExitName,
    );
    if (!mounted || !response.success) {
      return;
    }

    final rawSteps = response.data?['steps'];
    if (rawSteps is! List) {
      return;
    }

    final steps = rawSteps
        .whereType<Map>()
        .map((item) => _NavStep.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    if (steps.isEmpty) {
      return;
    }

    final rawSummary = response.data?['summary'];

    setState(() {
      if (rawSummary is Map) {
        _summary =
            _RouteSummary.fromJson(Map<String, dynamic>.from(rawSummary));
      }
      _guideSteps = steps;
      if (_stepIndex >= _guideSteps.length) {
        _stepIndex = _guideSteps.length - 1;
      }
    });
    await _refreshStepStatus();
    _startStatusRefreshTimer();
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer?.cancel();
    _statusRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshStepStatus(),
    );
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRoute) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Stack(
          children: [
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                children: [
                  _GuideTopBar(onBack: _returnToRoutePlan),
                  const SizedBox(height: 10),
                  _ProgressPanel(
                    status: _stepStatus ?? _fallbackStatusFor(step, steps),
                  ),
                  if (_hasAccessSelection) ...[
                    const SizedBox(height: 12),
                    _AccessTaskPanel(
                      startStation: _startStation,
                      startEntrance: _startEntranceName,
                      endStation: _endStation,
                      endExit: _endExitName,
                    ),
                  ],
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
                      setState(() {
                        _stepIndex--;
                        _stepStatus = null;
                      });
                      _refreshStepStatus();
                    },
                    onNext: () {
                      if (_stepIndex < steps.length - 1) {
                        setState(() {
                          _stepIndex++;
                          _stepStatus = null;
                        });
                        _refreshStepStatus();
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

  _ProgressStatus _fallbackStatusFor(_NavStep step, List<_NavStep> steps) {
    return _ProgressStatus(
      leadText: step.stage == _StepStage.ride
          ? '${step.remainingStops}站'
          : '${step.minutes}分钟',
      title: step.title,
      subtitle: step.detail,
      progress: ((_stepIndex + 1) / steps.length).clamp(0.05, 1),
      color: step.lineColor,
      icon: step.icon,
      isFallback: true,
    );
  }

  bool get _hasAccessSelection =>
      _startEntranceName.isNotEmpty || _endExitName.isNotEmpty;

  void _returnToRoutePlan() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(NavigationMemory.routePlanLocation ?? '/route-plan');
  }
}

class _GuideTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _GuideTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回路线方案',
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '站内一点通',
            style: TextStyle(
              color: _AIPlanningPageState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
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

class _AccessTaskPanel extends StatelessWidget {
  final String startStation;
  final String startEntrance;
  final String endStation;
  final String endExit;

  const _AccessTaskPanel({
    required this.startStation,
    required this.startEntrance,
    required this.endStation,
    required this.endExit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _softPanel(),
      child: Row(
        children: [
          _AccessNode(
            icon: Icons.login_rounded,
            title: startEntrance.isEmpty ? '待补进站口' : startEntrance,
            subtitle: startStation,
            color: _AIPlanningPageState._line10,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: _AIPlanningPageState._muted,
              size: 20,
            ),
          ),
          _AccessNode(
            icon: Icons.logout_rounded,
            title: endExit.isEmpty ? '待补出站口' : endExit,
            subtitle: endStation,
            color: _AIPlanningPageState._green,
          ),
        ],
      ),
    );
  }
}

class _AccessNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AccessNode({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AIPlanningPageState._muted,
                    fontSize: 11,
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
                    if (status.isFallback) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8CC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '兜底数据',
                          style: TextStyle(
                            color: Color(0xFF9A4D00),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
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
          if (step.photoUrl.isNotEmpty)
            Image.network(
              step.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return CustomPaint(
                    painter: _ScenePainter(color: step.lineColor));
              },
            )
          else
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
                  child: Text(
                    step.photoUrl.isEmpty ? '实景占位' : '实景照片',
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
  final String photoKey;
  final String photoUrl;

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
    this.photoKey = '',
    this.photoUrl = '',
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
      photoKey: json['photoKey']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
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
    case 'timer':
      return Icons.timer_rounded;
    case 'transfer':
      return Icons.transfer_within_a_station_rounded;
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
  final bool isFallback;

  const _ProgressStatus({
    required this.leadText,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
    required this.icon,
    required this.isFallback,
  });

  factory _ProgressStatus.fromJson(Map<String, dynamic> json) {
    return _ProgressStatus(
      leadText: json['leadText']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      progress: _doubleFromJson(json['progress'], 0),
      color: _colorFromJson(
        json['color']?.toString(),
        _AIPlanningPageState._line10,
      ),
      icon: _iconFromJson(json['iconKey']?.toString()),
      isFallback: json['isFallback'] == true,
    );
  }
}

double _doubleFromJson(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}
