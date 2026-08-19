import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/career_provider.dart';
import '../core/career_model.dart';
import '../core/theme.dart';
import 'rhythm_game.dart';
import 'lyrics_game.dart';
import 'social_games.dart';

enum StagePhase { intro, rhythm, spotlight, lyrics, interview, finale, done }

/// Konser Akışı — NSS maç döngüsü karşılığı
/// intro → ritim (koro) → spotlight (bridge) → söz ezberleme (kriz) →
/// röportaj (post-match) → kutlama finale → sonuç
class StageFlow extends HookConsumerWidget {
  final ValueChanged<ShowResult> onShowEnd;
  final VoidCallback onBack;

  const StageFlow({super.key, required this.onShowEnd, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final phase = useState(StagePhase.intro);
    final hits = useState(0);
    final lyricSaved = useState(0);
    final interviewResult = useState<String?>(null);
    final celebrationChosen = useState(false);

    // Rhythm oyunu isabet sayısı
    void onRhythmDone(int h) {
      hits.value = h;
      phase.value = StagePhase.spotlight;
    }

    // Spotlight seçimi sonrası söz ezberleme krizi
    void onSpotlight(String choice) {
      final memberAvg = state.members
              .map((m) => m.relationship)
              .reduce((a, b) => a + b) ~/
          state.members.length;
      final risky = memberAvg < 40;
      if (choice == 'best') {
        // diva seçimi: ses sağlığından ekstra maliyet
        state.voice = (state.voice - 8).clamp(0, 100);
      } else if (choice == 'safe' && !risky) {
        state.members.forEach((m) => m.relationship =
            (m.relationship + 5).clamp(0, 100));
      }
      phase.value = StagePhase.lyrics;
    }

    void onLyricsDone(int saved) {
      lyricSaved.value = saved;
      phase.value = StagePhase.interview;
    }

    void onInterview(String r) {
      interviewResult.value = r;
      phase.value = StagePhase.finale;
    }

    void onCelebrate(String choice) {
      ref.read(careerProvider.notifier).celebrate(choice);
      celebrationChosen.value = true;
      phase.value = StagePhase.done;
      onShowEnd(_computeResult(state, hits.value, lyricSaved.value,
          interviewResult.value!, phase, hits.value));
    }

    final Widget body;
    switch (phase.value) {
      case StagePhase.intro:
        body = _Intro(ref: ref, onStart: () => phase.value = StagePhase.rhythm);
      case StagePhase.rhythm:
        body = RhythmGame(bpm: _bpmForStage(state.stage),
            onFinish: onRhythmDone);
      case StagePhase.spotlight:
        body = SpotlightGame(onFinish: onSpotlight);
      case StagePhase.lyrics:
        body = LyricsGame(
          words: const [
            'Yandım', 'bu', 'gece', 'sensiz',
            'kalbim', 'boş', 'sokaklarda', 'seni', 'arıyorum',
          ],
          onFinish: onLyricsDone,
        );
      case StagePhase.interview:
        body = InterviewGame(onFinish: onInterview);
      case StagePhase.finale:
        body = _Finale(ref: ref, onCelebrate: onCelebrate,
            showResult: _computeResult(state, hits.value, lyricSaved.value,
                interviewResult.value ?? 'neutral', phase, hits.value));
      case StagePhase.done:
        body = const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: NSPTheme.darkStage,
      body: SafeArea(
        child: Column(
          children: [
            _StageHeader(state, phase.value),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  ShowResult _computeResult(CareerState s, int hits, int lyricSaved,
      String interview, Object _, int __) {
    // NSS match rating mantığı: performans bileşenleri puan oluşturur
    final rhythmPct = hits / 16;
    final lyricPct = lyricSaved / 9;
    final interviewBonus =
        interview == 'good' ? 0.15 : interview == 'neutral' ? 0.05 : -0.10;
    final divaPenalty = s.style == StageStyle.diva ? -0.05 : 0.0;
    double raw =
        rhythmPct * 0.5 + lyricPct * 0.3 + s.hype / 100 * 0.15;
    raw += interviewBonus + divaPenalty;
    final score = (raw.clamp(0, 1) * 100).round();

    final viral = (score * 3 + s.hype ~/ 4).round();
    final money = 100 + score * 8 + s.stage.level * 150;
    final voiceCost = s.style == StageStyle.diva ? 35 : 25;

    String headline;
    int hypeChange;
    if (score >= 85) {
      headline = 'AYŞE SAHNEYİ YAKTI! TikTok trendleri 1 numaraya yerleşti';
      hypeChange = 15;
    } else if (score >= 60) {
      headline = 'Güçlü gece: Ayşe\'den hatasız performans';
      hypeChange = 6;
    } else if (score >= 35) {
      headline = 'Karışık gece: hayranlar beklediğini bulamadı';
      hypeChange = -4;
    } else {
      headline = 'FELAKET: Teleprompter krizi trend oldu — "Ayşe kim?"';
      hypeChange = -14;
    }

    final relations = <String, int>{
      'manager': interview == 'good' ? 8 : interview == 'bad' ? -10 : 0,
      'fans': score >= 60 ? 6 : -8,
      'sponsor': interview == 'good' ? 5 : interview == 'bad' ? -6 : 0,
      'media': interview == 'bad' ? -8 : 3,
    };
    return ShowResult(
      score: score,
      applause: score * 40 + viral * 10,
      viralGain: viral,
      moneyEarned: money,
      voiceCost: voiceCost,
      hypeChange: hypeChange,
      headline: headline,
      relationChanges: relations,
    );
  }

  int _bpmForStage(CareerStage stage) =>
      switch (stage) {
        CareerStage.barSahnesi => 85,
        CareerStage.tvSecme => 95,
        CareerStage.ulusalSahne => 105,
        CareerStage.turne => 115,
        CareerStage.avrupa => 120,
        CareerStage.worldTour => 130,
      };
}

class _StageHeader extends StatelessWidget {
  final CareerState state;
  final StagePhase phase;
  const _StageHeader(this.state, this.phase);

  String _label() => switch (phase) {
        StagePhase.intro => 'SAHNEYE HAZIRLANIYOR...',
        StagePhase.rhythm => 'KORO BÖLÜMÜ — RİTİM TUT',
        StagePhase.spotlight => 'BRIDGE — SPOTLIGHT KİMDE?',
        StagePhase.lyrics => 'KRİZ — SÖZLERİ KURTAR',
        StagePhase.interview => 'POST-SHOW — TALK SHOW',
        StagePhase.finale => 'KUTLAMA ANI',
        StagePhase.done => 'SAHNE BİTTİ',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: NSPTheme.darkCard,
        border: Border(
            bottom: BorderSide(color: NSPTheme.neonPink.withValues(alpha: 0.4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('${state.stage.label} — ${_label()}',
                  style: const TextStyle(
                      color: NSPTheme.neonPink, fontSize: 13,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.favorite,
                  color: Colors.redAccent, size: 16),
              const SizedBox(width: 4),
              Text('${state.voice}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              const Icon(Icons.whatshot,
                  color: NSPTheme.stageGold, size: 16),
              const SizedBox(width: 4),
              Text('${state.hype}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Intro extends HookConsumerWidget {
  final WidgetRef ref;
  final VoidCallback onStart;
  const _Intro({required this.ref, required this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final styleChoice = useState(state.style);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('TONIGHT',
            style: TextStyle(
                color: NSPTheme.stageGold, fontSize: 42,
                fontWeight: FontWeight.w900, letterSpacing: 6)),
        const SizedBox(height: 4),
        Text(state.stage.label.toUpperCase(),
            style: const TextStyle(
                color: NSPTheme.neonCyan, fontSize: 16, letterSpacing: 4)),
        const SizedBox(height: 28),
        const Text('Sahne stilini seç (NSS play style karşılığı)',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 10),
        Row(
          children: StageStyle.values.map((s) {
            final selected = styleChoice.value == s;
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    ref.read(careerProvider.notifier).setStyle(s),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? NSPTheme.neonPink.withValues(alpha: 0.2)
                        : NSPTheme.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selected
                            ? NSPTheme.neonPink
                            : NSPTheme.neonPurple.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              color: selected
                                  ? NSPTheme.neonPink
                                  : Colors.white70,
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(s.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: state.voice > 20 ? onStart : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: NSPTheme.neonPink,
            padding: const EdgeInsets.symmetric(horizontal: 40,
                vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25)),
          ),
          child: const Text('SAHNEYİ AÇ',
              style: TextStyle(fontSize: 17, letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        if (state.voice <= 20)
          const Text('Ses sağlığın çok düşük! Önce prova veya dinlenme yap.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12)),
      ],
    );
  }
}

class _Finale extends HookConsumerWidget {
  final WidgetRef ref;
  final ValueChanged<String> onCelebrate;
  final ShowResult showResult;
  const _Finale({
    required this.ref,
    required this.onCelebrate,
    required this.showResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (state bu ekranda doğrudan kullanılmaz)
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${showResult.score}/100',
            style: TextStyle(
                color: showResult.score >= 60
                    ? NSPTheme.stageGold
                    : Colors.redAccent,
                fontSize: 56, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(14),
          decoration: NSPTheme.card(),
          child: Text(showResult.headline,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.4)),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: [
            _ResultLine('Applause', '+${showResult.applause}',
                NSPTheme.neonCyan),
            _ResultLine('Hype',
                '${showResult.hypeChange > 0 ? '+' : ''}${showResult.hypeChange}',
                NSPTheme.stageGold),
            _ResultLine('Kazanç', '+${showResult.moneyEarned} ₺',
                Colors.greenAccent),
            _ResultLine('Ses', '-${showResult.voiceCost}',
                Colors.redAccent),
          ],
        ),
        const SizedBox(height: 22),
        const Text('Konser bitti! Nasıl kutluyorsun? (NSS celebration)',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CelebBtn('Gruba sarıl', 'Grup +8', NSPTheme.neonCyan,
                  () => onCelebrate('group')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CelebBtn('Hayranlara koş', 'Fanbase +10',
                  NSPTheme.stageGold, () => onCelebrate('fans')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CelebBtn('Kameraya poz', 'Şöhret +12',
                  NSPTheme.neonPink, () => onCelebrate('camera')),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultLine(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 12)),
        Text(value, style: TextStyle(color: color,
            fontSize: 17, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CelebBtn extends StatelessWidget {
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _CelebBtn(this.title, this.sub, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color,
                fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(
                color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
