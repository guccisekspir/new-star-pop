import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/career_provider.dart';
import '../core/theme.dart';
import 'hub_screen.dart';

/// Başlangıç ekranı — NSS "create your alter ego" karşılığı
class StartScreen extends HookConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameCtrl = useTextEditingController();
    final isGirlBand = useState(true);

    return Scaffold(
      backgroundColor: NSPTheme.darkStage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: NSPTheme.card(color: const Color(0xFF2A1342)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('NEW',
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, letterSpacing: 8,
                          fontWeight: FontWeight.w300)),
                  const Text('STAR',
                      style: TextStyle(color: NSPTheme.stageGold,
                          fontSize: 44, letterSpacing: 6,
                          fontWeight: FontWeight.w900)),
                  const Text('POP',
                      style: TextStyle(color: NSPTheme.neonPink,
                          fontSize: 44, letterSpacing: 6,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('terepop.com · New Star Soccer konsepti × TR Pop',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Sahne adın...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: NSPTheme.neonPurple.withValues(
                                alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: NSPTheme.neonPink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Grup formatı',
                      style: TextStyle(color: Colors.white70,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _FormatBtn(
                        'Girl Band', NSPTheme.neonPink,
                        !isGirlBand.value,
                        () => isGirlBand.value = true,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _FormatBtn(
                        'Boy Band', NSPTheme.neonCyan,
                        isGirlBand.value,
                        () => isGirlBand.value = false,
                      )),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(careerProvider.notifier).newCareer(
                              name: nameCtrl.text.trim(),
                              isGirlBand: isGirlBand.value,
                            );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HubScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NSPTheme.neonPink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('KARİYERE BAŞLA',
                          style: TextStyle(
                              fontSize: 17, letterSpacing: 3)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _FormatBtn(this.label, this.color, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(
                color: selected ? color : Colors.white60,
                fontSize: 15, fontWeight: FontWeight.bold,
                letterSpacing: 1)),
      ),
    );
  }
}
