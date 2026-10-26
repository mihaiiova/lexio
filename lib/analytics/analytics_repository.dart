import 'dart:convert';
import 'dart:math';

import 'analytics_event.dart';
import 'analytics_identity.dart';
import 'analytics_transport.dart';
import 'consent_storage.dart';
import 'event_queue.dart';
import 'pending_round.dart';

/// Orchestrates consent, identity, the offline queue, and round sessions.
///
/// Collection is fully gated on consent: when consent is off every public
/// event/session method is a no-op. Network failures never surface to the UI;
/// events stay queued for a later retry.
final class AnalyticsRepository {
  static const _consentKey = 'analytics_consent_v1';
  static const _pendingRoundKey = 'analytics_pending_round_v1';

  AnalyticsRepository._(
    this._consentStorage,
    this._pendingRoundStorage,
    this._transport,
    this._random,
    this._consent,
    this._consentWasPersisted,
    this._pendingRound,
    this._queueStorage,
    this._clock,
  );

  final ConsentStorage? _consentStorage;
  final PendingRoundStorage? _pendingRoundStorage;
  final ConsentStorage? _queueStorage;
  Future<void> _queueWrites = Future<void>.value();
  bool _flushScheduled = false;
  final AnalyticsTransport _transport;
  final Random _random;
  final DateTime Function() _clock;
  bool _snapshotDurable = false;
  int _snapshotRevision = 0;
  final AnalyticsEventQueue _queue = AnalyticsEventQueue();

  ConsentState _consent;
  bool _consentWasPersisted;
  bool _consentPersistenceFailed = false;
  PendingRound? _pendingRound;
  bool _hasInterruptedRound = false;
  int _generation = 0;
  Future<void> _operations = Future<void>.value();

  Future<void> _serialize(Future<void> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.catchError((Object _) {});
    return result;
  }

  Future<void> _flushQueue = Future<void>.value();

