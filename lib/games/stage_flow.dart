import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';
import '../core/career_model.dart';
import '../core/career_provider.dart';
import 'rhythm_game.dart';
import 'lyrics_game.dart';
import 'social_games.dart';

/// Konser akışı — NSS "match" karşılığı
/// Sahneye çık → stil seç → ritim tut (koro) → spotlight paylaş (bridge)
/// → teleprompter krizi (prompter) → kutlama → skor
class StageFlow extends HookConsumerWidget {
  const StageFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(0); // 0 intro, 1 rhythm, 2 spotlight, 3 prompter, 4 kutlama, 5 skor
    final state = ref.watch(careerProvider);
    final beatRecord = useState<List<double>>([]);
    final spotlightResult = useState<Map<String, dynamic>>({});
    final lyricsResult = useState<List<int>>([0, 0]);
    final celebration = useState<String?>(null);
    final showResult = useState<ShowResult?>(null);
    final chosenStyle = useState<StageStyle?>(null);
    final burstController = useMemoized(() => BurstController());
    final rng = useMemoized(() => Random());

    // şarkı seti: ezberlenen şarkılar varsa onlardan, yoksa varsayılan
    final songPool = state.learnedSongs.isEmpty
        ? ['Aşkın Olayım', 'Gel Gör Beni', 'Deli Divane']
        : state.learnedSongs;

    void applyFinalScore() {
      final rhythm = beatRecord.value;
      final rhythmScore = rhythm.isEmpty
          ? 50
          : (rhythm.reduce((a, b) => a + b) / rhythm.length * 100).round();
      final perfects = rhythm.where((v) => v > 0.85).length;

      final picked = spotlightResult.value['picked'] ?? -1;
      final spotlightScore = picked >= 0 ? 90 : 40;

      final lyricsCorrect = lyricsResult.value[0];
      final lyricsTotal = max(lyricsResult.value[1], 1);
      final prompterScore = (lyricsCorrect / lyricsTotal * 100).round();

      final score = ((rhythmScore * 0.5) + (spotlightScore * 0.25) + (prompterScore * 0.25)).round();

      final voiceCost = (chosenStyle.value == StageStyle.diva) ? 30 : 18;
      final hypeChange = score >= 80 ? 12 : score >= 60 ? 6 : -4;
      final viralGain = score >= 80 ? 150 + perfects * 20 : score >= 60 ? 60 : 10;
      final money = (score * 3 + state.stage.level * 50).round();

      final relationChanges = <String, int>{
        'group': picked >= 0 ? 6 : -5,
        'fans': score >= 60 ? 8 : -4,
        'media': perfects >= 4 ? 10 : 0,
        'sponsor': score >= 70 ? 6 : -2,
      };

      String headline;
      if (score >= 85) {
        headline = 'YILDIZLAR PARLADI: ${state.playerName} sahneyi patlattı!';
      } else if (score >= 60) {
        headline = '${state.playerName} konserinde dengeli bir gece.';
      } else if (prompterScore < 50) {
        headline = 'TELEPROMPTER KRİZİ: ${state.playerName} sözlerini unuttu!';
      } else {
        headline = 'Ses sorunları: ${state.playerName} sahnede zorlandı.';
      }

      showResult.value = ShowResult(
        score: score,
        applause: rhythmScore,
        viralGain: viralGain,
        moneyEarned: money,
        voiceCost: voiceCost,
        hypeChange: hypeChange,
        headline: headline,
        relationChanges: relationChanges,
      );

      ref.read(careerProvider.notifier).applyShowResult(showResult.value!);
      if (picked >= 0) {
        ref.read(careerProvider.notifier).shareSpotlight(picked, 6);
      }
    }

    Widget currentStep() {
      switch (step.value) {
        case 0:
          return _StageIntro(
            onPick: (s) => chosenStyle.value = s,
            onStart: () {
              if (chosenStyle.value != null) {
                ref.read(careerProvider.notifier).setStyle(chosenStyle.value!);
              }
              step.value = 1;
            },
          );
        case 1:
          return RhythmGame(
            bpm: 100 + state.stage.level * 8,
            noteCount: 12 + state.stage.level * 2,
            onBurst: (x, y, palette) =>
                burstController.burst(x, y, count: 18, speed: 7, palette: palette),
            onFinish: (hits, total) {
              beatRecord.value = List.filled(hits, 1.0) + List.filled(total - hits, 0.0);
              step.value = 2;
            },
          );
        case 2:
          return SpotlightGame(
            onFinish: (result) {
              spotlightResult.value = result;
              step.value = 3;
            },
          );
        case 3:
          final song = songPool[rng.nextInt(songPool.length)];
          final words = song.split(' ');
          final shuffled = words.length > 3 ? words.sublist(0, 5) : words;
          return LyricsGame(
            lyricWords: shuffled,
            onFinish: (correct, total) {
              lyricsResult.value = [correct, total];
              step.value = 4;
            },
          );
        case 4:
          return _CelebrateScreen(
            celebration: celebration.value,
            onPick: (c) {
              celebration.value = c;
              ref.read(careerProvider.notifier).celebrate(c);
              applyFinalScore();
              step.value = 5;
            },
          );
        case 5:
          return _ScoreScreen(
            showResult: showResult.value!,
            onExit: () => Navigator.of(context).pop(),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: KeyedSubtree(key: ValueKey(step.value), child: currentStep()),
        ),
      ),
    );
  }
}

