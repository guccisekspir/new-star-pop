import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../ui/stage_theme.dart';
import '../ui/particles.dart';
import '../core/career_provider.dart';
import 'hub_screen.dart';

/// Kariyer açılış ekranı — neon sahne temalı giriş
class StartScreen extends HookConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final name = useState('');
    final isGirlBand = useState<bool?>(null);
    final burstController = useMemoized(() => BurstController());

    void startCareer() {
      if (name.value.trim().isEmpty || isGirlBand.value == null) return;
      ref.read(careerProvider.notifier).newCareer(
            name: name.value.trim(),
            isGirlBand: isGirlBand.value!,
          );
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => const HubScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: StageTheme.bgDeep,
      body: ParticleOverlay(
        controller: burstController,
        child: Stack(
          children: [
            const StageBackdrop(beamCount: 5, floor: true),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 90, 24, 40),
              child: Column(
                children: [
                  // logo / başlık
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: StageTheme.neonPink.withValues(alpha: 0.6)),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black45,
                    ),
                    child: const Text('✦ TERERPOP.COM ✦',
                        style: TextStyle(
                            color: StageTheme.neonGold, fontSize: 11,
                            letterSpacing: 4, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [StageTheme.neonPink, StageTheme.neonPurple, StageTheme.neonCyan],
                    ).createShader(bounds),
                    child: const Text(
                      'NEW STAR POP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        height: 1.05,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sahneye çık. Yıldız ol.',
                    style: TextStyle(color: StageTheme.textSub, fontSize: 14, letterSpacing: 1),
                  ),
                  const SizedBox(height: 36),

                  // isim girişi
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: StageTheme.neonPurple.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black45,
                    ),
                    child: TextField(
                      controller: nameController,
                      onChanged: (v) => name.value = v,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Yıldız adın...',
                        hintStyle: TextStyle(color: StageTheme.textSub, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(Icons.mic, color: StageTheme.neonCyan, size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // band tipi seçimi
                  const Text('GRUBUN',
                      style: TextStyle(color: StageTheme.textSub, fontSize: 11,
                          letterSpacing: 3, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeCard(
                          emoji: '👩',
                          title: 'GIRL BAND',
                          sub: 'Kız grubu',
                          color: StageTheme.neonPink,
                          selected: isGirlBand.value == true,
                          onTap: () {
                            isGirlBand.value = true;
                            burstController.confetti(
                                MediaQuery.sizeOf(context).width / 2, 300, count: 20,
                                palette: [StageTheme.neonPink, Colors.white]);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TypeCard(
                          emoji: '👨',
                          title: 'BOY BAND',
                          sub: 'Erkek grubu',
                          color: StageTheme.neonCyan,
                          selected: isGirlBand.value == false,
                          onTap: () {
                            isGirlBand.value = false;
                            burstController.confetti(
                                MediaQuery.sizeOf(context).width / 2, 300, count: 20,
                                palette: [StageTheme.neonCyan, Colors.white]);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // başla butonu
                  NeonButton(
                    label: 'SAHNEYE ÇIK →',
                    color: StageTheme.neonGold,
                    width: double.infinity,
                    enabled: name.value.trim().isNotEmpty && isGirlBand.value != null,
                    onTap: startCareer,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pop idol kariyeri simülasyonu — New Star Soccer ilhamıyla',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: StageTheme.textSub, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.emoji,
    required this.title,
    required this.sub,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.12)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              : null,
          color: selected ? null : Colors.black38,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.35),
            width: selected ? 2.5 : 1.2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18, spreadRadius: 2)]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(color: selected ? color : StageTheme.textSub,
                    fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 3),
            Text(sub, style: TextStyle(color: StageTheme.textSub, fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}
