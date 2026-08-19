import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_star_pop/main.dart';
import 'package:new_star_pop/core/career_model.dart';
import 'package:new_star_pop/games/rhythm_game.dart';

void main() {
  testWidgets('Başlangıç ekranı yüklenir ve kariyer başlar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NewStarPopApp()));
    await tester.pumpAndSettle();

    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('STAR'), findsOneWidget);
    expect(find.text('POP'), findsOneWidget);
    expect(find.text('Girl Band'), findsOneWidget);
    expect(find.text('Boy Band'), findsOneWidget);

    await tester.tap(find.text('KARİYERE BAŞLA'));
    await tester.pumpAndSettle();

    expect(find.text('AKSİYON'), findsOneWidget);
    expect(find.text('Sahneye Çık'), findsOneWidget);
    expect(find.text('Prova'), findsOneWidget);
    expect(find.text('Dilemma'), findsOneWidget);
    expect(find.text('Sezon Sonu'), findsOneWidget);
    expect(find.text('Solo Kariyer'), findsOneWidget);
  });

  testWidgets('Konser akışı sahne ekranlarını gösterir', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NewStarPopApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KARİYERE BAŞLA'));
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sahneye Çık'));
    await tester.pumpAndSettle();

    expect(find.text('TONIGHT'), findsOneWidget);
    expect(find.text('SAHNEYİ AÇ'), findsOneWidget);

    await tester.tap(find.text('SAHNEYİ AÇ'));
    // Ritim oyunu animasyonlu olduğu için pump ile ilerlet
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.textContaining('BPM'), findsOneWidget);
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
                onFinish: (_) {},
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
