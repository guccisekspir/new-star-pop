import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/career_provider.dart';
import '../core/career_model.dart';
import '../core/theme.dart';
import '../games/stage_flow.dart';
import '../games/dilemma_screen.dart';
import '../games/rhythm_game.dart';

/// Ana Kariyer Ekranı — NSS ana menü karşılığı
/// Prova → Sahne → İlişkiler → Mağaza → Dilemma → Sezon sonu
class HubScreen extends HookConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(careerProvider);
    final notifier = ref.read(careerProvider.notifier);

    return Scaffold(
      backgroundColor: NSPTheme.darkStage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(state),
              const SizedBox(height: 16),
              _StatsPanel(state),
              const SizedBox(height: 16),
              _RelationsPanel(state),
              const SizedBox(height: 16),
              const Text('AKSİYON',
                  style: TextStyle(color: Colors.white70, fontSize: 13,
                      letterSpacing: 3)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.mic,
                    title: 'Sahneye Çık',
                    sub: 'Konser (Ses -25/-35)',
                    color: NSPTheme.neonPink,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _StageWrapper(),
                    )),
                    enabled: state.voice > 20,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionCard(
                    icon: Icons.music_note,
                    title: 'Prova',
                    sub: 'Ritim antrenmanı',
                    color: NSPTheme.neonCyan,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _PracticeWrapper(),
                    )),
                    enabled: state.voice > 10,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionCard(
                    icon: Icons.card_giftcard,
                    title: 'Dilemma',
                    sub: 'Olay kartı aç',
                    color: NSPTheme.stageGold,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => _DilemmaWrapper(),
                    )),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _ActionCard(
                    icon: Icons.money,
                    title: 'Hayran Kulübü',
                    sub: 'Pasif gelir: NSS at yarışı karşılığı',
                    color: Colors.greenAccent,
                    onTap: () => notifier.addFanClubIncome(),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionCard(
                    icon: Icons.workspace_premium,
                    title: 'Sezon Sonu',
                    sub: 'Kontrat + yükselme/düşme',
                    color: NSPTheme.neonPurple,
                    onTap: () => notifier.signContract(),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: _ActionCard(
                    icon: Icons.logout,
                    title: 'Solo Kariyer',
                    sub: 'Emeklilik / Efsane Skoru',
                    color: Colors.redAccent,
                    onTap: () {
                      final score = notifier.retire();
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _RetireScreen(score: score),
                      ));
                    },
                  )),
                ],
              ),
              const SizedBox(height: 16),
              _LearnedSongs(state),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sahne ekranı wrap'ı — sonuç dönünce sonuç özetini göster
class _StageWrapper extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(careerProvider.notifier);
    return Stack(
      children: [
        StageFlow(
          onShowEnd: (result) {
            notifier.applyShowResult(result);
          },
          onBack: () {},
        ),
      ],
    );
  }
}

