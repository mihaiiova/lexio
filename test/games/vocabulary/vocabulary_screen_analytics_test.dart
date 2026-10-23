import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/analytics/analytics_repository.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/games/idioms/idioms_content.dart';
import 'package:lexio/games/idioms/idioms_screen.dart';
import 'package:lexio/games/vocabulary/vocabulary_content.dart';
import 'package:lexio/games/vocabulary/vocabulary_screen.dart';

import '../../support/analytics_fakes.dart';

const exercise = VocabularyExercise(
  id: 'variant_a',
  notionIdOverride: 'shared',
  word: 'greu',
  partOfSpeech: 'adjectiv',
  definition: 'dificil',
  example: 'Este greu.',
  options: ['dificil', 'ușor'],
  correctOptionIndex: 0,
  explanation: 'Explicație',
  category: 'test',
  synonyms: [],
  difficulty: 1,
);

void main() {
  testWidgets(
    'first committed answer resolves exercise and completes unchanged flow',
    (tester) async {
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(transport);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: VocabularyScreen(exercises: const [exercise], analytics: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('dificil'));
      await tester.pumpAndSettle();
      await repo.flush();
      expect(transport.events.map((e) => e.kind.wireName), [
        'round_started',
        'item_shown',
        'item_answered',
        'item_resolved',
        'round_ended',
      ]);
      expect(transport.events[1].itemId, 'variant_a');
      expect(transport.events[1].contentVersion, '1');
      expect(transport.events.last.reason?.wireName, 'completed');
      expect(transport.events.last.itemIndex, 0);
    },
  );
  for (final game in ['vocabulary', 'idioms']) {
    Widget screen(AnalyticsRepository repo, {bool empty = false}) =>
        game == 'vocabulary'
        ? VocabularyScreen(
            exercises: empty ? const [] : const [exercise],
            analytics: repo,
          )
        : IdiomsScreen(
            exercises: empty
                ? const []
                : const [
                    IdiomExercise(
                      id: 'variant_a',
                      notionIdOverride: 'shared',
                      expression: 'greu',
                      meaning: 'dificil',
                      example: 'Este greu.',
                      highlightedText: 'greu',
                      options: ['dificil', 'ușor'],
                      correctOptionIndex: 0,
                      category: 'test',
                      difficulty: 1,
                    ),
                  ],
            analytics: repo,
          );

    testWidgets(
      '$game wrong answer, rebuild, back and replay preserve lifecycle under active storage delay',
      (tester) async {
        final transport = RecordingAnalyticsTransport();
        final queue = MemoryAnalyticsStorage()..writeGate = Completer<void>();
        addTearDown(() {
          if (!queue.writeGate!.isCompleted) queue.writeGate!.complete();
        });
        final repo = await analyticsRepository(transport, queue: queue);
        await tester.pumpWidget(
          MaterialApp(
            theme: LexioTheme.light,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => screen(repo))),
                child: const Text('start'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('start'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ușor'));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(transport.events, isEmpty);
        queue.writeGate!.complete();
        await repo.flush();
        expect(transport.events.map((e) => e.kind.wireName), [
          'round_started',
          'item_shown',
          'item_answered',
          'item_resolved',
          'round_ended',
        ]);
        expect(transport.events[2].outcome, AnalyticsOutcome.wrong);
        expect(transport.events.last.reason, AnalyticsRoundEndReason.userBack);
        expect(transport.events.last.itemState, AnalyticsItemState.resolved);
        await tester.tap(find.text('start'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('dificil'));
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events.last.reason, AnalyticsRoundEndReason.completed);
        final session = transport.events.last.sessionId;
        await tester.tap(find.text('Joacă din nou'));
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events.last.kind, AnalyticsEventKind.itemShown);
        expect(transport.events.last.sessionId, isNot(session));
        await tester.pageBack();
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events.last.itemState, AnalyticsItemState.unresolved);
        expect(
          transport.events.where((e) => e.kind == AnalyticsEventKind.itemShown),
          hasLength(3),
        );
      },
    );

    testWidgets('$game no consent or empty content produces no events', (
      tester,
    ) async {
      for (final enabled in [false, true]) {
        final transport = RecordingAnalyticsTransport();
        final repo = await analyticsRepository(transport, enabled: enabled);
        await tester.pumpWidget(
          MaterialApp(home: screen(repo, empty: enabled)),
        );
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events, isEmpty);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }
}
