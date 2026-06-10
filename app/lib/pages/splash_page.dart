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
          final imageIn = _phase(0.0, 0.72, curve: Curves.easeOutCubic);
          final imagePunch = _phase(0.18, 0.88, curve: Curves.easeInOutCubic);
          final logo = _phase(0.56, 0.96, curve: Curves.elasticOut);
          final fadeIn = _phase(0.82, 1);

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: lerpDouble(1.08, 1.0, imageIn)! +
                    sin(imagePunch * pi) * 0.045,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0008)
                    ..rotateY(lerpDouble(-0.035, 0.018, imagePunch)!)
                    ..rotateX(lerpDouble(0.025, -0.01, imagePunch)!),
                  child: Image.asset(
                    'assets/images/splash_runner_3d.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.26),
                          blurRadius: 42,
                          spreadRadius: -18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.24),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
              ..._buildCoins(size, progress),
              Positioned(
                top: (MediaQuery.paddingOf(context).top + 84)
                    .clamp(76.0, 120.0)
                    .toDouble(),
                left: 20,
                right: 20,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: const [
            Text(
              '同济冲刺',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [
                  Shadow(
                    color: Color(0xFF101828),
                    offset: Offset(5, 7),
                  ),
                ],
              ),
            ),
            Text(
              '同济冲刺',
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
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFFFD166), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: const Text(
            '地铁跑酷换乘助手',
            style: TextStyle(
              color: Color(0xFF1D2939),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
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
      size: const Size(138, 158),
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

    final skin = Paint()..color = const Color(0xFFFFC49A);
    final sleeve = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final sleeveEdge = Paint()
      ..color = const Color(0xFF1E5B9E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final shoe = Paint()
      ..color = const Color(0xFF06D6A0)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final pants = Paint()
      ..color = const Color(0xFF118AB2)
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    final hoodie = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFDDEBFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.49),
        width: 58,
        height: 68,
      ));
    final hoodieEdge = Paint()
      ..color = const Color(0xFF1E5B9E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
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
    canvas.drawCircle(leftFoot.translate(-1, 0), 7, Paint()..color = Colors.white);
    canvas.drawCircle(rightFoot.translate(1, 0), 7, Paint()..color = Colors.white);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.48),
        width: 54,
        height: 62,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(body, hoodie);
    canvas.drawRRect(body, hoodieEdge);
    final scarf = Path()
      ..moveTo(size.width * 0.48, size.height * 0.37)
      ..lineTo(size.width * 0.58, size.height * 0.39)
      ..lineTo(size.width * 0.52, size.height * 0.56)
      ..close();
    canvas.drawPath(scarf, Paint()..color = const Color(0xFFEF476F));
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.39),
      Offset(size.width * 0.52, size.height * 0.62),
      Paint()
        ..color = const Color(0xFFB7C8E8)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.58, size.height * 0.44, 28, 40),
        const Radius.circular(12),
      ),
      bag,
    );

    final shoulder = Offset(size.width * 0.52, size.height * 0.43);
    final raisedHand =
        Offset(size.width * (0.82 + arm * 0.04), size.height * 0.22);
    final leftHand = Offset(size.width * (0.26 - arm * 0.12), size.height * 0.54);
    canvas.drawLine(shoulder, leftHand, sleeve);
    canvas.drawLine(shoulder, leftHand, sleeveEdge);
    canvas.drawCircle(leftHand, 7, skin);
    canvas.drawLine(
      shoulder,
      raisedHand,
      sleeve,
    );
    canvas.drawLine(
      shoulder,
      raisedHand,
      sleeveEdge,
    );
    canvas.drawCircle(raisedHand, 7, skin);
    _drawTrophy(canvas, raisedHand.translate(12, -24), 0.9 + glow * 0.18);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.26),
        width: 55,
        height: 50,
      ),
      Paint()..color = Colors.black.withOpacity(0.13),
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.23),
      23,
      skin,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.22),
        radius: 25,
      ),
      pi,
      pi * 0.45,
      false,
      Paint()
        ..color = const Color(0xFF2F1E15)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
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
    canvas.drawPath(
      cap,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF3A3), Color(0xFF06D6A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.06,
          76,
          42,
        )),
    );
    canvas.drawPath(
      cap,
      Paint()
        ..color = Colors.white.withOpacity(0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.25),
        width: 31,
        height: 10,
      ),
      Paint()..color = const Color(0xFF118AB2),
    );
    _drawTongjiBadge(canvas, Offset(size.width * 0.55, size.height * 0.18));
    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.24),
      2.8,
      Paint()..color = const Color(0xFF1D2939),
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.25),
      2.8,
      Paint()..color = const Color(0xFF1D2939),
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.54, size.height * 0.3),
        width: 18,
        height: 10,
      ),
      0.1,
      pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFF8A3A2A)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTongjiBadge(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 13, Paint()..color = Colors.white);
    canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF0E5AA7));

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '同济',
        style: TextStyle(
          color: Colors.white,
          fontSize: 7,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawTrophy(Canvas canvas, Offset center, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF0A3), Color(0xFFFFB703), Color(0xFFE58E00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(const Rect.fromLTWH(-28, -34, 56, 68));
    final edge = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final cup = Path()
      ..moveTo(-21, -24)
      ..quadraticBezierTo(-19, 7, -5, 15)
      ..lineTo(5, 15)
      ..quadraticBezierTo(19, 7, 21, -24)
      ..close();
    canvas.drawPath(cup, gold);
    canvas.drawPath(cup, edge);
    canvas.drawArc(
      const Rect.fromLTWH(-36, -20, 24, 30),
      -pi / 2,
      -pi,
      false,
      edge,
    );
    canvas.drawArc(
      const Rect.fromLTWH(12, -20, 24, 30),
      -pi / 2,
      pi,
      false,
      edge,
    );
    canvas.drawRect(const Rect.fromLTWH(-4, 15, 8, 15), gold);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-18, 28, 36, 9),
        const Radius.circular(4),
      ),
      gold,
    );

    final shine = Paint()
      ..color = Colors.white.withOpacity(0.62)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-7, -17), const Offset(-12, 3), shine);
    canvas.restore();
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
    _drawCampus(canvas, size);
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

    final birdPaint = Paint()
      ..color = Colors.white.withOpacity(0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.14 + i * 0.18);
      final y = size.height * (0.14 + sin(progress * pi * 2 + i) * 0.015);
      canvas.drawArc(Rect.fromLTWH(x, y, 18, 9), pi, pi, false, birdPaint);
      canvas.drawArc(Rect.fromLTWH(x + 16, y, 18, 9), pi, pi, false, birdPaint);
    }
  }

  void _drawCampus(Canvas canvas, Size size) {
    final buildingPaint = Paint()..color = const Color(0xFFE7A6A0).withOpacity(0.9);
    final roofPaint = Paint()..color = const Color(0xFF8A3B4D).withOpacity(0.96);
    final windowPaint = Paint()..color = const Color(0xFFBDEBFF).withOpacity(0.72);

    final left = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.22, size.width * 0.28,
          size.height * 0.25),
      const Radius.circular(14),
    );
    final right = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.67, size.height * 0.19, size.width * 0.28,
          size.height * 0.28),
      const Radius.circular(14),
    );
    canvas.drawRRect(left, buildingPaint);
    canvas.drawRRect(right, buildingPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.04, size.height * 0.21, size.width * 0.3, 12),
      roofPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.66, size.height * 0.18, size.width * 0.3, 12),
      roofPaint,
    );

    for (var side = 0; side < 2; side++) {
      final baseX = side == 0 ? size.width * 0.09 : size.width * 0.71;
      final baseY = side == 0 ? size.height * 0.27 : size.height * 0.24;
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 3; col++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(baseX + col * 28, baseY + row * 30, 17, 16),
              const Radius.circular(4),
            ),
            windowPaint,
          );
        }
      }
    }

    _drawStartGate(canvas, size);
    _drawGoBoard(canvas, size);
    _drawConfetti(canvas, size);
  }

  void _drawStartGate(Canvas canvas, Size size) {
    final pole = Paint()
      ..color = const Color(0xFF172033).withOpacity(0.86)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.31;
    canvas.drawLine(Offset(size.width * 0.32, y), Offset(size.width * 0.32, y + 72), pole);
    canvas.drawLine(Offset(size.width * 0.68, y), Offset(size.width * 0.68, y + 72), pole);
    canvas.drawLine(Offset(size.width * 0.32, y), Offset(size.width * 0.68, y), pole);

    final signRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.5, y - 8), width: 132, height: 38),
      const Radius.circular(18),
    );
    canvas.drawRRect(signRect, Paint()..color = const Color(0xFFFFD166));
    _drawCenteredText(canvas, 'TONGJI', Offset(size.width * 0.5, y - 16), 15,
        const Color(0xFF172033));
    _drawCenteredText(canvas, 'START', Offset(size.width * 0.5, y + 1), 9,
        const Color(0xFF8A3B4D));
  }

  void _drawGoBoard(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.42, 68, 28),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFEF476F));
    _drawCenteredText(canvas, 'GO', Offset(size.width * 0.7 + 34, size.height * 0.42 + 8),
        12, Colors.white);
  }

  void _drawConfetti(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFFFFD166),
      const Color(0xFFEF476F),
      const Color(0xFF06D6A0),
      const Color(0xFF67E8F9),
    ];
    for (var i = 0; i < 22; i++) {
      final t = ((i * 0.071) + progress * 0.42) % 1;
      final x = size.width * ((i * 37 % 100) / 100);
      final y = size.height * lerpDouble(0.1, 0.74, t)!;
      final rect = Rect.fromCenter(
        center: Offset(x + sin(progress * pi * 2 + i) * 18, y),
        width: 5,
        height: 10,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(progress * pi * 4 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height),
          const Radius.circular(2),
        ),
        Paint()..color = colors[i % colors.length].withOpacity(0.75),
      );
      canvas.restore();
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
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
