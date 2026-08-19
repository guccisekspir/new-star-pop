import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/career_provider.dart';
import '../core/career_model.dart';
import '../core/theme.dart';

/// Spotlight Paylaşımı — NSS "pas seçimi" karşılığı
/// Bridge/dans break anında spotlight'ı kime vereceğini seçersin.
class SpotlightGame extends HookConsumerWidget {
  final ValueChanged<String> onFinish; // 'best','risky','safe'

  const SpotlightGame({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('🎤 BRIDGE BÖLÜMÜ',
              style: TextStyle(
                  color: NSPTheme.stageGold, fontSize: 20,
                  fontWeight: FontWeight.bold, letterSpacing: 3)),
        ),
        const Text('Spotlight 8 saniyeliğine sana ya da grup arkadaşına geçebilir.\nKime veriyorsun?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 15)),
        const SizedBox(height: 24),
        ...state.members.map((m) => _MemberCard(m)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _ActionButton(
              'Ben Al (Diva)',
              NSPTheme.neonPink,
              () => onFinish('best'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionButton(
              'Paylaş',
              NSPTheme.neonCyan,
              () => onFinish('safe'),
            )),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final BandMember m;
  const _MemberCard(this.m);

  @override
  Widget build(BuildContext context) {
    final rel = m.relationship;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: NSPTheme.card(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: NSPTheme.neonPurple,
            child: Text(m.name[0],
                style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text(m.role,
                    style: const TextStyle(color: Colors.white54,
                        fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rel / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          color: rel > 60
                              ? NSPTheme.neonCyan
                              : rel > 30
                                  ? NSPTheme.stageGold
                                  : Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$rel',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Röportaj / Talk Show — NSS basın mülakatı karşılığı
class InterviewGame extends HookConsumerWidget {
  final ValueChanged<String> onFinish; // 'good','neutral','bad'

  const InterviewGame({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('📺 CANLI TALK SHOW',
              style: TextStyle(
                  color: NSPTheme.neonCyan, fontSize: 20,
                  fontWeight: FontWeight.bold, letterSpacing: 3)),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(18),
          decoration: NSPTheme.card(),
          child: const Text(
            'Sunucu: "Grup içinde gerilim olduğuna dair haberler var. Bunu doğruluyor musun? Yoksa solo kariyer mi düşünüyorsun?"',
            style: TextStyle(color: Colors.white, fontSize: 16,
                height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        _InterviewOption(
          'Hayır, biz bir aileyiz. Her şey harika!',
          NSPTheme.neonCyan,
          () => onFinish('good'),
        ),
        const SizedBox(height: 12),
        _InterviewOption(
          'Yorum yapmayacağım.',
          NSPTheme.stageGold,
          () => onFinish('neutral'),
        ),
        const SizedBox(height: 12),
        _InterviewOption(
          'Grup çok amatör, ben zaten tek başıma yeterim.',
          Colors.redAccent,
          () => onFinish('bad'),
        ),
      ],
    );
  }
}

class _InterviewOption extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _InterviewOption(this.text, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Text(text,
            style: TextStyle(color: color, fontSize: 15,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
