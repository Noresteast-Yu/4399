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
