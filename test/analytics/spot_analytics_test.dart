import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/analytics_event.dart';

import '../support/analytics_fakes.dart';

void main() {
  test('Dart schema accepts only bounded Spot deltas and known game ids', () {
    final base = AnalyticsEvent(
      eventId: 'event',
      sessionId: 'session',
      installationId: 'installation',
      gameId: 'spot',
      contentVersion: '1',
      timestampUtc: DateTime.utc(2026),
      kind: AnalyticsEventKind.spotAttempt,
      itemId: 'text',
      itemIndex: 0,
      attemptDelta: 1,
      correctDiscoveryDelta: 0,
      distinctWrongDelta: 1,
    ).toJson();
    expect(AnalyticsEvent.fromJson(base).toJson(), base);
    for (final change in <Map<String, dynamic>>[
      {'gameId': 'unknown'},
      {'gameId': 'grammar'},
      {'attemptDelta': 2},
      {'correctDiscoveryDelta': 1},
      {'distinctWrongDelta': -1},
      {'itemIndex': 10001},
      {'wordPosition': 3},
      {'rawAnswer': 'private'},
      {'kind': 'item_answered', 'outcome': 'wrong'},
      {'kind': 'item_shown'},
    ]) {
      expect(
        () => AnalyticsEvent.fromJson({...base, ...change}),
        throwsFormatException,
      );
    }
  });

  test(
    'Spot attempts are bounded deltas, distinct positions stay local, recovery is coherent',
    () async {
      final transport = RecordingAnalyticsTransport()..offline = true;
      final storage = MemoryAnalyticsStorage();
      final queue = MemoryAnalyticsStorage();
      final now = DateTime.utc(2026, 6, 1);
      final repo = await analyticsRepository(
        transport,
        storage: storage,
        queue: queue,
        clock: () => now,
      );
      await repo.startRound(gameId: 'spot', contentVersion: '1');
      await repo.itemShown(itemId: 'text_a', itemIndex: 0);
      for (var i = 0; i < 2; i++) {
        await repo.spotAttempt(
          itemId: 'text_a',
          itemIndex: 0,
          wordPosition: 3,
          newlyCorrect: false,
          isWrong: true,
        );
      }
      await repo.spotAttempt(
        itemId: 'text_a',
        itemIndex: 0,
        wordPosition: 0,
        newlyCorrect: true,
        isWrong: false,
        resolvesItem: true,
      );
      await repo.spotAttempt(
        itemId: 'text_a',
        itemIndex: 0,
        wordPosition: 0,
        newlyCorrect: false,
        isWrong: false,
      );
      await repo.itemShown(itemId: 'text_b', itemIndex: 1);
      await repo.spotAttempt(
        itemId: 'text_b',
        itemIndex: 1,
        wordPosition: 3,
        newlyCorrect: false,
        isWrong: true,
      );
      final saved = jsonDecode(queue.value!) as Map<String, dynamic>;
      final events = (saved['events'] as List).cast<Map<String, dynamic>>();
      final attempts = events
          .where((e) => e['kind'] == 'spot_attempt')
          .toList();
      expect(attempts.map((e) => e['attemptDelta']), [1, 1, 1, 1, 1]);
      expect(attempts.map((e) => e['correctDiscoveryDelta']), [0, 0, 1, 0, 0]);
      expect(attempts.map((e) => e['distinctWrongDelta']), [1, 0, 0, 0, 1]);
      expect(jsonEncode(events), isNot(contains('wordPosition')));
      expect(jsonEncode(events), isNot(contains('wrongPositions')));
      for (final snapshot in queue.snapshots.toList()) {
        final replayQueue = MemoryAnalyticsStorage()..value = snapshot;
        final accepted = RecordingAnalyticsTransport();
        final recovered = await analyticsRepository(
          accepted,
          storage: storage,
          queue: replayQueue,
          clock: () => now.add(const Duration(days: 1)),
        );
        await recovered.reconcileInterruptedRound();
        await recovered.flush();
        final resolutions = accepted.events.where(
          (e) => e.kind == AnalyticsEventKind.itemResolved,
        );
        final discoveries = accepted.events.where(
          (e) => e.toJson()['correctDiscoveryDelta'] == 1,
        );
        expect(resolutions.length, discoveries.length);
        final end = accepted.events.last;
        expect(end.reason, AnalyticsRoundEndReason.inferredInterruption);
        expect(end.timestampUtc, now);
      }
    },
  );
}
