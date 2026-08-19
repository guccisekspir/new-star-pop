import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/career_provider.dart';
import '../core/theme.dart';

/// Dilemma kartları — NSS rüşvet/skandal/kumarhane katmanı
/// Rastgele bir olay kartı açılır; kararın gerçek sonuçları vardır.
enum DilemmaType { secretOffer, nightClub, rest, fansEvent }

class DilemmaScreen extends HookConsumerWidget {
  final DilemmaType type;
  final VoidCallback onClose;

  const DilemmaScreen({super.key, required this.type, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(careerProvider.notifier);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: NSPTheme.card(color: const Color(0xFF301245)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._cardsFor(type, notifier),
          ],
        ),
      ),
    );
  }

  List<Widget> _cardsFor(DilemmaType type, CareerNotifier notifier) {
    switch (type) {
      case DilemmaType.secretOffer:
        return [
          const Text('📄 GİZLİ TEKLİF',
              style: TextStyle(color: NSPTheme.stageGold,
                  fontSize: 20, fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 14),
          const Text(
            'Rakip plak şirketi seni tek başına almak istiyor. 500 ₺ peşin, ama gruba bunu söylememen gerekiyor...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          _DilemmaBtn('Kabul et (500 ₺, Grup -15, skandal riski)',
              Colors.redAccent, () {
            notifier.resolveDilemma('acceptOffer');
            onClose();
          }),
          const SizedBox(height: 10),
          _DilemmaBtn('Dürüst kal, menajere söyle',
              NSPTheme.neonCyan, () {
            notifier.resolveDilemma('honest');
            onClose();
          }),
        ];
      case DilemmaType.nightClub:
        return [
          const Text('🌙 GECE KULÜBÜ',
              style: TextStyle(color: NSPTheme.neonPink,
                  fontSize: 20, fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 14),
          const Text(
            'Konser sonrası arkadaşların gece kulübüne davet ediyor. Paparazziler de oradaymış...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          _DilemmaBtn('Git — hayat kısa (Medya -20, skandal)',
              NSPTheme.neonPink, () {
            notifier.resolveDilemma('nightClub');
            onClose();
          }),
          const SizedBox(height: 10),
          _DilemmaBtn('Otelde dinlen (Ses +35)',
              NSPTheme.neonCyan, () {
            notifier.resolveDilemma('rest');
            onClose();
          }),
        ];
      case DilemmaType.rest:
        return [
          const Text('🛋️ HAFTA SONU',
              style: TextStyle(color: NSPTheme.neonCyan,
                  fontSize: 20, fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 14),
          const Text(
            'Boş bir günün var. Nereye harcıyorsun?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          _DilemmaBtn('Ses istirahati (Ses +35, Hype -5)',
              NSPTheme.neonCyan, () {
            notifier.resolveDilemma('rest');
            onClose();
          }),
          const SizedBox(height: 10),
          _DilemmaBtn('Hayran etkinliği (Fanbase +8, Ses -5)',
              NSPTheme.stageGold, () {
            notifier.resolveDilemma('socialMedia');
            onClose();
          }),
        ];
      case DilemmaType.fansEvent:
        return [
          const Text('💖 HAYRAN BULUŞMASI',
              style: TextStyle(color: NSPTheme.stageGold,
                  fontSize: 20, fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 14),
          const Text(
            'İmza günü düzenlendi. Yorucu ama hayranların seni bekliyor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 20),
          _DilemmaBtn('Katıl (Fanbase +8, Ses -5)',
              NSPTheme.stageGold, () {
            notifier.resolveDilemma('socialMedia');
            onClose();
          }),
          const SizedBox(height: 10),
          _DilemmaBtn('Dinlen (Ses +35)',
              NSPTheme.neonCyan, () {
            notifier.resolveDilemma('rest');
            onClose();
          }),
        ];
    }
  }
}

class _DilemmaBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DilemmaBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
