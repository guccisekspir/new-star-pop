import 'package:flutter/material.dart';

/// "Neon Sahne" UI kiti — görsel odaklı konser atmosferi
/// Zemin: derin lacivert-mor gradient, sahne spot ışıkları, glassmorphism kartlar
class StageTheme {
  StageTheme._();

  static const Color bgDeep = Color(0xFF0A0520);
  static const Color bgMid = Color(0xFF1A0B3D);
  static const Color bgLight = Color(0xFF2D1060);
  static const Color neonPink = Color(0xFFFF2D95);
  static const Color neonCyan = Color(0xFF4DE8FF);
  static const Color neonGold = Color(0xFFFFD24A);
  static const Color neonPurple = Color(0xFFB24DFF);
  static const Color textMain = Colors.white;
  static const Color textSub = Color(0xFFA8A0C0);

  /// Zemin gradienti (üstten sahne ışıklı derin mor)
  static const LinearGradient stageBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDeep, bgMid, bgLight],
    stops: [0.0, 0.55, 1.0],
  );

  /// Glassmorphism kart
  static BoxDecoration glassCard({
    Color borderColor = Colors.white24,
    double blur = 18,
  }) =>
      BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: blur,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: borderColor.withOpacity(0.12),
            blurRadius: blur * 2,
            spreadRadius: 4,
          ),
        ],
      );

  /// Gradient dolumlu progress bar (can / hype / şöhret)
  static BoxDecoration barFill(Gradient gradient) => BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: gradient,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.25), blurRadius: 6),
        ],
      );

  /// Bar arka planı
  static BoxDecoration barBg() => BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      );

  /// Parlayan (shimmer) efektli gradient dolum — statlar için
  static const LinearGradient pinkFill = LinearGradient(
    colors: [neonPink, Color(0xFFFF7EB9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient cyanFill = LinearGradient(
    colors: [neonCyan, Color(0xFF9FF3FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient goldFill = LinearGradient(
    colors: [neonGold, Color(0xFFFFE9A0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient purpleFill = LinearGradient(
    colors: [neonPurple, Color(0xFFD99BFF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Sahne arka planı: spot ışıkları + zemin reflektif gradient
class StageBackdrop extends StatelessWidget {
  final List<Color> beamColors;
  final bool floor;
  final double beamCount;
  final Color? tintColor;
  const StageBackdrop({
    super.key,
    this.beamColors = const [
      StageTheme.neonPink,
      StageTheme.neonCyan,
      StageTheme.neonGold,
    ],
    this.floor = true,
    this.beamCount = 3,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StagePainter(beamColors: beamColors, floor: floor, beamCount: beamCount.toInt()),
    );
  }
}

class _StagePainter extends CustomPainter {
  final List<Color> beamColors;
  final bool floor;
  final int beamCount;

  _StagePainter({required this.beamColors, required this.floor, required this.beamCount});

  @override
  void paint(Canvas canvas, Size size) {
    // zemin
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [StageTheme.bgDeep, StageTheme.bgMid, StageTheme.bgLight],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // spot ışıkları (sabit pozisyonlar)
    final beamPositions = [0.22, 0.5, 0.78, 0.36, 0.64];
    for (var i = 0; i < beamCount; i++) {
      final x = size.width * beamPositions[i % beamPositions.length];
      final color = beamColors[i % beamColors.length];
      final shader = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [color.withOpacity(0.18), color.withOpacity(0.02), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(x, -size.height * 0.25), radius: size.height * 1.1));
      final paint = Paint()..shader = shader;
      canvas.drawCircle(Offset(x, -size.height * 0.25), size.height * 1.1, paint);
    }

    // sahne zemini (reflektif)
    if (floor) {
      final floorRect = Rect.fromLTWH(0, size.height * 0.86, size.width, size.height * 0.14);
      final floorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [StageTheme.bgLight.withOpacity(0.9), Colors.black.withOpacity(0.75)],
        ).createShader(floorRect);
      canvas.drawRect(floorRect, floorPaint);
      // zemin çizgisi glow
      final line = Paint()
        ..shader = LinearGradient(
          colors: [StageTheme.neonPurple.withOpacity(0.0), StageTheme.neonPurple, StageTheme.neonPurple.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, floorRect.top - 1, size.width, 3));
      canvas.drawRect(Rect.fromLTWH(0, floorRect.top - 1, size.width, 3), line);
    }
  }

  @override
  bool shouldRepaint(covariant _StagePainter old) =>
      old.beamColors != beamColors || old.floor != floor || old.beamCount != beamCount;
}



/// Karakter avatarı: emoji + gradient halka + isim rozeti
class Avatar extends StatelessWidget {
  final String emoji;
  final String name;
  final Color ringColor;
  final double size;
  final bool showName;
  final Color? badgeColor;

  const Avatar({
    super.key,
    required this.emoji,
    this.name = '',
    this.ringColor = StageTheme.neonPink,
    this.size = 54,
    this.showName = true,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ringColor.withOpacity(0.35), ringColor.withOpacity(0.08)],
        ),
        border: Border.all(color: ringColor, width: 2.5),
        boxShadow: [
          BoxShadow(color: ringColor.withOpacity(0.45), blurRadius: 14, spreadRadius: 2),
        ],
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
      ),
    );

    if (!showName || name.isEmpty) return avatar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: (badgeColor ?? ringColor).withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (badgeColor ?? ringColor).withOpacity(0.6), width: 1),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gradient progress bar — label + renk kodlu bar + değer
class NeonBar extends StatelessWidget {
  final String label;
  final String valueText;
  final double progress; // 0..1
  final Gradient? fill;
  final Color? color; // dolgu rengi (fill verilmezse) — gradient olarak sarılır
  final double height;
  final Color textColor;
  final IconData? icon;

  const NeonBar({
    super.key,
    this.label = '',
    this.valueText = '',
    required this.progress,
    this.fill,
    this.color,
    this.height = 12,
    this.textColor = StageTheme.textMain,
    this.icon,
  });

  Gradient get _resolvedFill =>
      fill ?? LinearGradient(
        colors: [color ?? StageTheme.neonPink, (color ?? StageTheme.neonPink).withValues(alpha: 0.6)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: textColor),
                  const SizedBox(width: 5),
                ],
                if (label.isNotEmpty)
                  Text(label, style: const TextStyle(color: StageTheme.textSub, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
            if (valueText.isNotEmpty)
              Text(valueText, style: TextStyle(color: textColor, fontSize: 12.5, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: height,
          decoration: StageTheme.barBg(),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: StageTheme.barFill(_resolvedFill),
            ),
          ),
        ),
      ],
    );
  }
}

/// Neon buton — glow kenarlı, basınca pulse
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final double width;
  final bool enabled;
  final bool selected;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.color,
    this.icon,
    this.width = double.infinity,
    this.enabled = true,
    this.selected = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _pulse,
        
        builder: (context, child) {
          final glow = 6 + _pulse.value * 8;
          return Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            decoration: BoxDecoration(
              gradient: widget.enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.color.withOpacity(widget.selected ? 0.45 : 0.28),
                        widget.color.withOpacity(0.08),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: widget.color.withOpacity(widget.enabled ? (widget.selected ? 1.0 : 0.9) : 0.3), width: widget.selected ? 2.6 : 1.8),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(widget.enabled ? 0.45 : 0.1), blurRadius: glow, spreadRadius: 1),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.color, size: 16),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.enabled ? widget.color : StageTheme.textSub,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



/// Büyük feedback metni (PERFECT / MISS) — renkli, glow'lu
class BigFeedback extends StatelessWidget {
  final String text;
  final Color color;
  final double size;

  const BigFeedback(this.text, {super.key, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        height: 1,
        shadows: [
          Shadow(color: color.withOpacity(0.9), blurRadius: 22, offset: const Offset(0, 2)),
          Shadow(color: color.withOpacity(0.5), blurRadius: 45, offset: const Offset(0, 4)),
        ],
      ),
    );
  }
}
