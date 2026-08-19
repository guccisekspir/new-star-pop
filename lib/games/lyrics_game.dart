import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/theme.dart';

/// Şarkı Sözü Ezberleme — NSS "serbest vuruş" karşılığı (kriz anları)
/// Teleprompter arızası simülasyonu: kelimeler hızla kaybolur,
/// sırasıyla tap'leyerek şarkıyı tamamlaman gerekir.
class LyricsGame extends HookConsumerWidget {
  final List<String> words; // şarkının sözleri
  final int wordFadeMs; // kelimenin kaybolma hızı (zorluk)
  final ValueChanged<int> onFinish; // kaç kelime kurtarıldı

  const LyricsGame({
    super.key,
    required this.words,
    this.wordFadeMs = 1600,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = useState<Set<int>>({});
    final expired = useState<Set<int>>({});
    final timers = useState<List<Timer?>>(List.filled(60, null));
    final now = DateTime.now().millisecondsSinceEpoch;

    // her kelime için kaybolma zamanlayıcısı
    useEffect(() {
      for (var i = 0; i < words.length; i++) {
        timers.value[i] = Timer(Duration(milliseconds: wordFadeMs * (i + 1)),
            () {
          if (!found.value.contains(i)) {
            expired.value = {...expired.value, i};
          }
        });
      }
      // oyun sonu
      final end = Timer(
          Duration(milliseconds: wordFadeMs * (words.length + 1)), () {
        onFinish(found.value.length);
      });
      return () {
        timers.value.whereType<Timer>().forEach((t) => t.cancel());
        end.cancel();
      };
    }, []);

    final saved = found.value.length;
    final lost = expired.value.length;

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 500 ? 4 : 3;
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('⚡ TELEPROMPTER ARIZASI ⚡',
                style: TextStyle(
                    color: NSPTheme.stageGold, fontSize: 18,
                    fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(height: 6),
          const Text('Kelimeler kaybolmadan sırasıyla tap\'le!',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Chip('$saved KURTARILDI', NSPTheme.neonCyan),
                _Chip('$lost KAÇTI', Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(words.length, (i) {
                  final isFound = found.value.contains(i);
                  final isExpired = expired.value.contains(i);
                  final isNext = i ==
                      (found.value.isEmpty
                          ? 0
                          : found.value.last + 1);
                  return AnimatedOpacity(
                    opacity: isExpired ? 0.2 : 1,
                    duration: const Duration(milliseconds: 400),
                    child: GestureDetector(
                      onTap: () {
                        if (isExpired || isFound) return;
                        if (!isNext) {
                          // yanlış sıra: hata feedback'i
                          return;
                        }
                        found.value = {...found.value, i};
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFound
                              ? NSPTheme.neonCyan.withValues(alpha: 0.25)
                              : isExpired
                                  ? Colors.transparent
                                  : NSPTheme.darkCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isFound
                                ? NSPTheme.neonCyan
                                : isNext
                                    ? NSPTheme.stageGold
                                    : NSPTheme.neonPurple
                                        .withValues(alpha: 0.4),
                            width: isNext ? 2.5 : 1,
                          ),
                        ),
                        child: Text(
                          words[i],
                          style: TextStyle(
                            color: isFound
                                ? NSPTheme.neonCyan
                                : isNext
                                    ? Colors.white
                                    : Colors.white60,
                            fontSize: 16,
                            fontWeight: isNext
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration:
                                isFound ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 13,
              fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}
