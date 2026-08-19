import 'package:flutter/material.dart';

/// New Star Pop tema — sahne/arabesk-pop neon estetiği
class NSPTheme {
  static const Color neonPink = Color(0xFFE91E8C);
  static const Color neonPurple = Color(0xFF7B2FC8);
  static const Color neonCyan = Color(0xFF17D3E0);
  static const Color stageGold = Color(0xFFF5C518);
  static const Color darkStage = Color(0xFF140A1E);
  static const Color darkCard = Color(0xFF241438);

  static const BoxDecoration stageGradient = BoxDecoration(
    gradient: LinearGradient(
      colors: [darkStage, Color(0xFF351050), darkStage],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static BoxDecoration card({Color? color}) => BoxDecoration(
        color: color ?? darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPurple.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: neonPink.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

/// Stat çubuğu (NSS yıldız rating karşılığı görselleştirmesi)
class StatBar extends StatelessWidget {
  final String label;
  final int value; // 0-100
  final Color color;
  final String? rightLabel;
  const StatBar({
    super.key,
    required this.label,
    required this.value,
    this.color = NSPTheme.neonPink,
    this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ),
            ),
            Text(
              rightLabel ?? '$value',
              style: TextStyle(color: color, fontSize: 13,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Performans anlık puanı popup'ı (Perfect / Good / Miss)
class HitFeedback extends StatelessWidget {
  final String text;
  final Color color;
  const HitFeedback({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        shadows: [Shadow(color: color, blurRadius: 18)],
      ),
    );
  }
}
