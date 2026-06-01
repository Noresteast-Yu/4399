import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/home/line10_interactive_metro_map.dart';
import 'package:smart_travel_app/services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _ink = Color(0xFF0D1C2F);
  static const Color _muted = Color(0xFF667085);
  static const Color _surface = Color(0xFFF8F9FF);
  static const Color _surfaceBlue = Color(0xFFEFF4FF);
  static const Color _green = Color(0xFF008644);

  final TextEditingController _startController =
      TextEditingController(text: '五角场');
  final TextEditingController _endController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _travelAlerts = [];
  Map<String, dynamic>? _metroArrival;
  bool _isArrivalLoading = false;

  String _selectedMetroStopId = 'mock-l10-wujiaochang';
  String _selectedMetroStopName = '五角场';
  int _selectedMetroDirection = 0;
  double _arrivalDockHeight = 156;
  bool _isDockDragging = false;
  bool _allowStationTapAutoExpand = true;
  Timer? _arrivalTicker;
  DateTime? _arrivalFetchedAt;

  @override
  void initState() {
    super.initState();
    _arrivalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _metroArrival == null) return;
      setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _arrivalTicker?.cancel();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isArrivalLoading = true;
      });

      final results = await Future.wait([
        _apiService.getTravelAlerts(),
        _apiService.getMetroArrival(
          stopId: _selectedMetroStopId,
          stopName: _selectedMetroStopName,
          direction: _selectedMetroDirection,
        ),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('请求超时'),
      );

      final alertsResponse = results[0] as ApiResponse<List<dynamic>>;
      final arrivalResponse = results[1] as ApiResponse<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _travelAlerts = alertsResponse.success && alertsResponse.data != null
            ? List<Map<String, dynamic>>.from(alertsResponse.data!)
            : [];
        final arrivalData =
            arrivalResponse.success && arrivalResponse.data != null
                ? Map<String, dynamic>.from(arrivalResponse.data!)
                : null;
        _metroArrival = arrivalData;
        _arrivalFetchedAt = arrivalData == null ? null : DateTime.now();
        _isArrivalLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isArrivalLoading = false;
        _travelAlerts = [];
        _arrivalFetchedAt = null;
      });
    }
  }

  Future<void> _loadMetroArrival() async {
    setState(() {
      _isArrivalLoading = true;
    });

    final response = await _apiService.getMetroArrival(
      stopId: _selectedMetroStopId,
      stopName: _selectedMetroStopName,
      direction: _selectedMetroDirection,
    );

    if (!mounted) return;
    setState(() {
      final arrivalData = response.success && response.data != null
          ? Map<String, dynamic>.from(response.data!)
          : null;
      _metroArrival = arrivalData;
      _arrivalFetchedAt = arrivalData == null ? null : DateTime.now();
      _isArrivalLoading = false;
    });
  }

  void _selectMetroStation(Line10MapStation station) {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _selectedMetroStopId = station.id;
      _selectedMetroStopName = station.name;
      if (_allowStationTapAutoExpand) {
        _arrivalDockHeight = _dockMaxHeight(size);
      }
    });
    _loadMetroArrival();
  }

  void _disableStationTapAutoExpand() {
    if (!_allowStationTapAutoExpand) return;
    setState(() {
      _allowStationTapAutoExpand = false;
    });
  }

  void _setSelectedAsStart() {
    setState(() {
      _startController.text = _selectedMetroStopName;
    });
  }

  void _setSelectedAsEnd() {
    setState(() {
      _endController.text = _selectedMetroStopName;
    });
  }

  void _goPlanning() {
    final start = _startController.text.trim();
    final end = _endController.text.trim();
    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择起点和终点')),
      );
      return;
    }
    context.go(
      '/ai-planning?start=${Uri.encodeComponent(start)}&end=${Uri.encodeComponent(end)}',
    );
  }

  double _dockMinHeight(Size size) => size.height < 720 ? 136 : 156;

  double _dockMaxHeight(Size size) =>
      (size.height * 0.42).clamp(270.0, 318.0).toDouble();

  double _resolvedDockHeight(Size size) {
    return _arrivalDockHeight
        .clamp(_dockMinHeight(size), _dockMaxHeight(size))
        .toDouble();
  }

  void _handleDockDragStart(DragStartDetails details) {
    setState(() {
      _isDockDragging = true;
    });
  }

  void _handleDockDragUpdate(DragUpdateDetails details, Size size) {
    final nextHeight = (_arrivalDockHeight - details.delta.dy)
        .clamp(_dockMinHeight(size), _dockMaxHeight(size))
        .toDouble();
    setState(() {
      _arrivalDockHeight = nextHeight;
    });
  }

  void _handleDockDragEnd(DragEndDetails details, Size size) {
    final minHeight = _dockMinHeight(size);
    final maxHeight = _dockMaxHeight(size);
    final velocity = details.primaryVelocity ?? 0;
    final midpoint = minHeight + (maxHeight - minHeight) * 0.42;
    final targetHeight = velocity < -260
        ? maxHeight
        : velocity > 260
            ? minHeight
            : _arrivalDockHeight >= midpoint
                ? maxHeight
                : minHeight;

    setState(() {
      _isDockDragging = false;
      _arrivalDockHeight = targetHeight;
      if (targetHeight == minHeight) {
        _allowStationTapAutoExpand = false;
      }
    });
  }

  double? _arrivalNumber(String key) {
    final value = _metroArrival?[key];
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  double _arrivalElapsedSeconds() {
    final fetchedAt = _arrivalFetchedAt;
    if (fetchedAt == null) return 0;
    return DateTime.now().difference(fetchedAt).inSeconds.toDouble();
  }

  int? _remainingMinutesFor(String key) {
    final initialMinutes = _arrivalNumber(key);
    if (initialMinutes == null) return null;
    final remainingSeconds =
        (initialMinutes * 60 - _arrivalElapsedSeconds()).clamp(0.0, 3600.0);
    return (remainingSeconds / 60).ceil().clamp(0, 999).toInt();
  }

  double _arrivalIntervalSeconds() {
    final explicitInterval = _arrivalNumber('interval');
    if (explicitInterval != null && explicitInterval > 0) {
      return (explicitInterval * 60).clamp(90.0, 1200.0).toDouble();
    }

    final current = _arrivalNumber('currentArriveMinutes');
    final next = _arrivalNumber('nextArriveMinutes');
    if (current != null && next != null && next > current) {
      return ((next - current) * 60).clamp(90.0, 1200.0).toDouble();
    }

    return 8 * 60;
  }

  double? _arrivalProgress() {
    final current = _arrivalNumber('currentArriveMinutes');
    if (current == null) return null;

    final remainingSeconds =
        (current * 60 - _arrivalElapsedSeconds()).clamp(0.0, 3600.0);
    final intervalSeconds = _arrivalIntervalSeconds();
    return (1 - remainingSeconds / intervalSeconds)
        .clamp(0.04, 0.98)
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      extendBody: false,
      backgroundColor: _surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: _MapBackground()),
          Positioned.fill(
            child: Line10InteractiveMetroMap(
              selectedStationId: _selectedMetroStopId,
              onStationSelected: _selectMetroStation,
              onMapInteraction: _disableStationTapAutoExpand,
              height: size.height,
              immersive: true,
              showControls: true,
              showHint: false,
              controlsBottomOffset: _resolvedDockHeight(size) + 28,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: _MapReadabilityVeil()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: _buildTopOverlay(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: AnimatedContainer(
              duration: _isDockDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: _resolvedDockHeight(size),
              child: _buildArrivalDock(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTopOverlay() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassPanel(
          borderRadius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            children: [
              Icon(Icons.subway_rounded, color: _line10, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '地铁跑酷换乘助手',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _GlassPanel(
          borderRadius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              _compactRouteField(
                icon: Icons.trip_origin_rounded,
                iconColor: _green,
                controller: _startController,
                hintText: '选择起点',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF98A2B3),
                  size: 19,
                ),
              ),
              _compactRouteField(
                icon: Icons.location_on_outlined,
                iconColor: Color(0xFFFF4D5A),
                controller: _endController,
                hintText: '选择终点',
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _line10,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _goPlanning,
                  child: const Icon(Icons.near_me_rounded, size: 21),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compactRouteField({
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Expanded(
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivalDock() {
    final arrival = _metroArrival;
    final hasData = arrival != null;
    final currentMinutes =
        _remainingMinutesFor('currentArriveMinutes')?.toString() ??
            arrival?['currentArriveMinutes']?.toString() ??
            '?';
    final nextMinutes = _remainingMinutesFor('nextArriveMinutes')?.toString() ??
        arrival?['nextArriveMinutes']?.toString() ??
        '?';
    final location = arrival?['trainLocation']?.toString() ?? '未知位置';
    final nextStop =
        arrival?['trainNextStop']?.toString() ?? _selectedMetroStopName;
    final alertLabel = _travelAlerts.isEmpty
        ? '运行正常'
        : (_travelAlerts.first['title'] ?? '实时提醒').toString();
    final size = MediaQuery.sizeOf(context);
    final expanded = _resolvedDockHeight(size) > _dockMaxHeight(size) - 28;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onVerticalDragStart: _handleDockDragStart,
      onVerticalDragUpdate: (details) => _handleDockDragUpdate(details, size),
      onVerticalDragEnd: (details) => _handleDockDragEnd(details, size),
      child: _GlassPanel(
        borderRadius: 30,
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4D9E5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _selectedMetroStopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _pill('10号线', _line10, Colors.white),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasData ? alertLabel : '模拟接口未连接',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasData ? _green : const Color(0xFFBA1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: '刷新到站时间',
                  onPressed: _loadMetroArrival,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (expanded) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _isArrivalLoading
                        ? const SizedBox(
                            height: 74,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _countdownBlock(
                            currentMinutes: currentMinutes,
                            nextMinutes: nextMinutes,
                            hasData: hasData,
                          ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 126, child: _directionSelector()),
                ],
              ),
              const SizedBox(height: 8),
              _trainTracker(
                location: location,
                nextStop: nextStop,
                progress: _arrivalProgress(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniAction(Icons.trip_origin_rounded, '起点', () {
                    _setSelectedAsStart();
                  }),
                  const SizedBox(width: 8),
                  _miniAction(Icons.flag_rounded, '终点', () {
                    _setSelectedAsEnd();
                  }),
                  const SizedBox(width: 8),
                  _miniAction(Icons.elevator_rounded, '设施', () {
                    context.push('/subway-service');
                  }),
                  const SizedBox(width: 8),
                  _miniAction(Icons.timer_rounded, '计时', () {
                    context.push('/transfer-time');
                  }),
                ],
              ),
            ] else
              _compactArrivalSummary(
                currentMinutes: currentMinutes,
                nextMinutes: nextMinutes,
                hasData: hasData,
              ),
          ],
        ),
      ),
    );
  }

  Widget _compactArrivalSummary({
    required String currentMinutes,
    required String nextMinutes,
    required bool hasData,
  }) {
    final label = _isArrivalLoading
        ? '正在刷新到站时间'
        : hasData
            ? '最近一班 $currentMinutes 分钟后，下一班 $nextMinutes 分钟后'
            : '上拉查看到站详情';

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _surfaceBlue.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.train_rounded, color: _line10, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _compactSetButton(
              '起点', Icons.trip_origin_rounded, _setSelectedAsStart),
          const SizedBox(width: 6),
          _compactSetButton('终点', Icons.flag_rounded, _setSelectedAsEnd),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            color: _line10,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _compactSetButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _line10, size: 14),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countdownBlock({
    required String currentMinutes,
    required String nextMinutes,
    required bool hasData,
  }) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: _surfaceBlue.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            hasData ? currentMinutes : '--',
            style: const TextStyle(
              color: _line10,
              fontSize: 46,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 5, bottom: 4),
            child: Text(
              '分钟',
              style: TextStyle(
                color: _line10,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '下一班',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                hasData ? '$nextMinutes 分钟' : '--',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _directionSelector() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1F7),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        children: [
          _directionChip('往基隆路', 0),
          const SizedBox(height: 5),
          _directionChip('反方向', 1),
        ],
      ),
    );
  }

  Widget _directionChip(String label, int value) {
    final selected = _selectedMetroDirection == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (selected) return;
          setState(() {
            _selectedMetroDirection = value;
          });
          _loadMetroArrival();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _line10 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _trainTracker({
    required String location,
    required String nextStop,
    required double? progress,
  }) {
    return Row(
      children: [
        const Icon(Icons.train_rounded, color: _line10, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _arrivalProgressBar(progress),
              const SizedBox(height: 5),
              Text(
                '$location → $nextStop',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _arrivalProgressBar(double? progress) {
    if (progress == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 6,
          color: _line10,
          backgroundColor: const Color(0xFFD1C2CD),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final fillWidth = (width * value).clamp(18.0, width).toDouble();
            final trainLeft =
                (fillWidth - 10).clamp(0.0, width - 18).toDouble();

            return SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1C2CD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 7,
                    child: Container(
                      width: fillWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFB07AB2),
                            Color(0xFFC48AC5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: _line10.withOpacity(0.28),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: trainLeft,
                    top: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _line10, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _line10.withOpacity(0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.train_rounded,
                        color: _line10,
                        size: 11,
                      ),
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

  Widget _miniAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _line10, size: 18),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MapBackground extends StatelessWidget {
  const _MapBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FF),
            Color(0xFFEFF4FF),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: CustomPaint(painter: _GridPainter()),
    );
  }
}

class _MapReadabilityVeil extends StatelessWidget {
  const _MapReadabilityVeil();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.28),
            Colors.white.withOpacity(0.02),
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.42),
          ],
          stops: const [0, 0.28, 0.62, 1],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCDBF4).withOpacity(0.34)
      ..strokeWidth = 1;
    const step = 42.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassPanel({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B4A7F).withOpacity(0.08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
