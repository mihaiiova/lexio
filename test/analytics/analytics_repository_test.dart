import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_repository.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_transport.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/consent_storage.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/pending_round.dart';

void main() {
  group('AnalyticsRepository', () {
    test('defaults to off and undecided when storage is empty', () async {
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      expect(repo.isConsentEnabled, isFalse);
      expect(repo.isConsentUndecided, isTrue);
      expect(repo.installationId, isNull);
    });

    test('treats a failed storage read as off and already decided', () async {
      final storage = _MemoryConsentStorage()..readFailures = 1;
      final repo = await AnalyticsRepository.load(
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      expect(repo.isConsentEnabled, isFalse);
      expect(repo.isConsentUndecided, isFalse);
    });

    test('enable creates and persists a fresh identity', () async {
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      await repo.enable();

      expect(repo.isConsentEnabled, isTrue);
      expect(repo.installationId, isNotNull);
      expect(repo.isConsentUndecided, isFalse);

      final persisted = ConsentState.fromJson(
        jsonDecode(storage.value!) as Map<String, dynamic>,
      );
      expect(persisted.enabled, isTrue);
      expect(persisted.installationId, repo.installationId);
      expect(persisted.deletionSecret, isNotNull);
    });

    test('decline records a first-launch decision without identity', () async {
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      await repo.decline();

      expect(repo.isConsentUndecided, isFalse);
      expect(repo.isConsentEnabled, isFalse);
      expect(repo.needsDeletion, isFalse);
    });

    test('never transmits before consent', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enqueue(_event('pre_consent'));
      await repo.flush();

      expect(transport.sentBatches, isEmpty);

      await repo.enable();
      await repo.flush();

      expect(transport.sentBatches, isEmpty);
    });

    test('transmits a validated event after enable', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.enqueue(_event('post_consent'));
      await repo.flush();

      expect(transport.sentBatches, hasLength(1));
      expect(transport.sentBatches.single.single.eventId, 'post_consent');
    });

    test('deduplicates events by id at the queue boundary', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      repo.enqueue(_event('duplicate'));
      repo.enqueue(_event('duplicate'));
      await repo.flush();

      expect(transport.sentBatches.single, hasLength(1));
    });

    test('retries a failed transmission without losing the event', () async {
      final transport = _FakeTransport()..sendFailures = 1;
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.enqueue(_event('retry'));
      await repo.flush();

      expect(transport.sentBatches.single.single.eventId, 'retry');
    });

    test('disable stops collection, clears the queue and keeps identity', () async {
      final transport = _FakeTransport()..sendFailures = 1000;
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.enqueue(_event('queued'));
      await repo.flush();
      expect(transport.sentBatches, isEmpty);

      await repo.disable();
      transport.sendFailures = 0;
      await repo.flush();

      expect(repo.isConsentEnabled, isFalse);
      expect(repo.needsDeletion, isTrue);
      expect(transport.sentBatches, isEmpty);

      final persisted = ConsentState.fromJson(
        jsonDecode(storage.value!) as Map<String, dynamic>,
      );
      expect(persisted.enabled, isFalse);
      expect(persisted.installationId, isNotNull);
      expect(persisted.deletionSecret, isNotNull);
    });

    test('re-enable creates a fresh identity and deletion secret', () async {
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      await repo.enable();
      final first = repo.installationId;
      await repo.disable();
      await repo.enable();
      final second = repo.installationId;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second, isNot(first));
    });

    test('disableAndDelete clears identity on acknowledgment', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      final deleted = await repo.disableAndDelete();

      expect(deleted, isTrue);
      expect(repo.isConsentEnabled, isFalse);
      expect(repo.needsDeletion, isFalse);
      expect(repo.installationId, isNull);
      expect(transport.deletions, hasLength(1));
    });

    test('disableAndDelete keeps the deletion credential on failure', () async {
      final transport = _FakeTransport()..deleteFailures = 1;
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      final deleted = await repo.disableAndDelete();

      expect(deleted, isFalse);
      expect(repo.needsDeletion, isTrue);

      final persisted = ConsentState.fromJson(
        jsonDecode(storage.value!) as Map<String, dynamic>,
      );
      expect(persisted.needsDeletion, isTrue);
      expect(persisted.installationId, isNotNull);
      expect(persisted.deletionSecret, isNotNull);
    });

    test('session methods emit the round lifecycle in order', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.startRound(gameId: 'grammar', contentVersion: 'bundled');
      await repo.itemShown(itemId: 'n1', itemIndex: 0);
      await repo.itemAnswered(
        itemId: 'n1',
        itemIndex: 0,
        outcome: AnalyticsOutcome.correct,
      );
      await repo.endRound(reason: AnalyticsRoundEndReason.completed);
      await repo.flush();

      final events = transport.sentBatches.expand((batch) => batch).toList();
      expect(
        events.map((e) => e.kind),
        [
          AnalyticsEventKind.roundStarted,
          AnalyticsEventKind.itemShown,
          AnalyticsEventKind.itemAnswered,
          AnalyticsEventKind.roundEnded,
        ],
      );
      expect(events.first.gameId, 'grammar');
      expect(events[1].itemId, 'n1');
      expect(events[2].outcome, AnalyticsOutcome.correct);
      expect(events.last.reason, AnalyticsRoundEndReason.completed);
      expect(events.last.itemId, 'n1');
      expect(events.last.itemIndex, 0);
    });

    test('reconciles a pending round as inferred interruption', () async {
      final transport = _FakeTransport();
      final consentStorage = _MemoryConsentStorage();
      final pendingStorage = _MemoryPendingRoundStorage();
      final repo = await AnalyticsRepository.load(
        storage: consentStorage,
        pendingRoundStorage: pendingStorage,
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.startRound(gameId: 'grammar', contentVersion: 'bundled');
      await repo.itemShown(itemId: 'n1', itemIndex: 0);
      await repo.flush();

      final relaunched = await AnalyticsRepository.load(
        storage: consentStorage,
        pendingRoundStorage: pendingStorage,
        transport: transport,
        random: Random(1),
      );
      await relaunched.reconcileInterruptedRound(gameId: 'grammar');
      await relaunched.flush();

      final events = transport.sentBatches.expand((batch) => batch).toList();
      expect(events.last.kind, AnalyticsEventKind.roundEnded);
      expect(
        events.last.reason,
        AnalyticsRoundEndReason.inferredInterruption,
      );
      expect(events.last.itemId, 'n1');
      expect(events.last.itemIndex, 0);
    });

    test('endRound supports restart without marking the shown item wrong', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.startRound(gameId: 'grammar', contentVersion: 'bundled');
      await repo.itemShown(itemId: 'n1', itemIndex: 0);
      await repo.endRound(reason: AnalyticsRoundEndReason.restart);
      await repo.flush();

      final events = transport.sentBatches.expand((batch) => batch).toList();
      expect(events.last.kind, AnalyticsEventKind.roundEnded);
      expect(events.last.reason, AnalyticsRoundEndReason.restart);
      expect(events.last.itemId, 'n1');
      expect(events.last.itemIndex, 0);
      expect(events.last.outcome, isNull);
    });

    test('session methods no-op without consent', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.startRound(gameId: 'grammar', contentVersion: 'bundled');
      await repo.itemShown(itemId: 'n1', itemIndex: 0);
      await repo.itemAnswered(
        itemId: 'n1',
        itemIndex: 0,
        outcome: AnalyticsOutcome.wrong,
      );
      await repo.endRound(reason: AnalyticsRoundEndReason.completed);
      await repo.flush();

      expect(transport.sentBatches, isEmpty);
    });
  });
}

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

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;
  int readFailures = 0;

  @override
  Future<String?> read() async {
    if (readFailures > 0) {
      readFailures--;
      throw Exception('read failed');
    }
    return value;
  }

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

final class _FakeTransport implements AnalyticsTransport {
  final List<List<AnalyticsEvent>> sentBatches = [];
  final List<Map<String, String>> deletions = [];
  int sendFailures = 0;
  int deleteFailures = 0;

  @override
  Future<void> sendEvents(List<AnalyticsEvent> events) async {
    if (sendFailures > 0) {
      sendFailures--;
      throw Exception('send failed');
    }
    sentBatches.add(events);
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {
    if (deleteFailures > 0) {
      deleteFailures--;
      throw Exception('delete failed');
    }
    deletions.add({
      'installationId': installationId,
      'deletionSecret': deletionSecret,
    });
  }
}
