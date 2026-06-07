import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3900),
    )..forward();
    Future.delayed(const Duration(milliseconds: 4150), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end, {Curve curve = Curves.easeOutCubic}) {
    final value = ((_controller.value - start) / (end - start))
        .clamp(0, 1)
        .toDouble();
    return curve.transform(value);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final cameraRush = _phase(0.0, 0.72, curve: Curves.easeInOutCubic);
          final train = _phase(0.08, 0.58, curve: Curves.easeInOutCubic);
          final heroJump = _phase(0.38, 0.86, curve: Curves.easeOutBack);
          final logo = _phase(0.56, 0.96, curve: Curves.elasticOut);
          final fadeIn = _phase(0.82, 1);
          final bob = sin(progress * pi * 9);

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _RunwayPainter(
                  progress: progress,
                  cameraRush: cameraRush,
                ),
              ),
              ..._buildCoins(size, progress),
              Positioned(
                left: size.width * 0.5 - 158 + train * 24,
                top: lerpDouble(size.height * 0.23, size.height * 0.39, train),
                child: Opacity(
                  opacity: (1 - _phase(0.62, 0.82)).clamp(0, 1).toDouble(),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateX(lerpDouble(0.18, -0.08, train)!)
                      ..scale(lerpDouble(0.54, 1.18, train)!),
                    child: const _MetroCar3D(),
                  ),
                ),
              ),
              Positioned(
                left: lerpDouble(-88, size.width * 0.5 - 62, heroJump)!,
                bottom: lerpDouble(80, size.height * 0.22, heroJump)! +
                    sin(heroJump * pi) * 56,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(lerpDouble(-0.5, 0.1, heroJump)!)
                    ..rotateZ(lerpDouble(-0.28, 0.08, heroJump)! + bob * 0.02)
                    ..scale(lerpDouble(0.82, 1.16, heroJump)!),
                  child: _RunnerCharacter(
                    stride: progress,
                    glow: _phase(0.6, 1),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.1,
                left: 18,
                right: 18,
                child: Opacity(
                  opacity: _phase(0.5, 0.78),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX((1 - logo) * 0.4)
                      ..scale(0.72 + logo * 0.28),
                    child: const _ArcadeTitle(),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 42,
                child: Opacity(
                  opacity: fadeIn,
                  child: const _ReadyBar(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildCoins(Size size, double progress) {
    final lanes = [-0.24, 0.0, 0.24];
    return List.generate(8, (index) {
      final depth = ((index / 8) + progress * 1.38) % 1;
      final scale = lerpDouble(0.28, 1.18, depth)!;
      final y = lerpDouble(size.height * 0.37, size.height * 0.78, depth)!;
      final lane = lanes[index % lanes.length];
      final x = size.width * (0.5 + lane * depth);
      final spin = sin((progress * 8 + index) * pi);

      return Positioned(
        left: x - 15 * scale,
        top: y - 15 * scale,
        child: Opacity(
          opacity: lerpDouble(0.2, 0.95, depth)!,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(spin * 0.9)
              ..scale(scale),
            child: const _Coin(),
          ),
        ),
      );
    });
  }
}

class _ArcadeTitle extends StatelessWidget {
  const _ArcadeTitle();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(5, 6),
          child: const Text(
            '换乘冲刺',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        const Text(
          '换乘冲刺',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD166),
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: [
              Shadow(
                color: Color(0xFFEF476F),
                offset: Offset(3, 3),
              ),
              Shadow(
                color: Color(0xFF06D6A0),
                offset: Offset(-3, -2),
              ),
              Shadow(
                color: Color(0xFF118AB2),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.94),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFD166), width: 2),
            ),
            child: const Text(
              '地铁跑酷换乘助手',
              style: TextStyle(
                color: Color(0xFF1D2939),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetroCar3D extends StatelessWidget {
  const _MetroCar3D();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 316,
      height: 118,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 18,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewX(-0.12),
              child: Container(
                width: 276,
                height: 78,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9FAFB), Color(0xFFC7D7FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 35,
            child: Container(
              width: 52,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF172033),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.subway_rounded,
                color: Color(0xFFFFD166),
                size: 25,
              ),
            ),
          ),
          for (var i = 0; i < 4; i++)
            Positioned(
              left: 98 + i * 43,
              top: 36,
              child: Container(
                width: 29,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF67E8F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          Positioned(
            left: 28,
            top: 76,
            right: 34,
            child: Container(
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFEF476F),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 45,
            child: Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD166),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunnerCharacter extends StatelessWidget {
  final double stride;
  final double glow;

  const _RunnerCharacter({required this.stride, required this.glow});

  @override
  Widget build(BuildContext context) {
    final leg = sin(stride * pi * 12) * 0.5;
    final arm = cos(stride * pi * 12) * 0.5;

    return CustomPaint(
      size: const Size(124, 152),
      painter: _RunnerPainter(
        leg: leg,
        arm: arm,
        glow: glow,
      ),
    );
  }
}

class _RunnerPainter extends CustomPainter {
  final double leg;
  final double arm;
  final double glow;

  const _RunnerPainter({
    required this.leg,
    required this.arm,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.12 + glow * 0.18);
    canvas.drawCircle(center, 72 + glow * 18, glowPaint);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 12),
        width: 78,
        height: 17,
      ),
      shadowPaint,
    );

    final skin = Paint()..color = const Color(0xFFFFC6A1);
    final ink = Paint()
      ..color = const Color(0xFF1D2939)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final shoe = Paint()
      ..color = const Color(0xFF06D6A0)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final pants = Paint()
      ..color = const Color(0xFF118AB2)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final hoodie = Paint()..color = const Color(0xFFEF476F);
    final bag = Paint()..color = const Color(0xFFFFD166);

    final hip = Offset(size.width * 0.53, size.height * 0.64);
    final leftKnee = Offset(size.width * (0.42 - leg * 0.08), size.height * 0.78);
    final rightKnee =
        Offset(size.width * (0.63 + leg * 0.08), size.height * 0.78);
    final leftFoot =
        Offset(size.width * (0.35 - leg * 0.1), size.height * 0.93);
    final rightFoot =
        Offset(size.width * (0.73 + leg * 0.08), size.height * 0.9);

    canvas.drawLine(hip, leftKnee, pants);
    canvas.drawLine(leftKnee, leftFoot, shoe);
    canvas.drawLine(hip, rightKnee, pants);
    canvas.drawLine(rightKnee, rightFoot, shoe);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.48),
        width: 48,
        height: 58,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, hoodie);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.44, 28, 40),
        const Radius.circular(12),
      ),
      bag,
    );

    final shoulder = Offset(size.width * 0.52, size.height * 0.43);
    canvas.drawLine(
      shoulder,
      Offset(size.width * (0.26 - arm * 0.12), size.height * 0.54),
      ink,
    );
    canvas.drawLine(
      shoulder,
      Offset(size.width * (0.77 + arm * 0.1), size.height * 0.36),
      ink,
    );

    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.23),
      23,
      skin,
    );
    final cap = Path()
      ..moveTo(size.width * 0.32, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.05,
        size.width * 0.75,
        size.height * 0.22,
      )
      ..lineTo(size.width * 0.8, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.56,
        size.height * 0.19,
        size.width * 0.32,
        size.height * 0.22,
      )
      ..close();
    canvas.drawPath(cap, Paint()..color = const Color(0xFF06D6A0));
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.25),
      3,
      Paint()..color = const Color(0xFF1D2939),
    );
  }

  @override
  bool shouldRepaint(covariant _RunnerPainter oldDelegate) {
    return oldDelegate.leg != leg ||
        oldDelegate.arm != arm ||
        oldDelegate.glow != glow;
  }
}

