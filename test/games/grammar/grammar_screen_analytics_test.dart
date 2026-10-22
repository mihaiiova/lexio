import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/analytics/analytics_repository.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/analytics/analytics_transport.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/analytics/consent_storage.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/analytics/pending_round.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_screen.dart';

void main() {
  testWidgets('emits round_started and item_shown for a consented round', (
    tester,
  ) async {
    final transport = _FakeTransport();
    final repo = await _enabledRepo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [_exercise()], analytics: repo),
      ),
    );
    await tester.pumpAndSettle();
    await repo.flush();

    final kinds = transport.allEvents.map((e) => e.kind).toList();
    expect(kinds, [
      AnalyticsEventKind.roundStarted,
      AnalyticsEventKind.itemShown,
    ]);
    expect(transport.allEvents.first.gameId, 'grammar');
    expect(transport.allEvents.last.itemId, _exercise().notionId);
    expect(transport.allEvents.last.itemIndex, 0);
  });

  testWidgets('emits answered and completed for a finished round', (
    tester,
  ) async {
    final transport = _FakeTransport();
    final repo = await _enabledRepo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(
          exercises: [_exercise(isCorrect: true)],
          analytics: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await repo.flush();

    final events = transport.allEvents;
    expect(events.map((e) => e.kind), [
      AnalyticsEventKind.roundStarted,
      AnalyticsEventKind.itemShown,
      AnalyticsEventKind.itemAnswered,
      AnalyticsEventKind.roundEnded,
    ]);
    expect(events[2].outcome, AnalyticsOutcome.correct);
    expect(events.last.reason, AnalyticsRoundEndReason.completed);
  });

  testWidgets('emits user_back when leaving an active round', (tester) async {
    final transport = _FakeTransport();
    final repo = await _enabledRepo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => GrammarScreen(
                    exercises: [_exercise(), _exercise(id: 'two')],
                    analytics: repo,
                  ),
                ),
              );
            },
            child: const Text('deschide'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('deschide'));
    await tester.pumpAndSettle();
    await repo.flush();
    final before = transport.allEvents.length;

    await tester.pageBack();
    await tester.pumpAndSettle();
    await repo.flush();

    final events = transport.allEvents;
    expect(events.length, greaterThan(before));
    expect(events.last.kind, AnalyticsEventKind.roundEnded);
    expect(events.last.reason, AnalyticsRoundEndReason.userBack);
  });

  testWidgets('does not emit without consent', (tester) async {
    final transport = _FakeTransport();
    final repo = await AnalyticsRepository.load(
      storage: _MemoryConsentStorage(),
      pendingRoundStorage: _MemoryPendingRoundStorage(),
      transport: transport,
      random: Random(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [_exercise()], analytics: repo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await repo.flush();

    expect(transport.allEvents, isEmpty);
  });

  testWidgets('does not duplicate events on a rebuild', (tester) async {
    final transport = _FakeTransport();
    final repo = await _enabledRepo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [_exercise()], analytics: repo),
      ),
    );
    await tester.pumpAndSettle();
    await repo.flush();
    final before = transport.allEvents.length;

    await tester.pump();
    await tester.pumpAndSettle();
    await repo.flush();

    expect(transport.allEvents.length, before);
  });

  testWidgets('play again ends the finished round and starts a new session', (
    tester,
  ) async {
    final transport = _FakeTransport();
    final repo = await _enabledRepo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(
          exercises: [_exercise(isCorrect: true)],
          analytics: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await repo.flush();

    await tester.tap(find.text('Joacă din nou'));
    await tester.pumpAndSettle();
    await repo.flush();

    final events = transport.allEvents;
    final kinds = events.map((e) => e.kind).toList();
    expect(
      kinds.where((k) => k == AnalyticsEventKind.roundStarted),
      hasLength(2),
    );
    expect(
      kinds.where((k) => k == AnalyticsEventKind.roundEnded),
      hasLength(1),
    );
    expect(
      events.firstWhere((e) => e.kind == AnalyticsEventKind.roundEnded).reason,
      AnalyticsRoundEndReason.completed,
    );
  });
}

Future<AnalyticsRepository> _enabledRepo(_FakeTransport transport) async {
  final repo = await AnalyticsRepository.load(
    storage: _MemoryConsentStorage(),
    pendingRoundStorage: _MemoryPendingRoundStorage(),
    transport: transport,
    random: Random(1),
  );
  await repo.enable();
  return repo;
}

GrammarExercise _exercise({String id = 'one', bool isCorrect = false}) {
  return GrammarExercise(
    id: id,
    sentence: 'Copiii au plecat la școală.',
    category: 'test',
    topic: 'test',
    isCorrect: isCorrect,
    explanation: 'Explicație de test.',
    correctSentence: null,
    difficulty: 1,
    tags: const [],
    pairId: null,
  );
}

final class _FakeTransport implements AnalyticsTransport {
  final List<List<AnalyticsEvent>> sentBatches = [];

  List<AnalyticsEvent> get allEvents =>
      sentBatches.expand((batch) => batch).toList();

  @override
  Future<void> sendEvents(List<AnalyticsEvent> events, {String? deletionSecret}) async {
    sentBatches.add(events);
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {}
}

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    value = updated;
  }
}

final class _MemoryPendingRoundStorage implements PendingRoundStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    value = updated;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}
