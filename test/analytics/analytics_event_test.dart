import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';

void main() {
  group('AnalyticsEvent', () {
    test('serializes a round_started event with the versioned contract', () {
      final event = AnalyticsEvent(
        eventId: 'ev_1',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026, 1, 2, 3, 4, 5),
        kind: AnalyticsEventKind.roundStarted,
      );

      expect(event.toJson(), {
        'v': 1,
        'eventId': 'ev_1',
        'sessionId': 's_1',
        'installationId': 'inst_1',
        'gameId': 'grammar',
        'contentVersion': 'bundled',
        'itemId': null,
        'itemIndex': null,
        'timestampUtc': '2026-01-02T03:04:05.000Z',
        'kind': 'round_started',
        'outcome': null,
        'reason': null,
      });
    });

    test('serializes item_shown and item_answered with bounded fields', () {
      final shown = AnalyticsEvent(
        eventId: 'ev_2',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026, 1, 2),
        kind: AnalyticsEventKind.itemShown,
        itemId: 'notion_1',
        itemIndex: 3,
      );
      expect(shown.toJson()['kind'], 'item_shown');
      expect(shown.toJson()['itemId'], 'notion_1');
      expect(shown.toJson()['itemIndex'], 3);

      final answered = AnalyticsEvent(
        eventId: 'ev_3',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026, 1, 2),
        kind: AnalyticsEventKind.itemAnswered,
        itemId: 'notion_1',
        itemIndex: 3,
        outcome: AnalyticsOutcome.correct,
      );
      expect(answered.toJson()['outcome'], 'correct');
      expect(answered.toJson()['reason'], isNull);
    });

    test('serializes round_ended with a reason and last shown item', () {
      final event = AnalyticsEvent(
        eventId: 'ev_4',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026, 1, 2),
        kind: AnalyticsEventKind.roundEnded,
        itemId: 'notion_1',
        itemIndex: 3,
        reason: AnalyticsRoundEndReason.userBack,
      );
      expect(event.toJson()['reason'], 'user_back');
      expect(event.toJson()['outcome'], isNull);
    });

    test('rejects a round_started carrying item or outcome fields', () {
      final event = AnalyticsEvent(
        eventId: 'ev_5',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.roundStarted,
        itemId: 'notion_1',
      );
      expect(() => event.toJson(), throwsFormatException);
    });

    test('rejects item_shown without item identity', () {
      final event = AnalyticsEvent(
        eventId: 'ev_6',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.itemShown,
      );
      expect(() => event.toJson(), throwsFormatException);
    });

    test('rejects item_answered without an outcome', () {
      final event = AnalyticsEvent(
        eventId: 'ev_7',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.itemAnswered,
        itemId: 'notion_1',
        itemIndex: 0,
      );
      expect(() => event.toJson(), throwsFormatException);
    });

    test('rejects round_ended without a reason', () {
      final event = AnalyticsEvent(
        eventId: 'ev_8',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.roundEnded,
      );
      expect(() => event.toJson(), throwsFormatException);
    });

    test('rejects oversized identifiers and negative indexes', () {
      final long = 'x' * (AnalyticsEvent.maxIdLength + 1);
      final oversized = AnalyticsEvent(
        eventId: long,
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.roundStarted,
      );
      expect(() => oversized.toJson(), throwsFormatException);

      final negative = AnalyticsEvent(
        eventId: 'ev_9',
        sessionId: 's_1',
        installationId: 'inst_1',
        gameId: 'grammar',
        contentVersion: 'bundled',
        timestampUtc: DateTime.utc(2026),
        kind: AnalyticsEventKind.itemShown,
        itemId: 'notion_1',
        itemIndex: -1,
      );
      expect(() => negative.toJson(), throwsFormatException);
    });
  });
}