  static Future<AnalyticsRepository> load({
    ConsentStorage? storage,
    ConsentStorage? queueStorage,
    PendingRoundStorage? pendingRoundStorage,
    AnalyticsTransport? transport,
    Random? random,
    DateTime Function()? clock,
  }) async {
    ConsentStorage? effectiveStorage = storage;
    ConsentState consent = ConsentState.disabled;
    var consentWasPersisted = false;

    try {
      effectiveStorage ??= SharedPreferencesConsentStorage(_consentKey);
      final source = await effectiveStorage.read();
      if (source == null) {
        consent = ConsentState.disabled;
        consentWasPersisted = false;
      } else {
        consent = ConsentState.fromJson(
          jsonDecode(source) as Map<String, dynamic>,
        );
        consentWasPersisted = true;
      }
    } catch (_) {
      // Unknown or failed storage resolves to off and, to avoid an endless
      // first-launch prompt, is treated as already decided.
      effectiveStorage = null;
      consent = ConsentState.disabled;
      consentWasPersisted = true;
    }

    if (consent.needsDeletion) consent = consent.copyWith(enabled: false);
    if (consent.enabled && !consent.hasIdentity) {
      consent = ConsentState.disabled;
    }

    PendingRoundStorage? effectivePendingStorage = pendingRoundStorage;
    PendingRound? pendingRound;
    try {
      effectivePendingStorage ??= SharedPreferencesPendingRoundStorage(
        _pendingRoundKey,
      );
      final source = await effectivePendingStorage.read();
      if (source != null) {
        pendingRound = PendingRound.fromJson(
          jsonDecode(source) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      effectivePendingStorage = null;
      pendingRound = null;
    }

    ConsentStorage? effectiveQueueStorage = queueStorage;
    try {
      effectiveQueueStorage ??= SharedPreferencesConsentStorage(
        'analytics_queue_v1',
      );
    } catch (_) {
      // Queue persistence may be unavailable; gameplay must remain offline-safe.
    }
    final repository = AnalyticsRepository._(
      effectiveStorage,
      effectivePendingStorage,
      transport ?? HttpAnalyticsTransport(),
      random ?? Random.secure(),
      consent,
      consentWasPersisted,
      pendingRound,
      effectiveQueueStorage,
      clock ?? DateTime.now,
    );
    try {
      final source = await repository._queueStorage?.read();
      if (source != null && consent.enabled) {
        final saved = jsonDecode(source) as Map<String, dynamic>;
        if (saved['installationId'] == consent.installationId) {
          if (saved.containsKey('pendingRound')) {
            repository._pendingRound = saved['pendingRound'] == null
                ? null
                : PendingRound.fromJson(
                    saved['pendingRound'] as Map<String, dynamic>,
                  );
          }
          for (final entry in (saved['events'] as List).take(1000)) {
            final event = AnalyticsEvent.fromJson(
              entry as Map<String, dynamic>,
            );
            if (event.installationId == consent.installationId) {
              repository._queue.add(event);
            }
          }
        }
      }
    } catch (_) {
      // Unknown, malformed, or unavailable queue data is never transmitted.
      repository._queue.clear();
    }
    repository._snapshotDurable = true;
    if (!consent.enabled) {
      repository._pendingRound = null;
      await repository._clearPendingRoundStorage();
    }
    if (repository._pendingRound?.installationId != consent.installationId) {
      repository._pendingRound = null;
      await repository._clearPendingRoundStorage();
    }
    repository._hasInterruptedRound = repository._pendingRound != null;
    return repository;
  }

  bool get isConsentEnabled => _consent.enabled;

  /// True until the user has made a first-launch consent decision.
  bool get isConsentUndecided => !_consentWasPersisted;

  bool get consentPersistenceFailed => _consentPersistenceFailed;

  bool get needsDeletion => _consent.needsDeletion;

  bool get hasRetainedIdentity => _consent.hasIdentity;

  bool get isServerConfigured => _transport.isConfigured;

  String? get installationId =>
      _consent.enabled ? _consent.installationId : null;

  /// Resumes the retained identity, or creates one after first opt-in/deletion.
  Future<void> enable() {
    final generation = _generation;
    if (_consentStorage == null) _consentPersistenceFailed = true;
    if (_consentStorage == null || needsDeletion || _consent.enabled) {
      return Future<void>.value();
    }
    return _serialize(() async {
      if (generation != _generation || needsDeletion || _consent.enabled) {
        return;
      }
      if (_consent.hasIdentity) {
        // A failed withdrawal cleanup must not replay old events on resuming.
        await _persistQueue();
        if (generation != _generation || needsDeletion) return;
        if (!_snapshotDurable) {
          _consentPersistenceFailed = true;
          return;
        }
      }
      final identity = _consent.hasIdentity
          ? AnalyticsIdentity(
              installationId: _consent.installationId!,
              deletionSecret: _consent.deletionSecret!,
            )
          : AnalyticsIdentity.generate(random: _random);
      final next = ConsentState(
        enabled: true,
        installationId: identity.installationId,
        deletionSecret: identity.deletionSecret,
      );
      try {
        await _consentStorage.write(encodeConsentState(next));
        _consentPersistenceFailed = false;
        _consentWasPersisted = true;
        _consent = generation == _generation
            ? next
            : next.copyWith(
                enabled: false,
                needsDeletion: _consent.needsDeletion,
              );
      } catch (_) {
        _consentPersistenceFailed = true;
        // Never publish a consent decision that was not durably written.
      }
    });
  }

  void _revoke({required bool requestDeletion}) {
    _generation++;
    _consent = _consent.copyWith(
      enabled: false,
      needsDeletion: _consent.needsDeletion || requestDeletion,
    );
    _consentWasPersisted = true;
    _queue.clear();
    _pendingRound = null;
    _hasInterruptedRound = false;
  }

  Future<void> decline() => disable();

  Future<void> disable() => _disable(requestDeletion: false);

  Future<void> _disable({required bool requestDeletion}) {
    _revoke(requestDeletion: requestDeletion);
    return _serialize(() async {
      await _persistConsent();
      await _persistQueue();
      await _clearPendingRoundStorage();
    });
  }

  Future<bool> disableAndDelete() async {
    final disabling = _disable(requestDeletion: true);
    await disabling;
    await _flushQueue; // An older send must finish before its identity is deleted.
    final identity = _consent;
    if (identity.hasIdentity) {
      try {
        await _transport.requestDeletion(
          installationId: identity.installationId!,
          deletionSecret: identity.deletionSecret!,
        );
      } catch (_) {
        return false;
      }
    }
    var persisted = false;
    await _serialize(() async {
      if (_consent.installationId != identity.installationId) {
        persisted = true;
        return;
      }
      try {
        await _consentStorage!.write(encodeConsentState(ConsentState.disabled));
        _consent = ConsentState.disabled;
        _consentPersistenceFailed = false;
        persisted = true;
      } catch (_) {
        _consentPersistenceFailed = true;
        // Keep the retry credential until acknowledgment is durably recorded.
      }
    });
    return persisted;
  }

  /// Queues a validated event for transmission when consent is enabled.
  ///
  /// This is intentionally nonblocking and never throws to the UI.
  Future<void> enqueue(AnalyticsEvent event) async {
    if (!_consent.enabled || event.installationId != _consent.installationId) {
      return;
    }
    try {
      event.validate();
    } catch (_) {
      return;
    }
    if (!_queue.add(event)) return;
    await _persistQueue();
    _scheduleFlush();
  }

  /// One bounded attempt per retry point; never loops while offline.
  Future<void> flush() async {
    await _operations;
    await _queueWrites;
    if (_flushScheduled) await _flushQueue;
    _scheduleFlush();
    await _flushQueue;
  }

  Future<void> _persistQueue() {
    _snapshotDurable = false;
    final generation = _generation;
    final revision = ++_snapshotRevision;
    _queueWrites = _queueWrites.then((_) async {
      try {
        if (_queueStorage == null) return;
        await _queueStorage.write(
          jsonEncode({
            // Empty snapshots must override uncleared legacy rounds on resume.
            'installationId': _consent.installationId,
            'events': _queue.events.map((event) => event.toJson()).toList(),
            'pendingRound': _pendingRound?.toJson(),
          }),
        );
        if (generation == _generation && revision == _snapshotRevision) {
          _snapshotDurable = true;
        }
      } catch (_) {
        _snapshotDurable = false;
        // No send until the complete snapshot is durable. Total I/O failure
        // remains best-effort: gameplay continues, but crash loss is possible.
      }
    });
    return _queueWrites;
  }

  Future<void> _sessionAction(Future<void> Function() action) {
    final generation = _generation;
    if (!_consent.enabled) return Future<void>.value();
    return _serialize(() async {
      if (generation != _generation || !_consent.enabled) return;
      await action();
    });
  }

  Future<void> startRound({
    required String gameId,
    required String contentVersion,
  }) => _sessionAction(() async {
    if (_pendingRound != null) {
      await _endRound(
        _hasInterruptedRound
            ? AnalyticsRoundEndReason.inferredInterruption
            : AnalyticsRoundEndReason.restart,
      );
      _hasInterruptedRound = false;
    }
    if (!_consent.enabled) return;
    _pendingRound = PendingRound(
      sessionId: _randomToken(),
      installationId: _consent.installationId!,
      gameId: gameId,
      contentVersion: contentVersion,
      startedAtUtc: _clock().toUtc(),
    );
    final event = _newEvent(
      sessionId: _pendingRound!.sessionId,
      kind: AnalyticsEventKind.roundStarted,
    );
    await _commitEvents([event]);
  });

  Future<void> itemShown({required String itemId, required int itemIndex}) =>
      _sessionAction(() async {
        final pending = _pendingRound;
        if (pending == null ||
            (pending.lastShownItemId == itemId &&
                pending.lastShownItemIndex == itemIndex)) {
          return;
        }
        _pendingRound = pending.copyWith(
          lastShownItemId: itemId,
          lastShownItemIndex: itemIndex,
          itemResolved: false,
          lastActivityAtUtc: _clock().toUtc(),
        );
        final event = _newEvent(
          sessionId: pending.sessionId,
          kind: AnalyticsEventKind.itemShown,
          itemId: itemId,
          itemIndex: itemIndex,
        );
        await _commitEvents([event]);
      });

  Future<void> itemAnswered({
    required String itemId,
    required int itemIndex,
    required AnalyticsOutcome outcome,
  }) => _sessionAction(() async {
    final pending = _pendingRound;
    if (pending == null ||
        pending.itemResolved ||
        pending.lastShownItemId != itemId ||
        pending.lastShownItemIndex != itemIndex) {
      return;
    }
    _pendingRound = pending.copyWith(
      itemResolved: true,
      lastActivityAtUtc: _clock().toUtc(),
    );
    final answered = _newEvent(
      sessionId: pending.sessionId,
      kind: AnalyticsEventKind.itemAnswered,
      itemId: itemId,
      itemIndex: itemIndex,
      outcome: outcome,
    );
    final resolved = _newEvent(
      sessionId: pending.sessionId,
      kind: AnalyticsEventKind.itemResolved,
      itemId: itemId,
      itemIndex: itemIndex,
    );
    await _commitEvents([answered, resolved]);
  });

  /// One in-play press. Word positions are used only for local deduplication.
  /// The discovery flag observes gameplay; it does not change scoring sets.
  Future<void> spotAttempt({
    required String itemId,
    required int itemIndex,
    required int wordPosition,
    required bool newlyCorrect,
    required bool isWrong,
    bool resolvesItem = false,
  }) => _sessionAction(() async {
    final pending = _pendingRound;
    if (pending == null ||
        pending.gameId != 'spot' ||
        pending.lastShownItemId != itemId ||
        pending.lastShownItemIndex != itemIndex ||
        wordPosition < 0 ||
        (newlyCorrect && isWrong)) {
      return;
    }
    final key = '$itemIndex:$wordPosition';
    final distinctWrong = isWrong && !pending.spotWrongPositions.contains(key);
    final resolves = resolvesItem && !pending.itemResolved;
    _pendingRound = pending.copyWith(
      lastActivityAtUtc: _clock().toUtc(),
      itemResolved: pending.itemResolved || resolves,
      spotWrongPositions: distinctWrong
          ? Set.unmodifiable({...pending.spotWrongPositions, key})
          : pending.spotWrongPositions,
    );
    await _commitEvents([
      _newEvent(
        sessionId: pending.sessionId,
        kind: AnalyticsEventKind.spotAttempt,
        itemId: itemId,
        itemIndex: itemIndex,
        attemptDelta: 1,
        correctDiscoveryDelta: newlyCorrect ? 1 : 0,
        distinctWrongDelta: distinctWrong ? 1 : 0,
      ),
      if (resolves)
        _newEvent(
          sessionId: pending.sessionId,
          kind: AnalyticsEventKind.itemResolved,
          itemId: itemId,
          itemIndex: itemIndex,
        ),
    ]);
  });

  /// Explicit text completion, including an already-complete empty-mistake text.
  Future<void> itemResolved({required String itemId, required int itemIndex}) =>
      _sessionAction(() async {
        final pending = _pendingRound;
        if (pending == null ||
            pending.itemResolved ||
            pending.gameId != 'spot' ||
            pending.lastShownItemId != itemId ||
            pending.lastShownItemIndex != itemIndex) {
          return;
        }
        _pendingRound = pending.copyWith(
          itemResolved: true,
          lastActivityAtUtc: _clock().toUtc(),
        );
        await _commitEvents([
          _newEvent(
            sessionId: pending.sessionId,
            kind: AnalyticsEventKind.itemResolved,
            itemId: itemId,
            itemIndex: itemIndex,
          ),
        ]);
      });

  Future<void> endRound({
    required AnalyticsRoundEndReason reason,
    String? itemId,
    int? itemIndex,
  }) => _sessionAction(() => _endRound(reason));

  Future<void> _endRound(AnalyticsRoundEndReason reason) async {
    final pending = _pendingRound;
    if (pending == null) return;
    final event = _newEvent(
      sessionId: pending.sessionId,
      kind: AnalyticsEventKind.roundEnded,
      itemId: pending.lastShownItemId,
      itemIndex: pending.lastShownItemIndex,
      reason: reason,
      timestampUtc: reason == AnalyticsRoundEndReason.inferredInterruption
          ? _boundedActivity(pending)
          : null,
      itemState: pending.lastShownItemId == null
          ? null
          : pending.itemResolved
          ? AnalyticsItemState.resolved
          : AnalyticsItemState.unresolved,
    );
    _pendingRound = null;
    await _commitEvents([event]);
    await _clearPendingRoundStorage();
  }

  /// Called once at app launch, regardless of the interrupted game's identity.
  Future<void> reconcileInterruptedRound({String? gameId}) =>
      _sessionAction(() async {
        if (!_hasInterruptedRound) return;
        _hasInterruptedRound = false;
        await _endRound(AnalyticsRoundEndReason.inferredInterruption);
      });

  AnalyticsEvent _newEvent({
    required String sessionId,
    required AnalyticsEventKind kind,
    String? itemId,
    int? itemIndex,
    AnalyticsOutcome? outcome,
    AnalyticsRoundEndReason? reason,
    AnalyticsItemState? itemState,
    DateTime? timestampUtc,
    int? attemptDelta,
    int? correctDiscoveryDelta,
    int? distinctWrongDelta,
  }) {
    final pending = _pendingRound;
    return AnalyticsEvent(
      // Legacy terminal retries and snapshot replays share one identity.
      eventId: kind == AnalyticsEventKind.roundEnded
          ? sessionId
          : _randomToken(),
      sessionId: sessionId,
      installationId: _consent.installationId!,
      gameId: pending!.gameId,
      contentVersion: pending.contentVersion,
      itemId: itemId,
      itemIndex: itemIndex,
      timestampUtc: timestampUtc ?? _clock().toUtc(),
      kind: kind,
      outcome: outcome,
      reason: reason,
      itemState: itemState,
      attemptDelta: attemptDelta,
      correctDiscoveryDelta: correctDiscoveryDelta,
      distinctWrongDelta: distinctWrongDelta,
    );
  }

  void _scheduleFlush() {
    if (_flushScheduled || !_consent.enabled) return;
    _flushScheduled = true;
    _flushQueue = _flushQueue.then((_) => _flush()).whenComplete(() {
      _flushScheduled = false;
    });
  }

  Future<void> _flush() async {
    await _operations;
    await _queueWrites;
    if (!_consent.enabled || !_snapshotDurable) return;
    final generation = _generation;
    final secret = _consent.deletionSecret;
    final events = _queue.batch();
    if (events.isEmpty) return;
    try {
      await _transport.sendEvents(events, deletionSecret: secret);
      if (generation != _generation || !_consent.enabled) return;
      await _serialize(() async {
        if (generation != _generation || !_consent.enabled) return;
        _queue.acknowledge(events);
        await _persistQueue();
      });
    } catch (_) {
      // Events stay in their identity-bound queue; revocation clears it.
    }
  }

  Future<void> _persistConsent() async {
    final storage = _consentStorage;
    if (storage == null) {
      _consentPersistenceFailed = true;
      return;
    }
    try {
      await storage.write(encodeConsentState(_consent));
      _consentPersistenceFailed = false;
    } catch (_) {
      _consentPersistenceFailed = true;
      // The UI must warn that this process is off but the setting was not saved.
    }
  }

  // State and all events for an action share one atomic storage value. In
  // particular an answer and its resolution can never be recovered separately.
  Future<void> _commitEvents(List<AnalyticsEvent> events) async {
    if (!_consent.enabled) return;
    for (final event in events) {
      event.validate();
      _queue.add(event);
    }
    await _persistQueue();
    _scheduleFlush();
  }

  DateTime _boundedActivity(PendingRound pending) {
    final now = _clock().toUtc();
    final activity = pending.lastActivityAtUtc ?? pending.startedAtUtc;
    // This is an activity estimate, not an observed termination time. A clock
    // rollback must not put the inferred event in the recovery-time future.
    return activity.isAfter(now) ? now : activity;
  }

  Future<void> _clearPendingRoundStorage() async {
    final storage = _pendingRoundStorage;
    if (storage == null) return;
    try {
      await storage.clear();
    } catch (_) {
      // Best-effort only.
    }
  }

  String _randomToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
