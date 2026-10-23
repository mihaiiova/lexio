import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/design/colors.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/games/spot/spot_content.dart';
import 'package:lexio/games/spot/spot_game.dart';
import 'package:lexio/games/spot/spot_screen.dart';
import 'package:lexio/games/spot/widgets/spot_summary.dart';

import '../../support/analytics_fakes.dart';

SpotText text(String id) => SpotText(
  id: id,
  type: 'story',
  title: 'Test',
  difficulty: 1,
  content: 'Mie place oras aici',
  mistakes: const [
    SpotMistake(
      wordIndex: 0,
      token: 'Mie',
      replacement: 'Mi-e',
      explanation: 'Cratimă',
      category: 'ortografie',
      topic: 'cratima',
    ),
    SpotMistake(
      wordIndex: 2,
      token: 'oras',
      replacement: 'oraș',
      explanation: 'Diacritice',
      category: 'ortografie',
      topic: 'diacritice',
    ),
  ],
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

void main() {
  testWidgets('idle countdown refreshes time and warning without collecting', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var now = DateTime.utc(2026, 6, 1);
    final transport = RecordingAnalyticsTransport();
    final repo = await analyticsRepository(transport, clock: () => now);
    await tester.pumpWidget(
      MaterialApp(
        home: SpotScreen(
          texts: [text('a')],
          analytics: repo,
          clock: () => now,
        ),
      ),
    );
    await settle(tester);
    await repo.flush();
    final initialEvents = transport.events.length;
    expect(find.text('01:00'), findsOneWidget);

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Timp rămas: 00:59')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('00:59')).style!.color,
      LexioColors.textSecondary,
    );

    now = now.add(const Duration(seconds: 49));
    await tester.pump(const Duration(seconds: 49));
    expect(find.text('00:10'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Timp rămas: 00:10')),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('00:10')).style!.color,
      LexioColors.error,
    );
    await repo.flush();
    expect(transport.events, hasLength(initialEvents));
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Spot observes repeat presses without changing discoveries or gameplay score',
    (tester) async {
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(transport);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: SpotScreen(
            texts: [text('a')],
            mode: SpotGameMode.normal,
            analytics: repo,
          ),
        ),
      );
      await settle(tester);
      for (final position in [1, 1, 0, 0, 2]) {
        await tester.tap(find.byKey(ValueKey('0_$position')));
        await settle(tester);
      }
      // Legacy gameplay still accepts wrong-word presses after resolution.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('0_3')));
        await settle(tester);
      }
      // Already-found tokens do not gain new actions after resolution.
      await tester.tap(find.byKey(const ValueKey('0_0')));
      await settle(tester);
      await tester.tap(find.text('Vezi rezumatul'));
      await settle(tester);
      await repo.flush();
      final presses = transport.events
          .where((e) => e.kind.wireName == 'spot_attempt')
          .map((e) => e.toJson())
          .toList();
      expect(presses.map((e) => e['attemptDelta']), [1, 1, 1, 1, 1, 1, 1]);
      expect(presses.map((e) => e['correctDiscoveryDelta']), [
        0,
        0,
        1,
        0,
        1,
        0,
        0,
      ]);
      expect(presses.map((e) => e['distinctWrongDelta']), [
        1,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
      expect(
        transport.events.where(
          (e) => e.kind == AnalyticsEventKind.itemAnswered,
        ),
        isEmpty,
      );
      expect(
        transport.events.where(
          (e) => e.kind == AnalyticsEventKind.itemResolved,
        ),
        hasLength(1),
      );
      expect(transport.events.last.reason, AnalyticsRoundEndReason.completed);
      expect(
        tester.widget<SpotSummary>(find.byType(SpotSummary)).state.score,
        150,
      ); // Two discoveries minus two distinct wrong positions; repeats do not change score.
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'already-found token keeps non-actionable semantics during play',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: SpotScreen(texts: [text('a')], mode: SpotGameMode.normal),
        ),
      );
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('0_0')));
      await settle(tester);
      final node = tester.getSemantics(find.byKey(const ValueKey('0_0')));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final mode in SpotGameMode.values) {
    testWidgets(
      '$mode text identity, unresolved reveal, restart, zero-answer back and consent withdrawal',
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SpotScreen(
                      texts: [text('a'), text('b')],
                      mode: mode,
                      analytics: repo,
                    ),
                  ),
                ),
                child: const Text('start'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('start'));
        await settle(tester);
        for (var index = 0; index < 2; index++) {
          await tester.tap(find.byKey(ValueKey('${index}_1')));
          await settle(tester);
          await tester.tap(find.byKey(ValueKey('${index}_1')));
          await settle(tester);
          await tester.tap(find.text('Arată toate greșelile'));
          await settle(tester);
          await tester.tap(
            find.text(index == 0 ? 'Continuă' : 'Vezi rezumatul'),
          );
          await settle(tester);
        }
        expect(transport.events, isEmpty);
        queue.writeGate!.complete();
        await repo.flush();
        expect(
          transport.events
              .where((e) => e.kind == AnalyticsEventKind.itemShown)
              .map((e) => e.itemId),
          ['a', 'b'],
        );
        expect(
          transport.events
              .where((e) => e.kind.wireName == 'spot_attempt')
              .map((e) => e.distinctWrongDelta),
          [1, 0, 1, 0],
        );
        expect(
          transport.events.where(
            (e) => e.kind == AnalyticsEventKind.itemResolved,
          ),
          isEmpty,
        );
        expect(transport.events.last.itemId, 'b');
        expect(transport.events.last.itemState, AnalyticsItemState.unresolved);
        final oldSession = transport.events.last.sessionId;
        await tester.tap(find.text('Joacă din nou'));
        await settle(tester);
        await repo.flush();
        expect(transport.events.last.sessionId, isNot(oldSession));
        await tester.binding.handlePopRoute();
        await settle(tester);
        await repo.flush();
        expect(transport.events.last.reason, AnalyticsRoundEndReason.userBack);
        expect(transport.events.last.itemId, 'a');
        expect(transport.events.last.itemState, AnalyticsItemState.unresolved);
        final before = transport.events.length;
        await repo.disable();
        await tester.tap(find.text('start'));
        await settle(tester);
        await tester.tap(find.byKey(const ValueKey('0_1')));
        await settle(tester);
        await tester.binding.handlePopRoute();
        await settle(tester);
        await repo.flush();
        expect(transport.events, hasLength(before));
      },
    );
  }

  testWidgets(
    'timed expiry keeps last rendered text, background is not an end, kill is recovered at activity time',
    (tester) async {
      var now = DateTime.utc(2026, 6, 1);
      final storage = MemoryAnalyticsStorage();
      final queue = MemoryAnalyticsStorage();
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(
        transport,
        storage: storage,
        queue: queue,
        clock: () => now,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SpotScreen(
            texts: [text('a'), text('b')],
            analytics: repo,
            clock: () => now,
          ),
        ),
      );
      await settle(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await repo.flush();
      expect(
        transport.events.where((e) => e.kind == AnalyticsEventKind.roundEnded),
        isEmpty,
      );
      now = now.add(const Duration(seconds: 61));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      await repo.flush();
      expect(transport.events.last.itemId, 'b');
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      await repo.flush();
      expect(transport.events.last.reason, AnalyticsRoundEndReason.timeout);
      expect(transport.events.last.itemId, 'b');
      expect(transport.events.last.itemIndex, 1);
      expect(transport.events.last.itemState, AnalyticsItemState.unresolved);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: SpotScreen(
            texts: [text('kill')],
            analytics: repo,
            clock: () => now,
          ),
        ),
      );
      await settle(tester);
      await repo.flush();
      final lastActivity = now;
      await tester.pumpWidget(const SizedBox());
      now = now.add(const Duration(days: 1));
      final recovered = await analyticsRepository(
        transport,
        storage: storage,
        queue: queue,
        clock: () => now,
      );
      await recovered.reconcileInterruptedRound();
      await recovered.flush();
      expect(
        transport.events.last.reason,
        AnalyticsRoundEndReason.inferredInterruption,
      );
      expect(transport.events.last.timestampUtc, lastActivity);
      expect(transport.events.last.itemId, 'kill');
    },
  );

  testWidgets('deadline wins over a next press before the timer callback', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 6, 1);
    final transport = RecordingAnalyticsTransport();
    final repo = await analyticsRepository(transport, clock: () => now);
    await tester.pumpWidget(
      MaterialApp(
        home: SpotScreen(texts: [text('a')], analytics: repo, clock: () => now),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Arată toate greșelile'));
    await settle(tester);
    now = now.add(const Duration(seconds: 61));
    await tester.tap(find.text('Vezi rezumatul'));
    await settle(tester);
    await repo.flush();
    expect(transport.events.last.reason, AnalyticsRoundEndReason.timeout);
    expect(transport.events.last.itemId, 'a');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty and unconsented Spot never collect', (tester) async {
    for (final enabled in [false, true]) {
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(transport, enabled: enabled);
      await tester.pumpWidget(
        MaterialApp(
          home: SpotScreen(
            texts: enabled ? const [] : [text('a')],
            analytics: repo,
          ),
        ),
      );
      await settle(tester);
      await repo.flush();
      expect(transport.events, isEmpty);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