/// Prova ekranı — kısa ritim antrenmanı, NSS antrenman/technique karşılığı
class _PracticeWrapper extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(careerProvider.notifier);
    return Scaffold(
      backgroundColor: NSPTheme.darkStage,
      appBar: AppBar(
        backgroundColor: NSPTheme.darkCard,
        title: const Text('Prova — Koreografi Çalışması',
            style: TextStyle(color: Colors.white, fontSize: 15)),
      ),
      body: RhythmGame(
        bpm: 80,
        noteCount: 10,
        onFinish: (hits) {
          notifier.trainingResult(hits, 10);
          notifier.learnSong('Yeni Şarkı Demo');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$hits/10 başarılı! Şarkı "Yeni Şarkı Demo" ezberlendi.'),
            backgroundColor: NSPTheme.neonPurple,
          ));
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Dilemma wrap'ı — rastgele olay kartı
class _DilemmaWrapper extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = DilemmaType.values;
    final type = options[Random().nextInt(options.length)];
    return Scaffold(
      backgroundColor: NSPTheme.darkStage.withValues(alpha: 0.92),
      body: DilemmaScreen(
        type: type,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CareerState state;
  const _Header(this.state);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: NSPTheme.neonPink,
          child: Text(state.playerName[0],
              style: const TextStyle(fontSize: 28,
                  color: Colors.white, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.playerName,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(
                '${state.stage.label} · Sezon ${state.season} · '
                '${state.isGirlBand ? "Girl Band" : "Boy Band"}',
                style: const TextStyle(color: Colors.white54,
                    fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12,
              vertical: 8),
          decoration: BoxDecoration(
            color: NSPTheme.stageGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NSPTheme.stageGold),
          ),
          child: Text('${state.money} ₺',
              style: const TextStyle(color: NSPTheme.stageGold,
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final CareerState state;
  const _StatsPanel(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NSPTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İSTATİSTİKLER',
              style: TextStyle(color: NSPTheme.neonCyan,
                  fontSize: 13, letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StatBar(label: 'Ses Sağlığı (stamina)', value: state.voice,
              color: Colors.redAccent),
          const SizedBox(height: 10),
          StatBar(label: 'Hype (form)', value: state.hype,
              color: NSPTheme.stageGold),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: StatBar(label: 'Şöhret',
                  value: (state.fame / 10).clamp(0, 100).round(),
                  color: NSPTheme.neonPink)),
              const SizedBox(width: 12),
              Expanded(child: StatBar(label: 'Kariyer Skoru',
                  value: (state.careerScore ~/ 20).clamp(0, 100).round(),
                  color: NSPTheme.neonPurple)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelationsPanel extends StatelessWidget {
  final CareerState state;
  const _RelationsPanel(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NSPTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İLİŞKİLER',
              style: TextStyle(color: NSPTheme.neonPink,
                  fontSize: 13, letterSpacing: 3,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          StatBar(label: 'Menajer / Plak Şirketi',
              value: state.managerRelation),
          const SizedBox(height: 8),
          StatBar(label: 'Hayran Kitlesi',
              value: state.fansRelation, color: NSPTheme.stageGold),
          const SizedBox(height: 8),
          StatBar(label: 'Sponsorlar',
              value: state.sponsorRelation, color: NSPTheme.neonCyan),
          const SizedBox(height: 8),
          StatBar(label: 'Medya',
              value: state.mediaRelation, color: Colors.purpleAccent),
          const SizedBox(height: 10),
          ...state.members.map((m) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text('${m.name} (${m.role})',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ),
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: m.relationship / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        color: m.relationship > 60
                            ? NSPTheme.neonCyan
                            : NSPTheme.stageGold,
                      ),
                    )),
                    const SizedBox(width: 8),
                    Text('${m.relationship}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(sub, textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnedSongs extends StatelessWidget {
  final CareerState state;
  const _LearnedSongs(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: NSPTheme.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ezberlenen Şarkılar',
              style: TextStyle(color: NSPTheme.neonCyan,
                  fontSize: 13, letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          state.learnedSongs.isEmpty
              ? const Text('Henüz yok — prova yaparak yeni şarkı öğren.',
                  style: TextStyle(color: Colors.white54, fontSize: 13))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.learnedSongs
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: NSPTheme.neonPurple
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: NSPTheme.neonPurple),
                            ),
                            child: Text(s,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12)),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _RetireScreen extends StatelessWidget {
  final int score;
  const _RetireScreen({required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NSPTheme.darkStage,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('LEGEND SCORE',
                style: TextStyle(color: NSPTheme.stageGold,
                    fontSize: 30, letterSpacing: 4,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Text('$score',
                style: const TextStyle(color: Colors.white,
                    fontSize: 72, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            const Text('Solo kariyere geçtin. NSS career score karşılığı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: NSPTheme.neonPink,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 12)),
              child: const Text('Ana Menü',
                  style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
