import 'dart:math';
import 'package:flutter/material.dart';

/// Patlama/konfeti parçacığı
class Particle {
  late double x, y, vx, vy, size, opacity, spin;
  final Color color;
  final double gravity;
  final double life;
  double age = 0;

  Particle({
    required this.x,
    required this.y,
    required this.color,
    double speed = 4,
    double angleDeg = 0,
    double size = 5,
    double gravity = 0.25,
    double life = 1.0,
  })  : gravity = gravity,
        life = life {
    final a = angleDeg * pi / 180;
    vx = cos(a) * speed;
    vy = sin(a) * speed;
    this.size = size;
    opacity = 1;
    spin = Random().nextDouble() * 6 - 3;
  }

  bool update(double dt) {
    age += dt;
    x += vx;
    y += vy;
    vy += gravity;
    opacity = (1 - age / life).clamp(0.0, 1.0);
    return age < life;
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(spin * age);
    canvas.drawCircle(Offset.zero, size, paint);
    canvas.restore();
  }
}

/// Parçacık patlaması: konumda anlık "pop" efekti
class BurstController {
  final List<Particle> particles = [];
  final List<Color> palette;
  final Random _rng = Random();

  BurstController({List<Color>? palette})
      : palette = palette ??
            const [
              Color(0xFFFF2D95),
              Color(0xFF4DE8FF),
              Color(0xFFFFD24A),
              Color(0xFFB24DFF),
            ];

  void burst(double x, double y, {int count = 14, double speed = 5, double size = 4, List<Color>? palette}) {
    final p = palette ?? this.palette;
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 360;
      particles.add(Particle(
        x: x,
        y: y,
        color: p[_rng.nextInt(p.length)],
        angleDeg: angle,
        speed: speed * (0.5 + _rng.nextDouble() * 0.8),
        size: size * (0.6 + _rng.nextDouble() * 0.7),
        life: 0.6 + _rng.nextDouble() * 0.5,
      ));
    }
  }

  void confetti(double width, double height, {int count = 40, List<Color>? palette}) {
    final p = palette ?? this.palette;
    for (var i = 0; i < count; i++) {
      final angle = 240 + _rng.nextDouble() * 60; // yukarı doğru
      particles.add(Particle(
        x: width / 2 + (_rng.nextDouble() - 0.5) * width * 0.5,
        y: height * 0.55,
        color: p[_rng.nextInt(p.length)],
        angleDeg: angle,
        speed: 6 + _rng.nextDouble() * 7,
        size: 3 + _rng.nextDouble() * 4,
        gravity: 0.3,
        life: 1.4 + _rng.nextDouble() * 0.8,
      ));
    }
  }

  void tick(double dt) {
    particles.removeWhere((p) => !p.update(dt));
  }

  void draw(Canvas canvas) {
    for (final p in particles) {
      p.draw(canvas);
    }
  }
}

/// Parçacık layer widget — child'ın üstünde overlay olarak çalışır
class ParticleOverlay extends StatefulWidget {
  final Widget child;
  final BurstController? controller;

  const ParticleOverlay({super.key, required this.child, this.controller});

  @override
  State<ParticleOverlay> createState() => ParticleOverlayState();
}

class ParticleOverlayState extends State<ParticleOverlay> with TickerProviderStateMixin {
  late final BurstController _c;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _c = widget.controller ?? BurstController();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))..addListener(_onTick);
    _anim.repeat();
  }

  void _onTick() {
    _c.tick(1 / 60);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  BurstController get controller => _c;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ParticlesPainter(_c)),
          ),
        ),
      ],
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final BurstController c;
  _ParticlesPainter(this.c);

  @override
  void paint(Canvas canvas, Size size) => c.draw(canvas);

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) => true;
}
