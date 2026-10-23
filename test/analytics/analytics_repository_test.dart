import 'dart:async';
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
    test(
      'every durable action and acknowledgement reloads coherently',
      () async {
        final consent = _MemoryConsentStorage();
        final queue = _MemoryConsentStorage();
        final pending = _MemoryPendingRoundStorage();
        final offline = _FakeTransport()..sendFailures = 1000;
        final snapshots = <String>[];
        queue.onWrite = snapshots.add;
        final repo = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: offline,
        );
        await repo.enable();
        await repo.startRound(gameId: 'grammar', contentVersion: '1');
        await repo.itemShown(itemId: 'a', itemIndex: 0);
        await repo.itemAnswered(
          itemId: 'a',
          itemIndex: 0,
          outcome: AnalyticsOutcome.correct,
        );
        // Capture acknowledged history too: it must not be recreated or lost
        // when a later item is shown.
        final accepted = _FakeTransport();
        final checkpoint = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: accepted,
        );
        await checkpoint.flush();
        await checkpoint.itemShown(itemId: 'b', itemIndex: 1);
        await checkpoint.endRound(reason: AnalyticsRoundEndReason.completed);
        await checkpoint.flush();
        final acknowledged = accepted.sentBatches.expand((b) => b).toList();
        expect(
          acknowledged.where((e) => e.kind == AnalyticsEventKind.itemAnswered),
          hasLength(1),
        );
        expect(
          acknowledged.where((e) => e.kind == AnalyticsEventKind.itemResolved),
          hasLength(1),
        );
        for (final snapshot in snapshots.toList()) {
          final replayQueue = _MemoryConsentStorage()..value = snapshot;
          final replay = _FakeTransport();
          final recovered = await AnalyticsRepository.load(
            storage: consent,
            queueStorage: replayQueue,
            pendingRoundStorage: _MemoryPendingRoundStorage(),
            transport: replay,
          );
          await recovered.reconcileInterruptedRound();
          await recovered.flush();
          final events = replay.sentBatches.expand((b) => b).toList();
          final answers = events
              .where((e) => e.kind == AnalyticsEventKind.itemAnswered)
              .toList();
          final resolutions = events
              .where((e) => e.kind == AnalyticsEventKind.itemResolved)
              .toList();
          expect(answers.length, resolutions.length);
          if (answers.isNotEmpty) {
            expect(answers.single.outcome, AnalyticsOutcome.correct);
            expect(
              answers.single.eventId,
              acknowledged
                  .firstWhere((e) => e.kind == AnalyticsEventKind.itemAnswered)
                  .eventId,
            );
            expect(
              resolutions.single.eventId,
              acknowledged
                  .firstWhere((e) => e.kind == AnalyticsEventKind.itemResolved)
                  .eventId,
            );
          }
          expect(
            events.where((e) => e.kind == AnalyticsEventKind.roundEnded).length,
            lessThanOrEqualTo(1),
          );
        }
      },
    );

    test(
      'inferred interruption uses last activity bounded by recovery clock',
      () async {
        for (final recovery in [
          DateTime.utc(2026, 4, 20),
          DateTime.utc(2026, 4, 1),
        ]) {
          final consent = _MemoryConsentStorage();
          final queue = _MemoryConsentStorage();
          var now = DateTime.utc(2026, 4, 2);
          final first = await AnalyticsRepository.load(
            storage: consent,
            queueStorage: queue,
            pendingRoundStorage: _MemoryPendingRoundStorage(),
            transport: _FakeTransport(),
            clock: () => now,
          );
          await first.enable();
          await first.startRound(gameId: 'grammar', contentVersion: '1');
          now = DateTime.utc(2026, 4, 3);
          await first.itemShown(itemId: 'a', itemIndex: 0);
          await first.flush();
          final transport = _FakeTransport();
          final recovered = await AnalyticsRepository.load(
            storage: consent,
            queueStorage: queue,
            pendingRoundStorage: _MemoryPendingRoundStorage(),
            transport: transport,
            clock: () => recovery,
          );
          await recovered.reconcileInterruptedRound();
          await recovered.flush();
          expect(
            transport.sentBatches.expand((b) => b).last.timestampUtc,
            recovery.day == 1 ? recovery : DateTime.utc(2026, 4, 3),
          );
        }
      },
    );

    test(
      'failed snapshot cannot publish events before a durable retry',
      () async {
        final queue = _MemoryConsentStorage()..writeFailures = 100;
        final transport = _FakeTransport();
        final repo = await AnalyticsRepository.load(
          storage: _MemoryConsentStorage(),
          queueStorage: queue,
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: transport,
        );
        await repo.enable();
        await repo.startRound(gameId: 'grammar', contentVersion: '1');
        await repo.flush();
        expect(transport.sentBatches, isEmpty);
        queue.writeFailures = 0;
        await repo.itemShown(itemId: 'a', itemIndex: 0);
        await repo.flush();
        expect(transport.sentBatches.expand((b) => b).map((e) => e.kind), [
          AnalyticsEventKind.roundStarted,
          AnalyticsEventKind.itemShown,
        ]);
      },
    );

    test(
      'legacy pending uses start time and terminal snapshot overrides failed cleanup',
      () async {
        final consent = _MemoryConsentStorage();
        final queue = _MemoryConsentStorage();
        final pending = _MemoryPendingRoundStorage();
        final first = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: _FakeTransport(),
        );
        await first.enable();
        pending.value = encodePendingRound(
          PendingRound(
            sessionId: 'legacy',
            installationId: first.installationId!,
            gameId: 'grammar',
            contentVersion: '1',
            startedAtUtc: DateTime.utc(2026, 1, 1),
            lastShownItemId: 'a',
            lastShownItemIndex: 0,
          ),
        );
        pending.clearFailures = 1;
        final transport = _FakeTransport();
        final recovered = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: transport,
          clock: () => DateTime.utc(2026, 1, 20),
        );
        await recovered.reconcileInterruptedRound();
        await recovered.flush();
        expect(
          transport.sentBatches.single.single.timestampUtc,
          DateTime.utc(2026, 1, 1),
        );
        expect(pending.value, isNotNull);
        final reloaded = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: transport,
        );
        await reloaded.reconcileInterruptedRound();
        await reloaded.flush();
        expect(transport.sentBatches, hasLength(1));
      },
    );

    test(
      'crash between answer and resolution delivery preserves both IDs',
      () async {
        final consent = _MemoryConsentStorage();
        final queue = _MemoryConsentStorage();
        final offline = _FakeTransport()..sendFailures = 10000;
        final repo = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: offline,
        );
        await repo.enable();
        await repo.startRound(gameId: 'grammar', contentVersion: '1');
        // 99 preceding events place the pair across the 100-event send boundary.
        for (var i = 0; i < 98; i++) {
          await repo.itemShown(itemId: 'item_$i', itemIndex: i);
        }
        await repo.itemAnswered(
          itemId: 'item_97',
          itemIndex: 97,
          outcome: AnalyticsOutcome.wrong,
        );
        await repo.flush();
        final server = _FakeTransport();
        final sender = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: server,
        );
        await sender.flush();
        final sent = server.sentBatches.expand((b) => b).toList();
        expect(sent.last.kind, AnalyticsEventKind.itemAnswered);
        final snapshot = queue.value;
        final replayIds = <String>[];
        for (var attempt = 0; attempt < 2; attempt++) {
          final interruptedQueue = _MemoryConsentStorage()..value = snapshot;
          final recovered = await AnalyticsRepository.load(
            storage: consent,
            queueStorage: interruptedQueue,
            pendingRoundStorage: _MemoryPendingRoundStorage(),
            transport: server,
          );
          await recovered.itemShown(itemId: 'next', itemIndex: 98);
          await recovered.reconcileInterruptedRound();
          await recovered.flush();
          final resolutions = server.sentBatches
              .expand((b) => b)
              .where((e) => e.kind == AnalyticsEventKind.itemResolved)
              .toList();
          replayIds.add(resolutions.last.eventId);
        }
        expect(replayIds.toSet(), hasLength(1));
        final answers = server.sentBatches
            .expand((b) => b)
            .where((e) => e.kind == AnalyticsEventKind.itemAnswered)
            .toList();
        expect(answers, hasLength(1));
        expect(answers.single.outcome, AnalyticsOutcome.wrong);
      },
    );

    test('defaults to off and undecided when storage is empty', () async {
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
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
        queueStorage: _MemoryConsentStorage(),
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      expect(repo.isConsentEnabled, isFalse);
      expect(repo.isConsentUndecided, isFalse);
    });

    test('enable stays off until durable storage succeeds', () async {
      final storage = _MemoryConsentStorage()..writeGate = Completer<void>();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
      );
      final enabling = repo.enable();
      await Future<void>.delayed(Duration.zero);
      expect(repo.isConsentEnabled, isFalse);
      storage.writeGate!.completeError(StateError('disk unavailable'));
      await enabling;
      expect(repo.isConsentEnabled, isFalse);
    });

    test('revocation fences an in-flight enable and survives reload', () async {
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
      );
      storage.writeGate = Completer<void>();
      final enabling = repo.enable();
      await Future<void>.delayed(Duration.zero);
      final disabling = repo.disable();
      expect(repo.isConsentEnabled, isFalse);
      storage.writeGate!.complete();
      await Future.wait([enabling, disabling]);
      expect(repo.isConsentEnabled, isFalse);
      final reloaded = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: storage,
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
      );
      expect(reloaded.isConsentEnabled, isFalse);
    });

    test(
      'failed withdrawal persistence is recoverable without pretending it saved',
      () async {
        final storage = _MemoryConsentStorage();
        final repo = await AnalyticsRepository.load(
          queueStorage: _MemoryConsentStorage(),
          storage: storage,
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: _FakeTransport(),
        );
        await repo.enable();
        storage.writeFailures = 1;
        await repo.disable();
        expect(repo.isConsentEnabled, isFalse);
        expect(repo.needsDeletion, isTrue);
        expect(repo.consentPersistenceFailed, isTrue);
        expect(jsonDecode(storage.value!)['enabled'], isTrue);
        await repo.disable();
        expect(repo.consentPersistenceFailed, isFalse);
        expect(jsonDecode(storage.value!)['enabled'], isFalse);
        expect(jsonDecode(storage.value!)['deletionSecret'], isNotNull);
      },
    );

    test(
      'delete revokes before network and blocks re-enable until acknowledgment',
      () async {
        final transport = _FakeTransport()..deleteGate = Completer<void>();
        final repo = await AnalyticsRepository.load(
          queueStorage: _MemoryConsentStorage(),
          storage: _MemoryConsentStorage(),
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: transport,
        );
        await repo.enable();
        final deleting = repo.disableAndDelete();
        expect(repo.isConsentEnabled, isFalse);
        await repo.enable();
        expect(repo.isConsentEnabled, isFalse);
        transport.deleteGate!.complete();
        expect(await deleting, isTrue);
        await repo.enable();
        expect(repo.isConsentEnabled, isTrue);
      },
    );

    test('enable creates and persists a fresh identity', () async {
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
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
        queueStorage: _MemoryConsentStorage(),
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
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enqueue(
        _event(
          'pre_consent',
          installationId: repo.installationId ?? 'pre_consent',
        ),
      );
      await repo.flush();

      expect(transport.sentBatches, isEmpty);

      await repo.enable();
      await repo.flush();

      expect(transport.sentBatches, isEmpty);
    });

    test('transmits a validated event after enable', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.enqueue(
        _event(
          'post_consent',
          installationId: repo.installationId ?? 'pre_consent',
        ),
      );
      await repo.flush();

      expect(transport.sentBatches, hasLength(1));
      expect(transport.sentBatches.single.single.eventId, 'post_consent');
    });

    test('deduplicates events by id at the queue boundary', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      repo.enqueue(
        _event(
          'duplicate',
          installationId: repo.installationId ?? 'pre_consent',
        ),
      );
      repo.enqueue(
        _event(
          'duplicate',
          installationId: repo.installationId ?? 'pre_consent',
        ),
      );
      await repo.flush();

      expect(transport.sentBatches.single, hasLength(1));
    });

    test('retries a failed transmission without losing the event', () async {
      final transport = _FakeTransport()..sendFailures = 1;
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
        random: Random(1),
      );

      await repo.enable();
      await repo.enqueue(
        _event('retry', installationId: repo.installationId ?? 'pre_consent'),
      );
      await repo.flush();

      expect(transport.sentBatches.single.single.eventId, 'retry');
    });

    test(
      'disable stops collection, clears the queue and keeps identity',
      () async {
        final transport = _FakeTransport()..sendFailures = 1000;
        final storage = _MemoryConsentStorage();
        final repo = await AnalyticsRepository.load(
          queueStorage: _MemoryConsentStorage(),
          storage: storage,
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: transport,
          random: Random(1),
        );

        await repo.enable();
        await repo.enqueue(
          _event(
            'queued',
            installationId: repo.installationId ?? 'pre_consent',
          ),
        );
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
      },
    );

    test('re-enable creates a fresh identity and deletion secret', () async {
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
        random: Random(1),
      );

      await repo.enable();
      final first = repo.installationId;
      await repo.disableAndDelete();
      await repo.enable();
      final second = repo.installationId;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(second, isNot(first));
    });

    test('disableAndDelete clears identity on acknowledgment', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
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
        queueStorage: _MemoryConsentStorage(),
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

    test(
      'offline queue survives launch and sends bounded identity-bound batches',
      () async {
        final consent = _MemoryConsentStorage();
        final queue = _MemoryConsentStorage();
        final pending = _MemoryPendingRoundStorage();
        final transport = _FakeTransport()..sendFailures = 10000;
        final repo = await AnalyticsRepository.load(
          storage: consent,
          pendingRoundStorage: pending,
          queueStorage: queue,
          transport: transport,
        );
        await repo.enable();
        await repo.startRound(gameId: 'grammar', contentVersion: '1');
        for (var i = 0; i < 210; i++) {
          await repo.itemShown(itemId: 'variant_$i', itemIndex: i);
        }
        await repo.flush();
        final online = _FakeTransport();
        final relaunched = await AnalyticsRepository.load(
          storage: consent,
          pendingRoundStorage: pending,
          queueStorage: queue,
          transport: online,
        );
        await relaunched.flush();
        expect(online.sentBatches.single.length, lessThanOrEqualTo(100));
        expect(
          utf8
              .encode(
                jsonEncode({
                  'deletionSecret': 'x' * 43,
                  'events': online.sentBatches.single
                      .map((e) => e.toJson())
                      .toList(),
                }),
              )
              .length,
          lessThanOrEqualTo(60000),
        );
        await relaunched.flush();
        await relaunched.flush();
        expect(online.sentBatches.expand((b) => b).length, 211);
        await relaunched.disable();
        final revoked = await AnalyticsRepository.load(
          storage: consent,
          pendingRoundStorage: pending,
          queueStorage: queue,
          transport: online,
        );
        await revoked.flush();
        expect(online.sentBatches.expand((b) => b).length, 211);
      },
    );

    test('failed in-flight send cannot requeue after deletion', () async {
      final transport = _FakeTransport()..sendGate = Completer<void>();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
        storage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: transport,
      );
      await repo.enable();
      await repo.startRound(gameId: 'grammar', contentVersion: '1');
      await Future<void>.delayed(Duration.zero);
      final deleting = repo.disableAndDelete();
      expect(repo.isConsentEnabled, isFalse);
      expect(transport.deletions, isEmpty);
      transport.sendGate!.completeError(StateError('offline'));
      expect(await deleting, isTrue);
      transport.sendGate = null;
      await repo.enable();
      await repo.flush();
      expect(transport.sentBatches, isEmpty);
    });

    test(
      'session actions serialize while snapshot storage is delayed',
      () async {
        final pending = _MemoryConsentStorage()..writeGate = Completer<void>();
        final transport = _FakeTransport();
        final repo = await AnalyticsRepository.load(
          queueStorage: pending,
          storage: _MemoryConsentStorage(),
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: transport,
        );
        await repo.enable();
        final start = repo.startRound(gameId: 'grammar', contentVersion: '1');
        final shown = repo.itemShown(itemId: 'variant_1', itemIndex: 0);
        final answer = repo.itemAnswered(
          itemId: 'variant_1',
          itemIndex: 0,
          outcome: AnalyticsOutcome.correct,
        );
        final end = repo.endRound(reason: AnalyticsRoundEndReason.userBack);
        pending.writeGate!.complete();
        await Future.wait([start, shown, answer, end]);
        await repo.flush();
        final events = transport.sentBatches.expand((b) => b).toList();
        expect(events.map((e) => e.kind.wireName), [
          'round_started',
          'item_shown',
          'item_answered',
          'item_resolved',
          'round_ended',
        ]);
        expect(events.map((e) => e.sessionId).toSet(), hasLength(1));
        expect(events.last.toJson()['itemState'], 'resolved');
      },
    );

    test(
      'revoked consent is durable before interrupted queue cleanup',
      () async {
        final consent = _MemoryConsentStorage();
        final queue = _MemoryConsentStorage();
        final pending = _MemoryPendingRoundStorage();
        final offline = _FakeTransport()..sendFailures = 100;
        final repo = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: offline,
        );
        await repo.enable();
        await repo.startRound(gameId: 'grammar', contentVersion: '1');
        await repo.itemShown(itemId: 'a', itemIndex: 0);
        await repo.flush();
        queue.writeGate = Completer<void>();
        final disabling = repo.disable();
        await Future<void>.delayed(Duration.zero);
        final saved = jsonDecode(consent.value!) as Map<String, dynamic>;
        expect(saved['enabled'], isFalse);
        expect(saved['needsDeletion'], isTrue);
        expect(saved['deletionSecret'], isNotNull);
        final online = _FakeTransport();
        final relaunched = await AnalyticsRepository.load(
          storage: consent,
          queueStorage: queue,
          pendingRoundStorage: pending,
          transport: online,
        );
        await relaunched.reconcileInterruptedRound();
        await relaunched.flush();
        expect(online.sentBatches, isEmpty);
        await relaunched.enable();
        expect(relaunched.isConsentEnabled, isFalse);
        queue.writeGate!.complete();
        await disabling;
      },
    );

    test(
      'large UTF-8 events respect the batch byte limit before the count cap',
      () async {
        final transport = _FakeTransport()..sendFailures = 1000;
        final repo = await AnalyticsRepository.load(
          queueStorage: _MemoryConsentStorage(),
          storage: _MemoryConsentStorage(),
          pendingRoundStorage: _MemoryPendingRoundStorage(),
          transport: transport,
        );
        await repo.enable();
        for (var i = 0; i < 110; i++) {
          await repo.enqueue(
            AnalyticsEvent(
              eventId: '${'字' * 120}$i',
              sessionId: '字' * 128,
              installationId: repo.installationId!,
              gameId: 'grammar',
              contentVersion: '字' * 64,
              itemId: '字' * 128,
              itemIndex: i,
              timestampUtc: DateTime.now().toUtc(),
              kind: AnalyticsEventKind.itemShown,
            ),
          );
        }
        await repo.flush();
        transport.sendFailures = 0;
        await repo.flush();
        final batch = transport.sentBatches.single;
        expect(batch.length, lessThan(100));
        final bytes = utf8
            .encode(
              jsonEncode({
                'deletionSecret': 'x' * 43,
                'events': batch.map((e) => e.toJson()).toList(),
              }),
            )
            .length;
        expect(bytes, lessThanOrEqualTo(60000));
      },
    );

    test('session methods emit the round lifecycle in order', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
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
      expect(events.map((e) => e.kind), [
        AnalyticsEventKind.roundStarted,
        AnalyticsEventKind.itemShown,
        AnalyticsEventKind.itemAnswered,
        AnalyticsEventKind.itemResolved,
        AnalyticsEventKind.roundEnded,
      ]);
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
      final queue = _MemoryConsentStorage();
      final pendingStorage = _MemoryPendingRoundStorage();
      final repo = await AnalyticsRepository.load(
        queueStorage: queue,
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
        queueStorage: queue,
        storage: consentStorage,
        pendingRoundStorage: pendingStorage,
        transport: transport,
        random: Random(1),
      );
      await relaunched.reconcileInterruptedRound(gameId: 'grammar');
      await relaunched.flush();

      final events = transport.sentBatches.expand((batch) => batch).toList();
      expect(events.last.kind, AnalyticsEventKind.roundEnded);
      expect(events.last.reason, AnalyticsRoundEndReason.inferredInterruption);
      expect(events.last.itemId, 'n1');
      expect(events.last.itemIndex, 0);
    });

    test(
      'endRound supports restart without marking the shown item wrong',
      () async {
        final transport = _FakeTransport();
        final repo = await AnalyticsRepository.load(
          queueStorage: _MemoryConsentStorage(),
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
      },
    );

    test('session methods no-op without consent', () async {
      final transport = _FakeTransport();
      final repo = await AnalyticsRepository.load(
        queueStorage: _MemoryConsentStorage(),
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

AnalyticsEvent _event(String id, {required String installationId}) {
  return AnalyticsEvent(
    eventId: id,
    sessionId: 's_1',
    installationId: installationId,
    gameId: 'grammar',
    contentVersion: 'bundled',
    timestampUtc: DateTime.utc(2026),
    kind: AnalyticsEventKind.roundStarted,
  );
}

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;
  void Function(String)? onWrite;
  int readFailures = 0;
  int writeFailures = 0;
  Completer<void>? writeGate;

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
    await writeGate?.future;
    if (writeFailures-- > 0) throw StateError('disk write failed');
    value = updated;
    onWrite?.call(updated);
  }
}

final class _MemoryPendingRoundStorage implements PendingRoundStorage {
  String? value;
  int clearFailures = 0;
  Completer<void>? writeGate;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    await writeGate?.future;
    value = updated;
  }

  @override
  Future<void> clear() async {
    if (clearFailures-- > 0) throw StateError('interrupted cleanup');
    value = null;
  }
}

final class _FakeTransport implements AnalyticsTransport {
  final List<List<AnalyticsEvent>> sentBatches = [];
  final List<Map<String, String>> deletions = [];
  int sendFailures = 0;
  int deleteFailures = 0;
  Completer<void>? deleteGate;
  Completer<void>? sendGate;

  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> events, {
    String? deletionSecret,
  }) async {
    await sendGate?.future;
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
    await deleteGate?.future;
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
