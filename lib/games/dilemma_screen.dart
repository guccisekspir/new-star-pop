import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';
import '../core/career_provider.dart';

/// Dilemma kartları — NSS gece hayatı/skandal anları karşılığı
/// kind: nightClub | secretOffer | socialMedia | rest
class DilemmaScreen extends HookConsumerWidget {
  final String kind;
  final String Function(String choice) headlineGenerator;
  const DilemmaScreen({super.key, required this.kind, required this.headlineGenerator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(careerProvider);
    final resolved = useState(false);
    final picked = useState<String?>(null);
    final burstController = useMemoized(() => BurstController());

    final data = _dataFor(kind);

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: Stack(
          children: [
            StageBackdrop(beamCount: 2, floor: false, tintColor: data.color),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: data.color.withValues(alpha: 0.6)),
                        color: data.color.withValues(alpha: 0.12),
                      ),
                      child: Text(data.tag,
                          style: TextStyle(color: data.color, fontSize: 11,
                              letterSpacing: 3, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 26),
                    Text(data.emoji, style: const TextStyle(fontSize: 64)),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (b) => LinearGradient(
                        colors: [data.color, data.color.withValues(alpha: 0.6)],
                      ).createShader(b),
                      child: Text(data.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w900, height: 1.2)),
                    ),
                    const SizedBox(height: 14),
                    Text(data.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: StageTheme.textSub, fontSize: 13.5, height: 1.5)),
                    const SizedBox(height: 34),

                    if (!resolved.value) ...[
                      ...data.choices.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: NeonButton(
                              label: c.label,
                              color: c.color,
                              width: double.infinity,
                              selected: picked.value == c.id,
                              onTap: () {
                                picked.value = c.id;
                                ref.read(careerProvider.notifier).resolveDilemma(c.id);
                                resolved.value = true;
                              },
                            ),
                          )),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: data.color.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MAGAZİN',
                                style: TextStyle(color: StageTheme.neonCyan, fontSize: 10,
                                    letterSpacing: 3, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Text(headlineGenerator(picked.value ?? ''),
                                style: const TextStyle(color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text(data.resultHint,
                                style: TextStyle(color: StageTheme.textSub, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      NeonButton(label: 'DEVAM ET', color: data.color,
                          width: double.infinity,
                          onTap: () => Navigator.of(context).pop()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DilemmaData _dataFor(String kind) {
    switch (kind) {
      case 'nightClub':
        return _DilemmaData(
          color: Colors.redAccent,
          tag: 'GECE HAYATI',
          emoji: '🍾',
          title: 'Gece Kulübü Kavgası',
          body: 'Ünlü bir gece kulübünde paparazziler seni fotoğrafladı. Bir tartışma çıktı. Ne yapacaksın?',
          choices: [
            _Choice('nightClub', 'Kavgaya devam et', Colors.redAccent),
            _Choice('honest', 'Sakin kal, oradan ayrıl', StageTheme.neonCyan),
          ],
          resultHint: 'Medya ilişkileri değişti.',
        );
      case 'secretOffer':
        return _DilemmaData(
          color: StageTheme.neonGold,
          tag: 'GİZLİ',
          emoji: '🤫',
          title: 'Gizli Kontrat Teklifi',
          body: 'Rakip plak şirketi sana yüksek para teklif etti. Ama grubuna söylemeden görüşürsen...',
          choices: [
            _Choice('acceptOffer', 'Gizlice görüş (₺500, grup uyumu -)', StageTheme.neonGold),
            _Choice('honest', 'Menajere söyle (menajer +)', StageTheme.neonCyan),
          ],
          resultHint: 'Para veya güven — seçimin senin.',
        );
      case 'socialMedia':
        return _DilemmaData(
          color: StageTheme.neonPink,
          tag: 'FANLAR',
          emoji: '💖',
          title: 'Hayran Etkinliği',
          body: 'Sosyal medyada canlı yayın yapabilirsin ama sesini yorarsın. Hayranların bekliyor!',
          choices: [
            _Choice('socialMedia', 'Canlı yayın yap', StageTheme.neonPink),
            _Choice('rest', 'Sessiz kal, dinlen', StageTheme.neonPurple),
          ],
          resultHint: 'Hayranlar seni izliyor.',
        );
      case 'rest':
        return _DilemmaData(
          color: StageTheme.neonPurple,
          tag: 'TOPARLAN',
          emoji: '😴',
          title: 'Dinlenme Günü',
          body: 'Ses tellerin yoruldu. Bir gün dinlenirsen geri kazanırsın ama hype biraz düşer.',
          choices: [
            _Choice('rest', 'Dinlen (ses +35, hype -5)', StageTheme.neonPurple),
            _Choice('socialMedia', 'Zorla devam et (hayran +)', StageTheme.neonPink),
          ],
          resultHint: 'Ses sağlığı en değerli kaynağın.',
        );
      default:
        return _DilemmaData(
          color: StageTheme.neonCyan,
          tag: 'OLAY',
          emoji: '❓',
          title: 'Beklenmedik Olay',
          body: 'Bir şeyler oldu. Sakin kal.',
          choices: [_Choice('honest', 'Sakin kal', StageTheme.neonCyan)],
          resultHint: 'Geçti.',
        );
    }
  }
}

class _DilemmaData {
  final Color color;
  final String tag;
  final String emoji;
  final String title;
  final String body;
  final List<_Choice> choices;
  final String resultHint;
  _DilemmaData({required this.color, required this.tag, required this.emoji,
      required this.title, required this.body, required this.choices, required this.resultHint});
}

class _Choice {
  final String id;
  final String label;
  final Color color;
  _Choice(this.id, this.label, this.color);
}
