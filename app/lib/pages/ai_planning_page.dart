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
    final query = _arrivalQuery ?? const <String, dynamic>{};
    final response = await _apiService.getMetroArrival(
      stopId: query['stopId']?.toString() ?? _stopIdFor(_startStation),
      stopName: query['stopName']?.toString() ?? _startStation,
      lineId: query['lineId']?.toString() ?? 'mock-line-10',
      lineName: query['lineName']?.toString() ?? '10号线',
      direction: _intFromJson(query['direction'], 0),
      cityCode: query['cityCode']?.toString() ?? 'mock-shanghai',
    );
    if (!mounted) return;
    setState(() {
      _arrival = response.success ? response.data : null;
    });
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

    setState(() {
      if (rawArrivalQuery is Map) {
        _arrivalQuery = Map<String, dynamic>.from(rawArrivalQuery);
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

    final steps = _guideSteps.isNotEmpty ? _guideSteps : _buildSteps();
    final step = steps[_stepIndex];

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
                  const SizedBox(height: 12),
                  _InstructionPanel(step: step),
                  const SizedBox(height: 12),
                  Expanded(child: _ScenePanel(step: step)),
                  const SizedBox(height: 12),
                  _StepControls(
                    canGoBack: _stepIndex > 0,
                    isLast: _stepIndex == steps.length - 1,
                    onBack: () => setState(() => _stepIndex--),
                    onNext: () {
                      if (_stepIndex < steps.length - 1) {
                        setState(() => _stepIndex++);
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
      final countdown = _transferTrainMinutes();
      final walked =
          _completedMinutesBefore(steps, _stepIndex, _StepStage.transfer);
      return _ProgressStatus(
        leadText: '$countdown分钟',
        title: '预计可赶上${step.lineName}下一班',
        subtitle: '换乘步行约${_transferWalkMinutes()}分钟，已推进$walked分钟',
        progress: (walked / countdown.clamp(1, 60)).clamp(0.0, 0.95),
        color: step.lineColor,
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

    final trainMinutes = _currentTrainMinutes();
    final walked = _completedEntryMinutes(steps, _stepIndex);
    final toPlatform = _entryWalkMinutes(steps);
    final buffer = trainMinutes - toPlatform;
    final safeText = buffer >= 2
        ? '来得及，按指引走'
        : buffer >= 0
            ? '时间紧，建议加快'
            : '赶不上这班，等下一班';

    return _ProgressStatus(
      leadText: '$trainMinutes分钟',
      title: '10号线下一班',
      subtitle: '$safeText，到站台约$toPlatform分钟，预计余量${buffer < 0 ? 0 : buffer}分钟',
      progress: (walked / trainMinutes.clamp(1, 60)).clamp(0.0, 0.95),
      color: buffer >= 2
          ? _green
          : buffer >= 0
              ? _orange
              : const Color(0xFFBA1A1A),
      icon: Icons.timer_rounded,
    );
  }

  List<_NavStep> _buildSteps() {
    final entrance = _entranceFor(_startStation);
    final transferStation = _transferStationFor(_startStation, _endStation);
    final exit = _exitFor(_endStation);

    return [
      _NavStep(
        stage: _StepStage.entry,
        lineName: '10号线',
        lineColor: _line10,
        title: '从$entrance进入',
        detail: '面向地铁入口向前走，优先选择人少的一侧进站。',
        imageTitle: '$entrance 实景确认',
        imageSubtitle: '看见紫色10号线标识后继续直行',
        minutes: 1,
        icon: Icons.login_rounded,
      ),
      const _NavStep(
        stage: _StepStage.entry,
        lineName: '10号线',
        lineColor: _line10,
        title: '下扶梯到站厅',
        detail: '扶梯到底后保持直行，不要先跟随出站人流转弯。',
        imageTitle: '站厅扶梯口',
        imageSubtitle: '确认前方有10号线站台指示牌',
        minutes: 1,
        icon: Icons.escalator_rounded,
      ),
      const _NavStep(
        stage: _StepStage.entry,
        lineName: '10号线',
        lineColor: _line10,
        title: '刷码后右转',
        detail: '过闸机后右转，跟随“10号线 往基隆路方向”标识。',
        imageTitle: '闸机后右转通道',
        imageSubtitle: '右侧通道前往10号线站台',
        minutes: 1,
        icon: Icons.turn_right_rounded,
      ),
      _NavStep(
        stage: _StepStage.platform,
        lineName: '10号线',
        lineColor: _line10,
        title: '站到4车2门候车',
        detail: '这个位置下车后更靠近$transferStation换乘通道。',
        imageTitle: '10号线站台中部',
        imageSubtitle: '寻找4车2门地贴或屏蔽门编号',
        minutes: 1,
        icon: Icons.door_sliding_rounded,
        doorHint: '4车2门',
      ),
      _NavStep(
        stage: _StepStage.ride,
        lineName: '10号线',
        lineColor: _line10,
        title: '上车后坐到$transferStation',
        detail: '还有3站下车，到站前提前向4车2门车门附近移动。',
        imageTitle: '车厢内提示',
        imageSubtitle: '注意报站，到$transferStation准备下车',
        minutes: 6,
        icon: Icons.train_rounded,
        targetStation: transferStation,
        remainingStops: 3,
        totalStops: 3,
        doorHint: '4车2门',
      ),
      _NavStep(
        stage: _StepStage.transfer,
        lineName: '2号线',
        lineColor: _line2,
        title: '下车后向车头方向走',
        detail: '不要先上出站扶梯，沿站台向前走到换乘扶梯。',
        imageTitle: '$transferStation 10号线站台',
        imageSubtitle: '车头方向可见换乘扶梯',
        minutes: 1,
        icon: Icons.straight_rounded,
      ),
      _NavStep(
        stage: _StepStage.transfer,
        lineName: '2号线',
        lineColor: _line2,
        title: '上扶梯后左转',
        detail: '扶梯到站厅后左转，进入2号线换乘通道。',
        imageTitle: '换乘扶梯出口',
        imageSubtitle: '左侧为2号线换乘通道',
        minutes: 1,
        icon: Icons.turn_left_rounded,
      ),
      const _NavStep(
        stage: _StepStage.transferWait,
        lineName: '2号线',
        lineColor: _line2,
        title: '到2号线站台候车',
        detail: '确认方向为“徐泾东/静安寺方向”，站到中部车门附近。',
        imageTitle: '2号线候车区',
        imageSubtitle: '确认绿色2号线方向牌',
        minutes: 1,
        icon: Icons.signpost_rounded,
      ),
      _NavStep(
        stage: _StepStage.ride,
        lineName: '2号线',
        lineColor: _line2,
        title: '乘2号线到$_endStation',
        detail: '还有2站下车，到站前提前靠近车门。',
        imageTitle: '2号线车厢内',
        imageSubtitle: '听到$_endStation报站后准备下车',
        minutes: 4,
        icon: Icons.train_rounded,
        targetStation: _endStation,
        remainingStops: 2,
        totalStops: 2,
        doorHint: '中部车门',
      ),
      _NavStep(
        stage: _StepStage.exit,
        lineName: '出站',
        lineColor: _green,
        title: '从$exit出站',
        detail: '跟随出口编号走，出闸后靠右侧通道出站。',
        imageTitle: '$exit 出口实景',
        imageSubtitle: '确认出口编号后再上行',
        minutes: 3,
        icon: Icons.output_rounded,
        targetStation: exit,
      ),
    ];
  }

  int _currentTrainMinutes() {
    final value = _arrival?['currentArriveMinutes'];
    if (value is num) return value.round().clamp(1, 60);
    return int.tryParse(value?.toString() ?? '') ?? 5;
  }

  int _transferTrainMinutes() {
    final firstTrain = _currentTrainMinutes();
    return (firstTrain + 3).clamp(4, 14);
  }

  int _completedEntryMinutes(List<_NavStep> steps, int index) {
    var minutes = 0;
    for (var i = 0; i < index; i++) {
      if (steps[i].stage == _StepStage.entry ||
          steps[i].stage == _StepStage.platform) {
        minutes += steps[i].minutes;
      }
    }
    return minutes;
  }

  int _completedMinutesBefore(
    List<_NavStep> steps,
    int index,
    _StepStage stage,
  ) {
    var minutes = 0;
    for (var i = 0; i < index; i++) {
      if (steps[i].stage == stage) minutes += steps[i].minutes;
    }
    return minutes;
  }

  int _entryWalkMinutes(List<_NavStep> steps) {
    return steps
        .where((step) =>
            step.stage == _StepStage.entry || step.stage == _StepStage.platform)
        .fold<int>(0, (total, step) => total + step.minutes);
  }

  int _transferWalkMinutes() => 3;

  String _stopIdFor(String station) {
    if (station.contains('五角场')) return 'mock-l10-wujiaochang';
    if (station.contains('同济')) return 'mock-l10-tongji-university';
    if (station.contains('陕西南路')) return 'mock-l10-shaanxi-south-road';
    if (station.contains('虹桥')) return 'mock-l10-hongqiao-railway-station';
    if (station.contains('南京东路')) return 'mock-l10-nanjing-east-road';
    return 'mock-l10-xintiandi';
  }

  String _entranceFor(String station) {
    if (station.contains('陕西南路')) return '2号口';
    if (station.contains('虹桥')) return 'B1到达层入口';
    if (station.contains('五角场')) return '5号口';
    return '6号口';
  }

  String _transferStationFor(String start, String end) {
    if (end.contains('静安寺') || end.contains('浦东')) return '南京东路';
    if (end.contains('虹桥')) return '虹桥路';
    if (end.contains('交通大学')) return '交通大学';
    return '南京东路';
  }

  String _exitFor(String station) {
    if (station.contains('静安寺')) return '3号口';
    if (station.contains('虹桥')) return 'B出口';
    if (station.contains('五角场')) return '5号口';
    if (station.contains('陕西南路')) return '2号口';
    return '1号口';
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _AIPlanningPageState._ink,
                          fontSize: 16,
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
    this.doorHint = '车门',
  });

  factory _NavStep.fromJson(Map<String, dynamic> json) {
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
      doorHint: json['doorHint']?.toString() ?? '车门',
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
