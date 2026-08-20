import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';
import '../core/career_provider.dart';

// ============================================================
// SPOTLIGHT PAYLAŞIMI — NSS "pas seçimi" karşılığı
// Bridge bölümünde spotlight senin. Karar süresi 6 sn:
//   - Bir üyeye pasla → o üye mutlu, grup uyumu artar
//   - Süre dolarsa pas verilmedi → grup üzüldü
// ============================================================

class SpotlightGame extends HookWidget {
  final Function(Map<String, dynamic> result) onFinish;

  const SpotlightGame({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return ParticleOverlay(child: _SpotlightBody(onFinish: onFinish));
  }
}

class _SpotlightBody extends HookConsumerWidget {
  final Function(Map<String, dynamic> result) onFinish;

  const _SpotlightBody({required this.onFinish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(careerProvider).members;
    final selected = useState<int?>(null);
    final timeLeft = useState(6.0);
    final started = useState(false);
    final done = useState(false);
    final burstController = useMemoized(() => BurstController());

    const decisionTime = 6.0;

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () => started.value = true);
      return null;
    }, []);

    useEffect(() {
      if (!started.value) return null;
      Timer? t;
      final deadline = DateTime.now().millisecondsSinceEpoch + (decisionTime * 1000).round();
      t = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = (deadline - DateTime.now().millisecondsSinceEpoch) / 1000;
        if (remaining <= 0) {
          t?.cancel();
          if (!done.value) {
            done.value = true;
            onFinish({'picked': -1});
          }
          return;
        }
        timeLeft.value = remaining;
      });
      return () => t?.cancel();
    }, [started.value]);

    void pickMember(int index) {
      if (done.value || selected.value != null) return;
      done.value = true;
      selected.value = index;
      final size = MediaQuery.sizeOf(context);
      burstController.burst(size.width / 2, 300, count: 30, speed: 8,
          palette: [members[index].color, Colors.white]);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!done.value) return;
        onFinish({'picked': index});
      });
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: Stack(
          children: [
            const StageBackdrop(beamCount: 4, floor: true),

            // başlık
            Positioned(
              top: 44,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    '✦ BRIDGE BÖLÜMÜ ✦',
                    style: TextStyle(
                        color: StageTheme.textSub, fontSize: 12, letterSpacing: 4,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Spotlight senin! Bir üyeye pas ver ve onu öne çıkar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 15, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 10),
                  NeonBar(
                    progress: timeLeft.value / decisionTime,
                    color: timeLeft.value < 3 ? Colors.redAccent : StageTheme.neonCyan,
                    height: 6,
                  ),
                ],
              ),
            ),

            // üye kartları
            Positioned(
              top: 230,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(members.length, (i) {
                  final m = members[i];
                  final isPicked = selected.value == i;
                  return GestureDetector(
                    onTap: () => pickMember(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar(
                          emoji: m.emoji,
                          name: m.name,
                          ringColor: m.color,
                          size: isPicked ? 96 : 80,
                        ),
                        const SizedBox(height: 10),
                        Text(m.role,
                            style: TextStyle(color: StageTheme.textSub, fontSize: 11)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: m.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPicked ? m.color : m.color.withValues(alpha: 0.45),
                              width: isPicked ? 2 : 1,
                            ),
                            boxShadow: isPicked
                                ? [BoxShadow(color: m.color.withValues(alpha: 0.55), blurRadius: 14)]
                                : null,
                          ),
                          child: Text(
                            isPicked ? 'PAS VERDİN!' : 'TAP',
                            style: TextStyle(
                                color: isPicked ? Colors.white : m.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // sahne ışık efekti (alt)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      StageTheme.neonPurple.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TALK SHOW RÖPORTAJI — NSS "basın toplantısı" karşılığı
// Sunucu soru sorar; 3 cevap seçeneğinden biri seçilir.
// Her cevap farklı ilişki kombinasyonu üretir.
// ============================================================

class InterviewGame extends HookWidget {
  final String question;
  final List<InterviewAnswer> answers;
  final Function(InterviewAnswer picked) onFinish;

  const InterviewGame({
    super.key,
    required this.question,
    required this.answers,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return ParticleOverlay(child: _InterviewBody(
      question: question, answers: answers, onFinish: onFinish,
    ));
  }
}

class InterviewAnswer {
  final String label;
  final String effectLabel; // örn: "Hayranlar +10 / Medya -5"
  final Map<String, int> relationDeltas;
  InterviewAnswer({required this.label, required this.effectLabel, required this.relationDeltas});

  String get text => label;
}

class _InterviewBody extends HookWidget {
  final String question;
  final List<InterviewAnswer> answers;
  final Function(InterviewAnswer picked) onFinish;

  const _InterviewBody({required this.question, required this.answers, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final timeLeft = useState(8.0);
    final started = useState(false);
    final done = useState(false);

    const decisionTime = 8.0;

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 200), () => started.value = true);
      return null;
    }, []);

    useEffect(() {
      if (!started.value) return null;
      Timer? t;
      final deadline = DateTime.now().millisecondsSinceEpoch + (decisionTime * 1000).round();
      t = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final remaining = (deadline - DateTime.now().millisecondsSinceEpoch) / 1000;
        if (remaining <= 0) {
          t?.cancel();
          if (!done.value) {
            done.value = true;
            onFinish(answers.last); // süre dolarsa güvenli cevap
          }
          return;
        }
        timeLeft.value = remaining;
      });
      return () => t?.cancel();
    }, [started.value]);

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: Stack(
        children: [
          const StageBackdrop(beamCount: 2, floor: false),

          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    // sunucu avatarı
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: StageTheme.neonGold, width: 2),
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: Text('🎙', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StageTheme.neonGold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          question,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14.5, height: 1.3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                NeonBar(
                  progress: timeLeft.value / decisionTime,
                  color: timeLeft.value < 3 ? Colors.redAccent : StageTheme.neonCyan,
                  height: 6,
                ),
              ],
            ),
          ),

          // cevap kartları
          Positioned(
            top: 170,
            left: 16,
            right: 16,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('CEVABINI SEÇ',
                      style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                          letterSpacing: 3, fontWeight: FontWeight.w700)),
                ),
                ...List.generate(answers.length, (i) {
                  final a = answers[i];
                  return GestureDetector(
                    onTap: () {
                      if (done.value) return;
                      done.value = true;
                      onFinish(a);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: StageTheme.neonCyan.withValues(alpha: 0.7)),
                            ),
                            child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(color: StageTheme.neonCyan,
                                      fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(a.text,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14, height: 1.3)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
