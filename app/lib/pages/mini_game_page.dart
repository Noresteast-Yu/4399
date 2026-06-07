import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smart_travel_app/components/common/bottom_nav_bar.dart';
import 'package:smart_travel_app/components/common/top_nav_bar.dart';

class MiniGamePage extends StatefulWidget {
  const MiniGamePage({super.key});

  @override
  State<MiniGamePage> createState() => _MiniGamePageState();
}

class _MiniGamePageState extends State<MiniGamePage>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF14213D);
  static const Color _line10 = Color(0xFFB07AB2);
  static const Color _coin = Color(0xFFFFC857);
  static const Color _danger = Color(0xFFE8505B);
  static const Color _green = Color(0xFF00A676);

  late final AnimationController _ticker;
  final Random _random = Random();
  final List<_GameObject> _objects = [];

  int _lane = 1;
  int _score = 0;
  int _bestScore = 0;
  double _timeLeft = 45;
  double _spawnClock = 0;
  double _speed = 0.34;
  bool _isRunning = false;
  bool _isJumping = false;
  bool _isSliding = false;
  bool _gameOver = false;
  bool _recentlyHit = false;
  String _statusText = '准备换乘';

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tick);
    _resetGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _resetGame() {
    setState(() {
      _lane = 1;
      _score = 0;
      _timeLeft = 45;
      _spawnClock = 0;
      _speed = 0.34;
      _objects
        ..clear()
        ..add(_GameObject.coin(lane: 1, y: -0.25))
        ..add(_GameObject.obstacle(lane: 0, y: -0.55, type: _ObstacleType.low));
      _isRunning = true;
      _isJumping = false;
      _isSliding = false;
      _gameOver = false;
      _recentlyHit = false;
      _statusText = '上滑跳过行李箱，下滑穿过闸机';
    });
    _ticker.repeat();
  }

  void _tick() {
    if (!_isRunning || _gameOver) return;
    const dt = 0.016;
    _spawnClock += dt;
    _timeLeft -= dt;
    _speed = min(0.62, _speed + dt * 0.006);

    if (_spawnClock >= 0.82) {
      _spawnClock = 0;
      _spawnObject();
    }

    for (final object in _objects) {
      object.y += _speed * dt;
    }
    _objects.removeWhere((object) => object.y > 1.14);
    _checkCollisions();

    if (_timeLeft <= 0) {
      _finishGame();
      return;
    }

    setState(() {});
  }

  void _spawnObject() {
    final lane = _random.nextInt(3);
    if (_random.nextDouble() < 0.34) {
      _objects.add(_GameObject.coin(lane: lane, y: -0.12));
      return;
    }

    final type =
        _ObstacleType.values[_random.nextInt(_ObstacleType.values.length)];
    _objects.add(_GameObject.obstacle(lane: lane, y: -0.12, type: type));

    if (_random.nextDouble() < 0.28) {
      final coinLane = (lane + 1 + _random.nextInt(2)) % 3;
      _objects.add(_GameObject.coin(lane: coinLane, y: -0.38));
    }
  }

  void _checkCollisions() {
    for (final object in List<_GameObject>.from(_objects)) {
      if (object.lane != _lane || object.y < 0.76 || object.y > 0.93) {
        continue;
      }

      if (object.kind == _GameObjectKind.coin) {
        _objects.remove(object);
        _score += 10;
        _timeLeft = min(60, _timeLeft + 1.5);
        _statusText = '抢到时间币 +1.5秒';
        continue;
      }

      final type = object.obstacleType;
      final avoided = (type == _ObstacleType.low && _isJumping) ||
          (type == _ObstacleType.high && _isSliding);
      if (avoided) {
        _score += 3;
        _statusText = type == _ObstacleType.low ? '漂亮跳跃 +3' : '顺利滑行 +3';
        continue;
      }

      _hitObstacle(object);
      break;
    }
  }

  void _hitObstacle(_GameObject object) {
    if (_recentlyHit) return;
    _objects.remove(object);
    _recentlyHit = true;
    _timeLeft -= 6;
    _score = max(0, _score - 12);
    _statusText = '撞到障碍，换乘时间 -6秒';
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _recentlyHit = false;
    });
    if (_timeLeft <= 0) {
      _finishGame();
    }
  }

  void _finishGame() {
    _ticker.stop();
    setState(() {
      _isRunning = false;
      _gameOver = true;
      _bestScore = max(_bestScore, _score);
    });
  }

  void _moveLane(int delta) {
    if (!_isRunning || _gameOver) return;
    setState(() {
      _lane = (_lane + delta).clamp(0, 2).toInt();
      _statusText = switch (_lane) {
        0 => '左侧通道',
        1 => '中央通道',
        _ => '右侧通道',
      };
    });
  }

  void _jump() {
    if (!_isRunning || _gameOver || _isJumping) return;
    setState(() {
      _isJumping = true;
      _isSliding = false;
      _statusText = '跳跃避障';
    });
    Future.delayed(const Duration(milliseconds: 620), () {
      if (mounted) {
        setState(() => _isJumping = false);
      }
    });
  }

  void _slide() {
    if (!_isRunning || _gameOver || _isSliding) return;
    setState(() {
      _isSliding = true;
      _isJumping = false;
      _statusText = '低身滑行';
    });
    Future.delayed(const Duration(milliseconds: 560), () {
      if (mounted) {
        setState(() => _isSliding = false);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -80) {
      _moveLane(-1);
    } else if (velocity > 80) {
      _moveLane(1);
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -80) {
      _jump();
    } else if (velocity > 80) {
      _slide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(title: '换乘冲刺'),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            Column(
              children: [
                _ScoreHeader(
                  score: _score,
                  bestScore: _bestScore,
                  timeLeft: _timeLeft,
                  speed: _speed,
                  statusText: _statusText,
                  onRestart: _resetGame,
                ),
                Expanded(child: _buildTrack()),
              ],
            ),
            if (_gameOver) _GameOverOverlay(score: _score, onRestart: _resetGame),
          ],
        ),
      ),
    );
  }

  Widget _buildTrack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final laneWidth = width / 3;
        final playerY = height * 0.78;
        final playerX = laneWidth * _lane + laneWidth / 2;
        final jumpOffset = _isJumping ? -54.0 : 0.0;
        final playerHeight = _isSliding ? 44.0 : 72.0;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9F7FF), Color(0xFFEAF2FF)],
                ),
              ),
            ),
            for (var i = 0; i < 3; i++)
              Positioned(
                left: i * laneWidth,
                top: 0,
                bottom: 0,
                width: laneWidth,
                child: _LaneStrip(index: i),
              ),
            ..._objects.map((object) {
              final objectX = laneWidth * object.lane + laneWidth / 2;
              final objectY = height * object.y;
              return Positioned(
                left: objectX - 28,
                top: objectY - 28,
                child: _ObjectWidget(object: object),
              );
            }),
            Positioned(
              left: playerX - 34,
              top: playerY + jumpOffset - playerHeight / 2,
              child: _PlayerWidget(
                isJumping: _isJumping,
                isSliding: _isSliding,
                recentlyHit: _recentlyHit,
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: _StationBanner(
                speed: _speed,
                timeLeft: _timeLeft,
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: _ControlHint(
                isJumping: _isJumping,
                isSliding: _isSliding,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final int bestScore;
  final double timeLeft;
  final double speed;
  final String statusText;
  final VoidCallback onRestart;

  const _ScoreHeader({
    required this.score,
    required this.bestScore,
    required this.timeLeft,
    required this.speed,
    required this.statusText,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final hurryLevel = speed < 0.43
        ? '稳步换乘'
        : speed < 0.54
            ? '加速冲刺'
            : '极限赶车';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Metric(label: '得分', value: '$score'),
              const SizedBox(width: 12),
              _Metric(label: '最佳', value: '$bestScore'),
              const SizedBox(width: 12),
              _Metric(label: '剩余', value: '${timeLeft.ceil()}秒'),
              const Spacer(),
              IconButton.filledTonal(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: '重新开始',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 9,
                    value: (timeLeft / 60).clamp(0, 1).toDouble(),
                    color: _MiniGamePageState._green,
                    backgroundColor: const Color(0xFFE9EDF6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                hurryLevel,
                style: const TextStyle(
                  color: _MiniGamePageState._line10,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              statusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _MiniGamePageState._ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LaneStrip extends StatelessWidget {
  final int index;

  const _LaneStrip({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: index == 1
              ? const [Color(0x55FFFFFF), Color(0x22B07AB2)]
              : const [Color(0x22FFFFFF), Color(0x00000000)],
        ),
        border: Border(
          left: index == 0
              ? BorderSide.none
              : BorderSide(color: Colors.white.withOpacity(0.9), width: 2),
        ),
      ),
      child: CustomPaint(painter: _TrackPainter()),
    );
  }
}

class _StationBanner extends StatelessWidget {
  final double speed;
  final double timeLeft;

  const _StationBanner({required this.speed, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    final stage = speed < 0.43
        ? '站厅通道'
        : speed < 0.54
            ? '换乘大厅'
            : '即将进站';
    final icon = timeLeft < 12 ? Icons.timer_rounded : Icons.subway_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _MiniGamePageState._line10.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _MiniGamePageState._line10, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage,
                  style: const TextStyle(
                    color: _MiniGamePageState._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '躲开人流和行李，赶上下一班车',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF667085),
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

class _TrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8D7F4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double y = 18; y < size.height; y += 42) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + 18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerWidget extends StatelessWidget {
  final bool isJumping;
  final bool isSliding;
  final bool recentlyHit;

  const _PlayerWidget({
    required this.isJumping,
    required this.isSliding,
    required this.recentlyHit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 68,
      height: isSliding ? 44 : 72,
      decoration: BoxDecoration(
        color: recentlyHit
            ? _MiniGamePageState._danger
            : _MiniGamePageState._line10,
        borderRadius: BorderRadius.circular(isSliding ? 22 : 24),
        boxShadow: [
          BoxShadow(
            color: _MiniGamePageState._line10.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        isJumping
            ? Icons.keyboard_arrow_up_rounded
            : isSliding
                ? Icons.keyboard_arrow_down_rounded
                : Icons.directions_run_rounded,
        color: Colors.white,
        size: isSliding ? 30 : 38,
      ),
    );
  }
}

class _ObjectWidget extends StatelessWidget {
  final _GameObject object;

  const _ObjectWidget({required this.object});

  @override
  Widget build(BuildContext context) {
    if (object.kind == _GameObjectKind.coin) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _MiniGamePageState._coin,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _MiniGamePageState._coin.withOpacity(0.45),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.more_time_rounded, color: Colors.white),
      );
    }

    final type = object.obstacleType;
    final icon = switch (type) {
      _ObstacleType.low => Icons.work_rounded,
      _ObstacleType.high => Icons.horizontal_rule_rounded,
      _ObstacleType.block => Icons.warning_rounded,
    };
    final label = switch (type) {
      _ObstacleType.low => '跳',
      _ObstacleType.high => '滑',
      _ObstacleType.block => '躲',
    };

    return Container(
      width: 56,
      height: type == _ObstacleType.high ? 36 : 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), _MiniGamePageState._danger],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _MiniGamePageState._danger.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Positioned(
            right: 5,
            bottom: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlHint extends StatelessWidget {
  final bool isJumping;
  final bool isSliding;

  const _ControlHint({required this.isJumping, required this.isSliding});

  @override
  Widget build(BuildContext context) {
    final action = isJumping
        ? '跳跃中'
        : isSliding
            ? '滑行中'
            : '左右滑动换道，上滑跳跃，下滑滑行';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: _MiniGamePageState._line10),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _MiniGamePageState._ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const _GameOverOverlay({required this.score, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.32),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: _MiniGamePageState._coin,
                size: 54,
              ),
              const SizedBox(height: 10),
              const Text(
                '换乘结束',
                style: TextStyle(
                  color: _MiniGamePageState._ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '本次得分 $score',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('再跑一次'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _GameObjectKind { obstacle, coin }

enum _ObstacleType { low, high, block }

class _GameObject {
  final int lane;
  final _GameObjectKind kind;
  final _ObstacleType obstacleType;
  double y;

  _GameObject._({
    required this.lane,
    required this.y,
    required this.kind,
    this.obstacleType = _ObstacleType.block,
  });

  factory _GameObject.coin({required int lane, required double y}) {
    return _GameObject._(lane: lane, y: y, kind: _GameObjectKind.coin);
  }

  factory _GameObject.obstacle({
    required int lane,
    required double y,
    required _ObstacleType type,
  }) {
    return _GameObject._(
      lane: lane,
      y: y,
      kind: _GameObjectKind.obstacle,
      obstacleType: type,
    );
  }
}
