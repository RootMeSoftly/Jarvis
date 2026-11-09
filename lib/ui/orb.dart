import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OrbState { idle, thinking, speaking }

class JarvisOrb extends StatefulWidget {
  final OrbState state;
  final double size;
  const JarvisOrb({super.key, required this.state, this.size = 220});
  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: _OrbPainter(_c.value, widget.state),
        ),
      ),
    );
  }
}

Color _a(Color c, double o) => c.withAlpha((o * 255).round());

class _OrbPainter extends CustomPainter {
  final double t;
  final OrbState s;
  _OrbPainter(this.t, this.s);

  static const cyan = Color(0xFF00E5FF);
  static const blue = Color(0xFF2979FF);

  @override
  void paint(Canvas canvas, Size size) {
    final ctr = size.center(Offset.zero);
    final r = size.width / 2;
    final k = s == OrbState.idle ? 1.0 : (s == OrbState.thinking ? 6.0 : 3.0);
    final amp = s == OrbState.idle ? 0.03 : (s == OrbState.thinking ? 0.05 : 0.10);
    final pulse = 1 + amp * math.sin(t * 2 * math.pi * k);

    // outer glow
    canvas.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = RadialGradient(colors: [_a(cyan, .30), _a(cyan, 0)])
            .createShader(Rect.fromCircle(center: ctr, radius: r)),
    );

    // core
    final core = r * 0.42 * pulse;
    canvas.drawCircle(
      ctr,
      core,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, cyan, _a(blue, .25)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromCircle(center: ctr, radius: core)),
    );

    // rotating rings
    final speed = s == OrbState.thinking ? 3.0 : 1.0;
    for (int i = 0; i < 3; i++) {
      final rad = r * (0.62 + 0.13 * i);
      final dir = i.isEven ? 1 : -1;
      final start = t * 2 * math.pi * dir * (i + 1) * 0.5 * speed;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = _a(i == 1 ? blue : cyan, .85 - i * .2);
      final rect = Rect.fromCircle(center: ctr, radius: rad);
      canvas.drawArc(rect, start, 1.6, false, p);
      canvas.drawArc(rect, start + math.pi, 0.8, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}
