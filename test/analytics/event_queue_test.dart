import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/event_queue.dart';

AnalyticsEvent _event(String id) {
  return AnalyticsEvent(
    eventId: id,
    sessionId: 's_1',
    installationId: 'inst_1',
    gameId: 'grammar',
    contentVersion: 'bundled',
    timestampUtc: DateTime.utc(2026),
    kind: AnalyticsEventKind.roundStarted,
  );
}

void main() {
  group('AnalyticsEventQueue', () {
    test('deduplicates by event id', () {
      final queue = AnalyticsEventQueue();
      expect(queue.add(_event('a')), isTrue);
      expect(queue.add(_event('a')), isFalse);
      expect(queue.length, 1);
    });

    test('drains oldest first and clears', () {
      final queue = AnalyticsEventQueue();
      queue.add(_event('a'));
      queue.add(_event('b'));

      final drained = queue.drain();
      expect(drained.map((e) => e.eventId), ['a', 'b']);
      expect(queue.isEmpty, isTrue);
    });

    test('stays bounded by dropping the oldest event', () {
      final queue = AnalyticsEventQueue(maxSize: 2);
      queue.add(_event('a'));
      queue.add(_event('b'));
      queue.add(_event('c'));

      expect(queue.length, 2);
      expect(queue.drain().map((e) => e.eventId), ['b', 'c']);
    });
  });
}
