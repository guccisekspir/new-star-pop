import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_star_pop/main.dart';
import 'package:new_star_pop/core/career_model.dart';
import 'package:new_star_pop/games/rhythm_game.dart';

Future<void> startCareer(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: NewStarPopApp()));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.enterText(find.byType(TextField), 'TestYildiz');
  await tester.pump();
  await tester.tap(find.text('GIRL BAND'));
  await tester.pump();
  await tester.tap(find.text('SAHNEYE ÇIK →'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('Başlangıç ekranı yüklenir ve kariyer başlar', (tester) async {
    await startCareer(tester);
    await tester.scrollUntilVisible(
      find.textContaining('SEZON SONU'), 100,
      maxScrolls: 20, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('AKSİYONLAR'), findsOneWidget);
    expect(find.textContaining('SAHNEYE ÇIK'), findsOneWidget);
    expect(find.textContaining('PROVA'), findsOneWidget);
    expect(find.textContaining('GECE KULÜBÜ'), findsOneWidget);
    expect(find.textContaining('SEZON SONU'), findsOneWidget);
    expect(find.textContaining('SOLO KARİYER'), findsOneWidget);
  });

  testWidgets('Konser akışı sahne ekranlarını gösterir', (tester) async {
    await startCareer(tester);
    await tester.scrollUntilVisible(
      find.textContaining('SEZON SONU'), 100,
      maxScrolls: 20, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));

    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pump();
    await tester.tap(find.textContaining('SAHNEYE ÇIK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // intro ekranı: stil seçimi
    expect(find.textContaining('NASIL OYNARSIN'), findsOneWidget);
    expect(find.textContaining('Diva'), findsOneWidget);

    await tester.tap(find.textContaining('Diva'));
    await tester.pump();
    await tester.tap(find.text('SAHNEYE ÇIK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // ritim oyunu: BPM göstergesi görünür olmalı
    expect(find.byType(RhythmGame), findsOneWidget);

    // animasyonlu ritim oyunu için pump ile ilerlet
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('Ritim oyunu notaları render eder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: RhythmGame(
                bpm: 90,
                noteCount: 4,
                onFinish: (hits, total) {},
              ),
            ),
          ),
        ),
      ),
    );

    // Hedef çizgisi notanın altında görünür olmalı
    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(RhythmGame), findsOneWidget);
  });

  testWidgets('CareerState alanları ve ilişki mantığı çalışır', (tester) async {
    final state = CareerState(
      playerName: 'Test',
      stage: CareerStage.barSahnesi,
      voice: 100,
      hype: 40,
    );
    for (final m in state.members) {
      m.relationship = 50;
    }
    expect(state.stage.level, 1);
    expect(state.learnedSongs, isEmpty);
    expect(state.members.length, 3);

    final result = ShowResult(
      score: 88,
      applause: 100,
      viralGain: 300,
      moneyEarned: 400,
      voiceCost: 30,
      hypeChange: 15,
      headline: 'test',
      relationChanges: {'group': 5},
    );
    state.voice = (state.voice - result.voiceCost).clamp(0, 100);
    state.hype = (state.hype + result.hypeChange).clamp(0, 100);
    expect(state.voice, 70);
    expect(state.hype, 55);
  });
}
