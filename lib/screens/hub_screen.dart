import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../ui/stage_theme.dart';
import '../ui/particles.dart';
import '../core/career_model.dart';
import '../core/career_provider.dart';
import '../games/stage_flow.dart';
import '../games/dilemma_screen.dart';
import '../games/rhythm_game.dart';

/// Ana kariyer ekranı — NSS hub karşılığı
/// Statlar, grup üyeleri, ilişkiler, aksiyonlar (sahne, prova, şarkı öğrenme,
/// hayran kulübü, sezon sonu, emeklilik) burada.
class HubScreen extends HookConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final burstController = useMemoized(() => BurstController());
    final stageKey = useState(0);

    void goStage() {
      Navigator.of(context).push(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => StageFlow(key: ValueKey(stageKey.value)),
          transitionsBuilder: (_, anim, __, child) {
            return SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ),
      ).then((_) {
        stageKey.value += 1;
      });
    }

    void openTraining() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrainingScreen()),
      );
    }

    void openLearnSongs() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LearnSongsScreen()),
      );
    }

    void openDilemma(String kind) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DilemmaScreen(
            kind: kind,
            headlineGenerator: (choice) => _headlineFor(state, choice),
          ),
        ),
      );
    }

    void openFanClub() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FanClubScreen()),
      );
    }

    void openSeasonEnd() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SeasonEndScreen()),
      );
    }

    void openRetire() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const RetireScreen()),
      );
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: CustomScrollView(
          slivers: [
            // başlık bandı
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [StageTheme.bgDeep, StageTheme.bgMid],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('🎤 ${state.playerName}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: StageTheme.neonGold.withValues(alpha: 0.15),
                            border: Border.all(color: StageTheme.neonGold.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('⭐ ${state.careerScore}',
                              style: const TextStyle(
                                  color: StageTheme.neonGold, fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.isGirlBand ? "GIRL BAND" : "BOY BAND"} • Sezon ${state.season} • '
                      '${CareerStage.values[_currentStageLevel(state) - 1].label}',
                      style: TextStyle(color: StageTheme.textSub, fontSize: 11),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MiniStat('HYPE', state.hype, StageTheme.neonPink),
                        const SizedBox(width: 8),
                        _MiniStat('SES', state.voice,
                            state.voice < 25 ? Colors.redAccent : StageTheme.neonCyan),
                        const SizedBox(width: 8),
                        _MiniStat('ŞÖHRET', (state.fame / 10).round(), StageTheme.neonPurple),
                        const SizedBox(width: 8),
                        _MiniStat('₺', state.money, StageTheme.neonGold),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // üyeler
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: const Text('GRUP ÜYELERİ',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                        letterSpacing: 3, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: state.members.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _MemberChip(state.members[i]),
                ),
              ),
            ),

            // ilişkiler
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: const Text('İLİŞKİLER',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                        letterSpacing: 3, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _RelRow('MENAJER', state.managerRelation, StageTheme.neonCyan),
                    const SizedBox(height: 5),
                    _RelRow('HAYRANLAR', state.fansRelation, StageTheme.neonPink),
                    const SizedBox(height: 5),
                    _RelRow('SPONSOR', state.sponsorRelation, StageTheme.neonGold),
                    const SizedBox(height: 5),
                    _RelRow('MEDYA', state.mediaRelation, StageTheme.neonPurple),
                  ],
                ),
              ),
            ),

            // aksiyonlar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: const Text('AKSİYONLAR',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                        letterSpacing: 3, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    NeonButton(
                      label: '🎤 SAHNEYE ÇIK',
                      color: StageTheme.neonPink,
                      width: double.infinity,
                      enabled: state.voice >= 15,
                      onTap: goStage,
                    ),
                    if (state.voice < 15)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Text('Sesiniz çok yorgun — önce dinlen veya prova yap!',
                            style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(label: '🎶 PROVA', color: StageTheme.neonCyan,
                              enabled: state.voice >= 8, onTap: openTraining),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeonButton(label: '📝 ŞARKI ÖĞREN',
                              color: StageTheme.neonPurple, onTap: openLearnSongs),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(label: '🍾 GECE KULÜBÜ',
                              color: Colors.redAccent, onTap: () => openDilemma('nightClub')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeonButton(label: '🤫 GİZLİ TEKLİF',
                              color: StageTheme.neonGold, onTap: () => openDilemma('secretOffer')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(label: '💖 HAYRAN ETKİNLİĞİ',
                              color: StageTheme.neonPink,
                              onTap: () => openDilemma('socialMedia')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeonButton(label: '😴 DİNLEN',
                              color: StageTheme.neonPurple, onTap: () => openDilemma('rest')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // kariyer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: const Text('KARİYER',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                        letterSpacing: 3, fontWeight: FontWeight.w700)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(label: '📈 SEZON SONU',
                              color: StageTheme.neonCyan, onTap: openSeasonEnd),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NeonButton(label: '👥 HAYRAN KULÜBÜ',
                              color: StageTheme.neonGold, onTap: openFanClub),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    NeonButton(
                      label: '🎭 SOLO KARİYERE GEÇ (EMEKİLİ)',
                      color: StageTheme.neonPurple,
                      width: double.infinity,
                      onTap: openRetire,
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),

            // skandallar
            if (state.scandals.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MAGAZİN',
                          style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                              letterSpacing: 3, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...state.scandals.map((s) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.08),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(s, style: const TextStyle(
                                color: Color(0xFFFF8A8A), fontSize: 12)),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _headlineFor(CareerState s, String choice) {
    if (choice == 'acceptOffer') {
      return 'SAZINTI: ${s.playerName} rakip şirkete gizlice görüşmüş!';
    }
    return '';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9.5,
                letterSpacing: 1, fontWeight: FontWeight.w700)),
            Text('$value',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _RelRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _RelRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: color, fontSize: 10.5,
              letterSpacing: 1, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(child: NeonBar(progress: value / 100, color: color, height: 6)),
        const SizedBox(width: 8),
        Text('$value', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  final BandMember m;
  const _MemberChip(this.m);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: m.color.withValues(alpha: 0.4)),
      ),
      child: FittedBox(
      child: Column(
        children: [
          Avatar(emoji: m.emoji, name: m.name.split(' ').first, ringColor: m.color, size: 34),
          const SizedBox(height: 3),
          Text(m.name.split(' ').first, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          SizedBox(width: 62, child: NeonBar(progress: m.relationship / 100, color: m.color, height: 4)),
          const SizedBox(height: 2),
          Text('${m.relationship}', style: TextStyle(color: m.color, fontSize: 9)),
        ],
      ),
      ),
    );
  }
}

// ============================================================
// Ara ekranlar
// ============================================================

class TrainingScreen extends HookConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final result = useState<TrainingResult?>(null);
    final showGame = useState(false);

    void finish(int success, int total) {
      ref.read(careerProvider.notifier).trainingResult(success, total);
      result.value = TrainingResult(success, total);
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('PROVA', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: showGame.value && state.voice >= 8
          ? RhythmGame(
              bpm: 95,
              noteCount: 10,
              onFinish: (hits, total) {
                finish(hits, total);
                showGame.value = false;
              },
            )
          : result.value != null
              ? _ResultView(
                  title: '${result.value!.stars} YILDIZ',
                  body: '+${result.value!.stars * 2} şöhret, ses -10',
                  color: StageTheme.neonCyan,
                )
              : _StartView(
                  title: 'RİTİM PROVASI',
                  body: '16 nota çal. Notaları hedef çizgisinde yakala.\nSes: ${state.voice}',
                  color: StageTheme.neonCyan,
                  enabled: state.voice >= 8,
                  onTap: () => showGame.value = true,
                ),
    );
  }
}

class LearnSongsScreen extends HookConsumerWidget {
  const LearnSongsScreen({super.key});

  static const _songs = [
    ('Beni Affet', 'Pop balad'),
    ('Ateş Dansı', 'Trap-pop'),
    ('Yaz Gecesi', 'Dance-pop'),
    ('Kalp Hırsızı', 'Arabesk-pop'),
    ('Sahne Benim', 'Rap-pop'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final learned = useState<List<String>>([]);

    void learn(String song) {
      if (learned.value.contains(song)) return;
      learned.value = [...learned.value, song];
      ref.read(careerProvider.notifier).learnSong(song);
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ŞARKI ÖĞREN', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ..._songs.map((s) {
              final isLearned = state.learnedSongs.contains(s.$1) || learned.value.contains(s.$1);
              return GestureDetector(
                onTap: () => learn(s.$1),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isLearned
                        ? StageTheme.neonGold.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLearned
                          ? StageTheme.neonGold
                          : StageTheme.neonPurple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(isLearned ? '✓ ' : '♪ ',
                          style: TextStyle(color: isLearned ? StageTheme.neonGold : StageTheme.neonPurple,
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1, style: const TextStyle(color: Colors.white,
                                fontSize: 14, fontWeight: FontWeight.w700)),
                            Text(s.$2, style: TextStyle(color: StageTheme.textSub, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(isLearned ? 'EZBERDE' : 'TAP',
                          style: TextStyle(
                              color: isLearned ? StageTheme.neonGold : StageTheme.neonCyan,
                              fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class FanClubScreen extends HookConsumerWidget {
  const FanClubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final collected = useState(false);
    final income = (state.fame ~/ 10) + 50;

    void collect() {
      if (collected.value) return;
      collected.value = true;
      ref.read(careerProvider.notifier).addFanClubIncome();
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('HAYRAN KULÜBÜ', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [StageTheme.neonPink.withValues(alpha: 0.2),
                           StageTheme.neonPurple.withValues(alpha: 0.12)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StageTheme.neonPink.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💖 Abonelik Geliri (NSS at yarışı karşılığı)',
                      style: TextStyle(color: StageTheme.textSub, fontSize: 11)),
                  const SizedBox(height: 8),
                  Text('+₺$income',
                      style: TextStyle(color: StageTheme.neonGold,
                          fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  const Text('Şöhret puanına göre gelir. Her sezon toplanabilir.',
                      style: TextStyle(color: StageTheme.textSub, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: collected.value ? '✓ BU SEZON TOPLANDI' : 'GELİRİ TOPLA',
              color: StageTheme.neonGold,
              width: double.infinity,
              enabled: !collected.value,
              onTap: collect,
            ),
          ],
        ),
      ),
    );
  }
}

class SeasonEndScreen extends HookConsumerWidget {
  const SeasonEndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final currentLevel = _currentStageLevel(state);
    final nextLevel = currentLevel + 1;
    final canRise = nextLevel <= CareerStage.values.length;
    final result = useState<SeasonResult?>(null);

    void decide(bool rise) {
      ref.read(careerProvider.notifier).seasonEnd();
      result.value = SeasonResult(rise);
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SEZON SONU', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (result.value == null) ...[
              const Text('Sahne seviyen',
                  style: TextStyle(color: StageTheme.textSub, fontSize: 12)),
              const SizedBox(height: 6),
              Text(CareerStage.values[currentLevel - 1].label,
                  style: TextStyle(color: StageTheme.neonPurple, fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              NeonButton(
                label: canRise ? '⬆ KONTRAT YÜKSELT' : 'SEVİYEDEN KAL',
                color: canRise ? StageTheme.neonCyan : StageTheme.neonPurple,
                width: double.infinity,
                enabled: canRise && state.hype >= 40,
                onTap: () => decide(true),
              ),
              if (canRise && state.hype < 40)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Kontrat yükseltmek için hype ≥ 40 gerekli.',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),
              const SizedBox(height: 10),
              NeonButton(
                label: '⬇ KONTRAT DÜŞÜR (Hi-Lo Negotiation)',
                color: StageTheme.neonGold,
                width: double.infinity,
                onTap: () => decide(false),
              ),
            ] else
              _ResultView(
                title: result.value!.rose ? 'KONTRAT YÜKSELDİ!' : 'SEVİYEDEN KALDIN',
                body: 'Sonraki sezon tekrar dene.',
                color: result.value!.rose ? StageTheme.neonCyan : StageTheme.neonGold,
              ),
          ],
        ),
      ),
    );
  }
}

class RetireScreen extends HookConsumerWidget {
  const RetireScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final done = useState(false);

    void retire() {
      ref.read(careerProvider.notifier).retire();
      done.value = true;
    }

    if (done.value) {
      return Scaffold(
        backgroundColor: StageTheme.bgDeep,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
                const Text('EFSANE SKORU',
                    style: TextStyle(color: StageTheme.neonGold, fontSize: 12, letterSpacing: 3)),
                const SizedBox(height: 8),
                Text('${state.careerScore}',
                    style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                NeonButton(label: 'YENİ KARİYER', color: StageTheme.neonPink,
                    width: double.infinity,
                    onTap: () {
                      ref.read(careerProvider.notifier)
                          .newCareer(name: state.playerName, isGirlBand: state.isGirlBand);
                      Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HubScreen()));
                    }),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SOLO KARİYER / EMEKLİLİK', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grup ile kariyerine veda edip solo kariyere geçersin.\nKariyer skoru hesaplanır ve oyun sıfırlanır.',
                style: TextStyle(color: StageTheme.textSub, fontSize: 13)),
            const SizedBox(height: 20),
            NeonButton(
              label: '🎭 SOLO KARİYERE GEÇ',
              color: StageTheme.neonPurple,
              width: double.infinity,
              onTap: retire,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartView extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _StartView({required this.title, required this.body, required this.color,
      required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 22,
              fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 28),
          NeonButton(label: 'BAŞLA', color: color, width: double.infinity,
              enabled: enabled, onTap: onTap),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  const _ResultView({required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(body, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
          const SizedBox(height: 24),
          NeonButton(
            label: 'GERİ DÖN',
            color: color,
            width: double.infinity,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class TrainingResult {
  final int stars;
  final int success;
  final int total;
  TrainingResult(this.success, this.total)
      : stars = success >= total - 1 ? 3 : success >= total - 2 ? 2 : 1;
}

class SeasonResult {
  final bool rose;
  SeasonResult(this.rose);
}

int _currentStageLevel(CareerState state) {
  return ((state.fame ~/ 180) + 1).clamp(1, CareerStage.values.length);
}
