import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';

/// Şarkı Sözü Ezberleme — NSS "frikik krizi" karşılığı
/// Teleprompter arızalanır; kelimeler grid'de dağınık durur.
/// Şarkının sırasına göre doğru kelimeye TAP yapılır.
/// Aktif kelime altın çerçeve ile vurgulanır; doğru tap patlama, yanlış tap sarsılma.
class LyricsGame extends HookWidget {
  final List<String> lyricWords;
  final Function(int correct, int total) onFinish;

  const LyricsGame({
    super.key,
    required this.lyricWords,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return ParticleOverlay(child: _LyricsBody(lyricWords: lyricWords, onFinish: onFinish));
  }
}

class _WordTile {
  String word;
  int index; // orijinal sırada pozisyon
  int gridRow;
  int gridCol;
  bool saved = false;
  bool wrongTap = false;
  _WordTile({required this.word, required this.index, required this.gridRow, required this.gridCol});
}

class _LFeedback {
  final String text;
  final Color color;
  _LFeedback(this.text, this.color);
}

class _LyricsBody extends HookWidget {
  final List<String> lyricWords;
  final Function(int correct, int total) onFinish;

  const _LyricsBody({required this.lyricWords, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final tiles = useState<List<_WordTile>>([]);
    final activeIdx = useState(0);
    final savedCount = useState(0);
    final started = useState(false);
    final feedback = useState<_LFeedback?>(null);
    final feedbackKey = useState(0);
    final timeLeft = useState(10.0);
    final done = useState(false);
    final burstController = useMemoized(() => BurstController());

    const playTime = 15.0; // saniye
    const wordTime = 1.6; // kelime başına bonus süre

    // kelimeleri rastgele grid'e dağıt
    useEffect(() {
      final rng = Random(99);
      final total = lyricWords.length;
      final cols = 3;
      final positions = List.generate(total, (i) => i);
      positions.shuffle(rng);

      tiles.value = [
        for (var i = 0; i < total; i++)
          _WordTile(
            word: lyricWords[i],
            index: i,
            gridRow: positions[i] ~/ cols,
            gridCol: positions[i] % cols,
          ),
      ];
      Future.delayed(const Duration(milliseconds: 250), () => started.value = true);
      return null;
    }, []);

    // süre sayacı
    useEffect(() {
      if (!started.value) return null;
      Timer? t;
      final deadline = DateTime.now().millisecondsSinceEpoch + (playTime * 1000).round();
      t = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = (deadline - DateTime.now().millisecondsSinceEpoch) / 1000;
        if (remaining <= 0) {
          t?.cancel();
          if (!done.value) {
            done.value = true;
            onFinish(savedCount.value, lyricWords.length);
          }
          return;
        }
        timeLeft.value = remaining;
      });
      return () => t?.cancel();
    }, [started.value]);

    void tapWord(_WordTile tile) {
      if (tile.saved || done.value) return;
      if (tile.index == activeIdx.value) {
        // DOĞRU kelime
        tile.saved = true;
        savedCount.value += 1;
        activeIdx.value += 1;
        timeLeft.value = (timeLeft.value + wordTime - 0.3).clamp(0, playTime);
        final size = MediaQuery.sizeOf(context);
        final cellW = size.width / 3.4;
        final cellH = 92.0;
        burstController.burst(
          tile.gridCol * cellW + cellW / 2,
          130 + tile.gridRow * cellH + cellH / 2,
          count: 18,
          speed: 7,
          palette: [StageTheme.neonGold, Colors.white],
        );
        feedback.value = _LFeedback('DOĞRU', StageTheme.neonGold);
        feedbackKey.value += 1;
        if (savedCount.value >= lyricWords.length) {
          done.value = true;
          Future.delayed(const Duration(milliseconds: 350), () {
            onFinish(savedCount.value, lyricWords.length);
          });
        }
      } else {
        // YANLIŞ kelime — sarsılma + feedback
        tile.wrongTap = true;
        feedback.value = _LFeedback('SIRASI BUNUN DEĞİL!', Colors.redAccent);
        feedbackKey.value += 1;
        timeLeft.value = (timeLeft.value - 0.5).clamp(0, playTime);
        Future.delayed(const Duration(milliseconds: 450), () {
          tile.wrongTap = false;
        });
      }
    }

    final total = lyricWords.length;
    final cols = 3;
    final rows = (total / cols).ceil();

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: Stack(
          children: [
            const StageBackdrop(beamCount: 3, floor: false),

            // üst HUD
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _LyricHudChip('${savedCount.value}/$total KELİME', StageTheme.neonGold),
                  const Spacer(),
                  _LyricHudChip('${timeLeft.value.toStringAsFixed(1)}s',
                      timeLeft.value < 5 ? Colors.redAccent : StageTheme.neonCyan),
                ],
              ),
            ),

            // süre barı
            Positioned(
              top: 92,
              left: 16,
              right: 16,
              child: NeonBar(
                progress: timeLeft.value / playTime,
                color: timeLeft.value < 5 ? Colors.redAccent : StageTheme.neonCyan,
                height: 8,
              ),
            ),

            // telkprompter şeridi (arızalı)
            Positioned(
              top: 118,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.signal_wifi_off, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'TELEPROMPTER ARIZASI! Kelimeleri sırasıyla kurtar!',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // kelime grid'i
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: List.generate(rows, (r) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(cols, (c) {
                        final tile = tiles.value
                            .cast<_WordTile?>()
                            .where((_WordTile? t) => t != null && t.gridRow == r && t.gridCol == c)
                            .firstOrNull;
                        if (tile == null) {
                          return const SizedBox(width: 106, height: 90);
                        }
                        final isActive = tile.index == activeIdx.value;
                        return GestureDetector(
                          onTap: () => tapWord(tile),
                          child: Container(
                            width: 100,
                            height: 86,
                            margin: const EdgeInsets.all(6),
                            transform: tile.wrongTap
                                ? (Matrix4.identity()..translate(5.0))
                                : null,
                            decoration: BoxDecoration(
                              color: tile.saved
                                  ? StageTheme.neonGold.withValues(alpha: 0.12)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: tile.saved
                                    ? StageTheme.neonGold
                                    : isActive
                                        ? StageTheme.neonGold
                                        : Colors.white24,
                                width: isActive ? 2.5 : 1.2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: StageTheme.neonGold.withValues(alpha: 0.5),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      tile.word,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: tile.saved ? StageTheme.neonGold : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        decoration:
                                            tile.saved ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ),
                                if (tile.saved)
                                  const Positioned(
                                    right: 4,
                                    top: 2,
                                    child: Icon(Icons.check_circle,
                                        color: StageTheme.neonGold, size: 15),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ),
              ),
            ),

            // feedback
            if (feedback.value != null)
              Positioned(
                top: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: BigFeedback(feedback.value!.text, color: feedback.value!.color, size: 26),
                ),
              ),

            // alt talimat
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Parlayan altın çerçeveli kelimeye tap et!',
                  style: TextStyle(color: StageTheme.textSub, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricHudChip extends StatelessWidget {
  final String text;
  final Color color;
  const _LyricHudChip(this.text, this.color);

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