class _Coin extends StatelessWidget {
  const _Coin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3A3), Color(0xFFFFB703)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD166).withOpacity(0.46),
            blurRadius: 13,
          ),
        ],
      ),
      child: const Icon(
        Icons.bolt_rounded,
        color: Color(0xFFE94F37),
        size: 17,
      ),
    );
  }
}

class _ReadyBar extends StatelessWidget {
  const _ReadyBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_double_arrow_up_rounded,
                color: Color(0xFFFFD166),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '跳跃 · 滑行 · 冲刺换乘',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunwayPainter extends CustomPainter {
  final double progress;
  final double cameraRush;

  const _RunwayPainter({
    required this.progress,
    required this.cameraRush,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF4C1D95),
          Color(0xFF0B2A4A),
          Color(0xFF071A2B),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawSky(canvas, size);
    _drawTunnel(canvas, size);
    _drawGraffiti(canvas, size);
    _drawTrack(canvas, size);
    _drawObstacles(canvas, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final moon = Paint()..color = const Color(0xFFFFD166).withOpacity(0.86);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.13), 34, moon);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF67E8F9).withOpacity(0.28),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.35),
          radius: size.width * 0.75,
        ),
      );
    canvas.drawRect(Offset.zero & size, glow);
  }

  void _drawTunnel(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withOpacity(0.12);
    for (var i = 0; i < 7; i++) {
      final t = ((i / 7) + progress * 0.48) % 1;
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.48),
        width: lerpDouble(size.width * 0.2, size.width * 1.15, t)!,
        height: lerpDouble(size.height * 0.12, size.height * 0.78, t)!,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(80 * t)),
        paint,
      );
    }
  }

  void _drawGraffiti(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFEF476F),
      const Color(0xFF06D6A0),
      const Color(0xFF67E8F9),
    ];
    final spray = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      spray.color = colors[i].withOpacity(0.36);
      final y = size.height * (0.2 + i * 0.08);
      final wobble = sin(progress * pi * 2 + i) * 12;
      final path = Path()
        ..moveTo(size.width * 0.05, y + wobble)
        ..quadraticBezierTo(
          size.width * 0.24,
          y - 28,
          size.width * 0.48,
          y + 9,
        )
        ..quadraticBezierTo(
          size.width * 0.65,
          y + 38,
          size.width * 0.94,
          y - 10,
        );
      canvas.drawPath(path, spray);
    }
  }

  void _drawTrack(Canvas canvas, Size size) {
    final vanish = Offset(size.width / 2, size.height * 0.46);
    final floor = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.2, size.height * 0.54)
      ..lineTo(size.width * 0.8, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      floor,
      Paint()..color = const Color(0xFF101828).withOpacity(0.62),
    );

    final rail = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final sideRail = Paint()
      ..color = const Color(0xFF67E8F9).withOpacity(0.62)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final endX in [
      size.width * 0.17,
      size.width * 0.38,
      size.width * 0.62,
      size.width * 0.83,
    ]) {
      canvas.drawLine(vanish, Offset(endX, size.height), rail);
    }
    for (final endX in [size.width * 0.05, size.width * 0.95]) {
      canvas.drawLine(vanish, Offset(endX, size.height), sideRail);
    }

    final sleeper = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.78)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final t = ((i / 18) + progress * 0.82 + cameraRush * 0.18) % 1;
      final y = lerpDouble(size.height * 0.5, size.height * 1.06, t)!;
      final half = lerpDouble(16, size.width * 0.4, t)!;
      canvas.drawLine(
        Offset(size.width / 2 - half, y),
        Offset(size.width / 2 + half, y),
        sleeper,
      );
    }
  }

  void _drawObstacles(Canvas canvas, Size size) {
    final barrierPaint = Paint()..color = const Color(0xFFEF476F);
    final stripePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final t = ((i / 3) + progress * 0.74 + 0.28) % 1;
      final scale = lerpDouble(0.35, 1.15, t)!;
      final y = lerpDouble(size.height * 0.47, size.height * 0.82, t)!;
      final lane = [-0.22, 0.22, 0.0][i];
      final x = size.width * (0.5 + lane * t);
      final rect = Rect.fromCenter(
        center: Offset(x, y),
        width: 46 * scale,
        height: 26 * scale,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(7 * scale)),
        barrierPaint,
      );
      canvas.drawLine(
        Offset(rect.left + 8 * scale, rect.bottom - 6 * scale),
        Offset(rect.right - 8 * scale, rect.top + 6 * scale),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RunwayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.cameraRush != cameraRush;
  }
}