// ============================================================
// INTRO — sahneden önce stil seçimi (NSS play style karşılığı)
// ============================================================
class _StageIntro extends HookWidget {
  final Function(StageStyle) onPick;
  final VoidCallback onStart;
  const _StageIntro({required this.onPick, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final chosen = useState<StageStyle?>(null);
    return Stack(
      children: [
        const StageBackdrop(beamCount: 4, floor: true),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                const Text('BU GECE',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFF2D95), Color(0xFFB24DFF), Color(0xFF4DE8FF)],
                  ).createShader(b),
                  child: const Text('NASIL OYNARSIN?',
                      style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.15)),
                ),
                const SizedBox(height: 30),
                ...StageStyle.values.map((s) => _StyleCard(
                      style: s,
                      selected: chosen.value == s,
                      onTap: () {
                        chosen.value = s;
                        onPick(s);
                      },
                    )),
                const SizedBox(height: 24),
                NeonButton(
                  label: 'SAHNEYE ÇIK',
                  color: StageTheme.neonGold,
                  width: double.infinity,
                  enabled: chosen.value != null,
                  onTap: onStart,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StyleCard extends StatelessWidget {
  final StageStyle style;
  final bool selected;
  final VoidCallback onTap;
  const _StyleCard({required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = style == StageStyle.diva ? StageTheme.neonPink : StageTheme.neonCyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.black38,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : color.withValues(alpha: 0.3),
              width: selected ? 2.2 : 1),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 1)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.4)]),
              ),
              child: Icon(style == StageStyle.diva ? Icons.mic : Icons.groups,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style.name, style: TextStyle(color: Colors.white,
                      fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(style.description,
                      style: TextStyle(color: StageTheme.textSub, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: color, size: 22),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// KUTLAMA — NSS goal celebration karşılığı
// ============================================================
class _CelebrateScreen extends StatelessWidget {
  final String? celebration;
  final Function(String) onPick;
  const _CelebrateScreen({required this.celebration, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('👯 GRUP', 'group', 'Grupla kutla — grup uyumu +'),
      ('💖 HAYRANLAR', 'fans', 'Hayranlara koş — hayran +'),
      ('📸 KAMERA', 'camera', 'Kameraya gül — şöhret +, medya -'),
    ];
    return Stack(
      children: [
        const StageBackdrop(beamCount: 6, floor: true),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const Text('ALKIŞLAR SENİN İÇİN!',
                    style: TextStyle(color: StageTheme.neonGold, fontSize: 12, letterSpacing: 4,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFF2D95), Color(0xFFFFD24A)],
                  ).createShader(b),
                  child: const Text('NASIL KUTLARSIN?',
                      style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.15)),
                ),
                const SizedBox(height: 32),
                ...options.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: NeonButton(
                        label: '${o.$1}  ·  ${o.$3}',
                        color: o.$2 == 'group'
                            ? StageTheme.neonPink
                            : o.$2 == 'fans'
                                ? StageTheme.neonPurple
                                : StageTheme.neonCyan,
                        width: double.infinity,
                        selected: celebration == o.$2,
                        onTap: () => onPick(o.$2),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SKOR — NSS maç sonu skor + mülakat karşılığı
// ============================================================
class _ScoreScreen extends StatelessWidget {
  final ShowResult showResult;
  final VoidCallback onExit;
  const _ScoreScreen({required this.showResult, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const StageBackdrop(beamCount: 5, floor: false),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const Text('KONSER BİTTİ',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 12, letterSpacing: 4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(colors: [
                      StageTheme.neonPink.withValues(alpha: 0.25),
                      StageTheme.neonPurple.withValues(alpha: 0.25),
                    ]),
                    border: Border.all(color: StageTheme.neonPink.withValues(alpha: 0.5)),
                  ),
                  child: Text('${showResult.score}',
                      style: const TextStyle(color: Colors.white, fontSize: 54,
                          fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 6),
                Text('SAHNE PUANI',
                    style: TextStyle(color: StageTheme.neonGold, fontSize: 11, letterSpacing: 3,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 26),
                _StatRow('Alkış (ritim)', '${showResult.applause}%'),
                const SizedBox(height: 10),
                _StatRow('Viral kazanç', '+${showResult.viralGain}'),
                const SizedBox(height: 10),
                _StatRow('Kazanç', '₺${showResult.moneyEarned}'),
                const SizedBox(height: 10),
                _StatRow('Ses maliyeti', '-${showResult.voiceCost}'),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StageTheme.neonCyan.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MAGAZİN',
                          style: TextStyle(color: StageTheme.neonCyan, fontSize: 10,
                              letterSpacing: 3, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(showResult.headline,
                          style: const TextStyle(color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                NeonButton(label: 'GERİ DÖN', color: StageTheme.neonPink,
                    width: double.infinity, onTap: onExit),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: StageTheme.textSub, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.w700)),
      ],
    );
  }
}
