import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';

/// Ritim tutma mini-oyunu — NSS şut anı karşılığı
/// 4 şerit, beat tabanlı düşen notalar, şerit alanına tap ile değerlendirme.
/// Pencereler: PERFECT <40ms / İYİ <90ms / PAS <140ms / KAÇTI (pencere dışı)
class RhythmGame extends HookWidget {
  final int bpm;
  final int noteCount;
  final Function(int hits, int total) onFinish;
  final Function(double x, double y, List<Color> palette)? onBurst;

  const RhythmGame({
    super.key,
    this.bpm = 110,
    this.noteCount = 14,
    required this.onFinish,
    this.onBurst,
  });

  @override
  Widget build(BuildContext context) {
    final burstController = useMemoized(() => BurstController());
    return ParticleOverlay(
      controller: burstController,
      child: _RhythmBody(
        bpm: bpm,
        noteCount: noteCount,
        onFinish: onFinish,
        onBurst: (x, y, palette) => burstController.burst(x, y, count: 16, speed: 6, palette: palette),
      ),
    );
  }
}

class _Note {
  int lane; // 0..3
  double targetMs; // hedef çizgisine ulaşacağı zaman (ms)
  bool hit = false;
  bool missed = false;
  bool judged = false;
  _Note({required this.lane, required this.targetMs});
}

class _Feedback {
  final String text;
  final Color color;
  _Feedback(this.text, this.color);
}

class _RhythmBody extends HookWidget {
  final int bpm;
  final int noteCount;
  final Function(int hits, int total) onFinish;
  final Function(double x, double y, List<Color> palette)? onBurst;

  const _RhythmBody({
    required this.bpm,
    required this.noteCount,
    required this.onFinish,
    this.onBurst,
  });


  @override
  Widget build(BuildContext context) {
    final notes = useState<List<_Note>>([]);
    final done = useState(false);
    final hits = useState(0);
    final judgedCount = useState(0);
    final combo = useState(0);
    final started = useState(false);
    final startTime = useRef(DateTime.now().millisecondsSinceEpoch);
    final feedback = useState<_Feedback?>(null);
    final feedbackKey = useState(0);
    final laneFlash = useState<List<bool>>([false, false, false, false]);

    // sabitler
    const fallMs = 1200.0; // nota yukarıdan hedefe kaç ms'de iner
    const targetYRatio = 0.78; // hedef çizgisi ekran yüksekliği oranı
    const laneColors = [StageTheme.neonPink, StageTheme.neonCyan, StageTheme.neonGold, StageTheme.neonPurple];
    const hitLabels = ['PERFECT', 'İYİ', 'PAS', 'KAÇTI'];
    const hitColorValues = [StageTheme.neonPurple, StageTheme.neonCyan, StageTheme.neonGold, Colors.redAccent];

    // notaları önceden üret (beat tabanlı + hafif ritmik çeşitlilik)
    useEffect(() {
      final rng = Random(42);
      final beatMs = 60000.0 / bpm;
      final list = <_Note>[];
      var t = 1800.0; // ilk nota 1.8sn sonra
      for (var i = 0; i < noteCount; i++) {
        final gap = (rng.nextDouble() < 0.35 ? 0.5 : 1.0) * beatMs;
        t += gap;
        list.add(_Note(lane: rng.nextInt(4), targetMs: t));
      }
      notes.value = list;
      Future.delayed(const Duration(milliseconds: 300), () => started.value = true);
      return null;
    }, []);

    // game loop (16ms timer ile 60fps ticker)
    useEffect(() {
      if (!started.value) return null;
      final hitWindow = 140.0;
      Timer? ticker;
      ticker = Timer.periodic(const Duration(milliseconds: 16), (t) {
        if (done.value) return;
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsed = now - startTime.value;

        for (final n in notes.value) {
          if (n.judged || n.hit || n.missed) continue;
          final diff = n.targetMs - elapsed;
          if (diff < -hitWindow) {
            n.missed = true;
            n.judged = true;
            judgedCount.value += 1;
            combo.value = 0;
            feedback.value = _Feedback(hitLabels[3], hitColorValues[3]);
            feedbackKey.value += 1;
          }
        }

        if (judgedCount.value >= noteCount) {
          done.value = true;
          ticker?.cancel();
          onFinish(hits.value, noteCount);
        }
      });
      return () => ticker?.cancel();
    }, [started.value]); // end loop

    void judgeLane(int lane) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - startTime.value;

      _Note? nearest;
      double best = double.infinity;
      for (final n in notes.value) {
        if (n.lane != lane || n.judged) continue;
        final d = (n.targetMs - elapsed).abs();
        if (d < best) {
          best = d;
          nearest = n;
        }
      }

      // şeritte nota yok veya çok uzak → boş tap (combo kırmak yok, flash var)
      if (nearest == null) return;
      if (best > 140) return; // çok uzak: değerlendirme

      int tier; // 0 PERFECT, 1 İYİ, 2 PAS
      if (best < 40) {
        nearest.hit = true;
        tier = 0;
      } else if (best < 90) {
        nearest.hit = true;
        tier = 1;
      } else {
        nearest.hit = true;
        tier = 2;
      }
      nearest.judged = true;
      hits.value += 1;
      judgedCount.value += 1;
      combo.value += 1;
      feedback.value = _Feedback(hitLabels[tier], hitColorValues[tier]);
      feedbackKey.value += 1;

      // şerit patlaması + flash
      final size = MediaQuery.sizeOf(context);
      final laneWidth = size.width / 4;
      onBurst?.call(laneWidth * lane + laneWidth / 2, size.height * targetYRatio,
          <Color>[laneColors[lane], Colors.white]);
      laneFlash.value = [lane == 0, lane == 1, lane == 2, lane == 3];
      Future.delayed(const Duration(milliseconds: 180), () {
        laneFlash.value = [false, false, false, false];
      });
    }

    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final elapsed = DateTime.now().millisecondsSinceEpoch - startTime.value;
      final laneWidth = size.width / 4;
      const noteRadius = 22.0;

