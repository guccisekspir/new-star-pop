import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/theme.dart';

/// Ritim Tutma — NSS "şut anı" karşılığı (koro/solo bölümü)
/// Notalar aşağıdan hedef çizgisine doğru akar; isabet anında swipe/tap yapılır.
class RhythmGame extends HookConsumerWidget {
  final int bpm; // tempo (zorluk)
  final int noteCount;
  final ValueChanged<int> onFinish; // isabet sayısı

  const RhythmGame({
    super.key,
    this.bpm = 90,
    this.noteCount = 16,
    required this.onFinish,
  });

  static const double hitLineY = 120; // hedef çizgisinin ekrandan mesafesi

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = useState<List<_Note>>([]);
    final hits = useState(0);
    final misses = useState(0);
    final feedback = useState<String?>(null);
    final score = useState(0);
    final seed = useState(Random().nextInt(9999));

    // Zamanlayıcı: her beat'te yeni nota üret
    useEffect(() {
      final beatMs = (60000 / bpm).round();
      final spawnTimer = Timer.periodic(Duration(milliseconds: beatMs), (t) {
        if (notes.value.length >= noteCount) {
          t.cancel();
          return;
        }
        // x pozisyonu beat bazında değişir (koro hissi)
        final rand = Random(seed.value + t.tick);
        final x = 0.15 + rand.nextDouble() * 0.7;
        notes.value = [
          ...notes.value,
          _Note(
            id: '${t.tick}',
            x: x,
            spawnedAt: DateTime.now().millisecondsSinceEpoch,
            fallMs: 1800, // notanın yukarıdan hedefe düşme süresi
          ),
        ];
      });

      // Oyun sonu: son nota hedefi geçtikten sonra
      final endTimer = Timer(
          Duration(milliseconds: beatMs * noteCount + 3200), () {
        onFinish(hits.value);
      });

      return () {
        spawnTimer.cancel();
        endTimer.cancel();
      };
    }, []);

    // Her frame'de notaları güncelle (CustomPainter animasyonu)
    final anim = useAnimationController(duration: const Duration(seconds: 10000));
    useEffect(() {
      anim.repeat();
      return null;
    }, [anim]);

    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        painter: _RhythmPainter(
          notes: notes.value,
          hits: hits.value,
          misses: misses.value,
          hitLineFromBottom: hitLineY,
        ),
        size: constraints.biggest,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            // İsabet değerlendirme: hedef çizgisine en yakın notayı bul
            final layoutH = constraints.maxHeight;
            final hitLineYpx = layoutH - hitLineY;
            _Note? nearest;
            double bestDist = 1e9;
            for (final n in notes.value) {
              if (n.hit || n.missed) continue;
              final y = noteY(n, layoutH);
              final dist = (y - hitLineYpx).abs();
              if (dist < bestDist) {
                bestDist = dist;
                nearest = n;
              }
            }
            if (nearest == null) return;

            if (bestDist < 35) {
              nearest!.hit = true;
              hits.value += 1;
              score.value += 10;
              feedback.value = 'PERFECT';
            } else if (bestDist < 80) {
              nearest!.hit = true;
              hits.value += 1;
              score.value += 5;
              feedback.value = 'İYİ';
            } else {
              nearest!.missed = true;
              misses.value += 1;
              feedback.value = 'KAÇTI!';
            }
            // feedback'i kısa süre göster
            Future.delayed(const Duration(milliseconds: 450), () {
              feedback.value = null;
            });
          },
          child: Stack(
            children: [
              // Hedef çizgisi
              Positioned(
                bottom: hitLineY,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: BoxDecoration(
                    color: NSPTheme.neonCyan,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: NSPTheme.neonCyan.withValues(alpha: 0.8),
                          blurRadius: 14),
                    ],
                  ),
                ),
              ),
              // Feedback yazısı
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: feedback.value == null
                      ? const SizedBox.shrink()
                      : HitFeedback(
                          text: feedback.value!,
                          color: feedback.value == 'KAÇTI!'
                              ? Colors.redAccent
                              : NSPTheme.stageGold,
                        ),
                ),
              ),
              // Puan
              Positioned(
                top: 20,
                right: 20,
                child: Text('${score.value} SKOR',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
              ),
              // Kalan / isabet göstergesi
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  '${notes.value.where((n) => n.hit).length}/${notes.value.length}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 16),
                ),
              ),
              // BPM göstergesi
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text('$bpm BPM — KORO BÖLÜMÜ',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13,
                          letterSpacing: 3)),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  double noteY(_Note n, double layoutH) {
    final elapsed =
        DateTime.now().millisecondsSinceEpoch - n.spawnedAt;
    return (elapsed / n.fallMs) * (layoutH + 100) - 50;
  }
}

class _Note {
  final String id;
  final double x; // 0-1
  final int spawnedAt;
  final int fallMs;
  bool hit = false;
  bool missed = false;
  _Note({
    required this.id,
    required this.x,
    required this.spawnedAt,
    required this.fallMs,
  });
}

class _RhythmPainter extends CustomPainter {
  final List<_Note> notes;
  final int hits;
  final int misses;

  final double hitLineFromBottom;

  _RhythmPainter({
    required this.notes,
    required this.hits,
    required this.misses,
    required this.hitLineFromBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final layoutH = size.height;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final n in notes) {
      if (n.hit) continue;
      final elapsed = now - n.spawnedAt;
      final y = (elapsed / n.fallMs) * (layoutH + 100) - 50;
      if (y < -50 || y > layoutH + 50) continue;
      final x = n.x * size.width;

      // Notayı isabet durumuna göre boya
      final isMiss = n.missed && y > layoutH - hitLineFromBottom;
      final noteColor = isMiss ? Colors.redAccent : NSPTheme.neonPink;
      final blurAmount = isMiss ? 2.0 : 8.0;
      final outerPaint = Paint()
        ..color = noteColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurAmount);
      canvas.drawCircle(Offset(x, y), 26, outerPaint);
      canvas.drawCircle(
        Offset(x, y),
        18,
        Paint()..color = isMiss ? Colors.red : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RhythmPainter old) => true;
}
