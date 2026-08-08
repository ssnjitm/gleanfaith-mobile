import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiBurst extends StatefulWidget {
  final int particleCount;
  final Duration duration;
  final VoidCallback? onCompleted;

  const ConfettiBurst({
    super.key,
    this.particleCount = 80,
    this.duration = const Duration(milliseconds: 1800),
    this.onCompleted,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _particles = List.generate(
      widget.particleCount,
      (_) => _ConfettiParticle.random(_random),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted?.call();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller.value,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double sway;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.sway,
  });

  factory _ConfettiParticle.random(Random r) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFFD97706),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
    ];
    return _ConfettiParticle(
      x: r.nextDouble(),
      y: -0.1 - r.nextDouble() * 0.2,
      size: 6 + r.nextDouble() * 8,
      color: colors[r.nextInt(colors.length)],
      vx: (r.nextDouble() - 0.5) * 0.4,
      vy: 0.35 + r.nextDouble() * 0.45,
      rotation: r.nextDouble() * 2 * pi,
      rotationSpeed: (r.nextDouble() - 0.5) * 1.2,
      sway: 0.5 + r.nextDouble() * 2,
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress;
      final wobble = sin(t * p.sway * pi) * 0.06;
      final x = (p.x + p.vx * t + wobble) * size.width;
      final y = (p.y + p.vy * t) * size.height;

      if (y < -20 || y > size.height + 20) continue;

      final alpha = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: alpha * 0.9);
      final rotation = p.rotation + p.rotationSpeed * t;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          Radius.circular(p.size * 0.2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