      return Scaffold(
        backgroundColor: StageTheme.bgDeep,
        body: ParticleOverlay(
          child: Stack(
            children: [
              // sahne backdrop
              const StageBackdrop(beamCount: 4, floor: false),

              // şeritler
              ...List.generate(4, (lane) {
                final flash = laneFlash.value[lane];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => judgeLane(lane),
                  child: Container(
                    margin: EdgeInsets.only(left: laneWidth * lane + 3),
                    width: laneWidth - 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          laneColors[lane].withValues(alpha: flash ? 0.30 : 0.08),
                          laneColors[lane].withValues(alpha: flash ? 0.55 : 0.14),
                        ],
                      ),
                      border: Border.all(color: laneColors[lane].withValues(alpha: 0.45), width: 1),
                      boxShadow: flash
                          ? [BoxShadow(color: laneColors[lane].withValues(alpha: 0.6), blurRadius: 30)]
                          : null,
                    ),
                  ),
                );
              }),

              // notalar
              ...notes.value.map((n) {
                final diff = n.targetMs - elapsed;
                final t = 1 - diff / fallMs; // 0 = en üst, 1 = hedef çizgisi
                if (t < -0.15 || n.hit) return const SizedBox.shrink();
                final y = t * size.height * targetYRatio;
                return Positioned(
                  left: laneWidth * n.lane + (laneWidth - noteRadius * 2) / 2,
                  top: y - noteRadius,
                  child: Opacity(
                    opacity: n.missed ? 0.25 : 1,
                    child: Container(
                      width: noteRadius * 2,
                      height: noteRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: laneColors[n.lane],
                        boxShadow: [
                          BoxShadow(
                            color: laneColors[n.lane].withValues(alpha: 0.75),
                            blurRadius: 18,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.music_note, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                );
              }),

              // hedef çizgisi + halkaları
              Positioned(
                top: size.height * targetYRatio - 2,
                left: 0,
                right: 0,
                child: Row(
                  children: List.generate(4, (lane) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: laneColors[lane],
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: laneColors[lane].withValues(alpha: 0.8),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // üst HUD
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _HudChip('${hits.value}/${noteCount} VURDU', StageTheme.neonCyan),
                    if (combo.value > 1) _ComboChip('${combo.value}x COMBO', StageTheme.neonGold),
                  ],
                ),
              ),

              // feedback metni (merkez üstü)
              if (feedback.value != null)
                Positioned(
                  top: size.height * 0.30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      BigFeedback(
                        feedback.value!.text,
                        color: feedback.value!.color,
                        size: combo.value > 2 ? 54 : 40,
                      ),
                      if (combo.value > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${combo.value}x COMBO!',
                            style: TextStyle(
                              color: StageTheme.neonGold,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                    color: StageTheme.neonGold.withValues(alpha: 0.8),
                                    blurRadius: 18,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // alt talimat
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    'Nota hedef çizgisine ulaşınca şeride TAP!',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _HudChip extends StatelessWidget {
  final String text;
  final Color color;
  const _HudChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class _ComboChip extends StatelessWidget {
  final String text;
  final Color color;
  const _ComboChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.8)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14)],
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w900)),
    );
  }
}
