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
  );

  final ConsentStorage? _consentStorage;
  final PendingRoundStorage? _pendingRoundStorage;
  final AnalyticsTransport _transport;
  final Random _random;
  final AnalyticsEventQueue _queue = AnalyticsEventQueue();

  ConsentState _consent;
  bool _consentWasPersisted;
  PendingRound? _pendingRound;
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
    PendingRoundStorage? pendingRoundStorage,
    AnalyticsTransport? transport,
    Random? random,
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

    return AnalyticsRepository._(
      effectiveStorage,
      effectivePendingStorage,
      transport ?? HttpAnalyticsTransport(),
      random ?? Random.secure(),
      consent,
      consentWasPersisted,
      pendingRound,
    );
  }

  bool get isConsentEnabled => _consent.enabled;

  /// True until the user has made a first-launch consent decision.
  bool get isConsentUndecided => !_consentWasPersisted;

  bool get needsDeletion => _consent.needsDeletion;

  String? get installationId =>
      _consent.enabled ? _consent.installationId : null;

  /// Enables collection with a fresh installation identity and deletion secret.
  Future<void> enable() {
    final generation = _generation;
    if (_consentStorage == null || needsDeletion || _consent.enabled) {
      return Future<void>.value();
    }
    return _serialize(() async {
      if (generation != _generation || needsDeletion || _consent.enabled) return;
      final identity = AnalyticsIdentity.generate(random: _random);
      final next = ConsentState(enabled: true,
        installationId: identity.installationId,
        deletionSecret: identity.deletionSecret);
      try {
        await _consentStorage.write(encodeConsentState(next));
        _consentWasPersisted = true;
        _consent = generation == _generation
            ? next : next.copyWith(enabled: false, needsDeletion: true);
      } catch (_) {
        // Never publish a consent decision that was not durably written.
      }
    });
  }

  void _revoke() {
    _generation++;
    _consent = _consent.copyWith(enabled: false,
      needsDeletion: _consent.hasIdentity);
    _consentWasPersisted = true;
    _queue.clear();
    _pendingRound = null;
  }

  Future<void> decline() => disable();

  Future<void> disable() {
    _revoke();
    return _serialize(() async {
      await _clearPendingRoundStorage();
      await _persistConsent();
    });
  }

  Future<bool> disableAndDelete() async {
    final disabling = disable(); // Revocation occurs before the first await.
    await disabling;
    await _flushQueue; // An older send must finish before its identity is deleted.
    final identity = _consent;
    if (!identity.hasIdentity) return true;
    try {
      await _transport.requestDeletion(
        installationId: identity.installationId!,
        deletionSecret: identity.deletionSecret!);
    } catch (_) {
      return false;
    }
    var persisted = false;
    await _serialize(() async {
      try {
        await _consentStorage!.write(encodeConsentState(ConsentState.disabled));
        _consent = ConsentState.disabled;
        persisted = true;
      } catch (_) {
        // Keep the retry credential until acknowledgment is durably recorded.
      }
    });
    return persisted;
  }

  /// Queues a validated event for transmission when consent is enabled.
  ///
  /// This is intentionally nonblocking and never throws to the UI.
  Future<void> enqueue(AnalyticsEvent event) {
    if (!_consent.enabled) return Future<void>.value();
    try {
      event.validate();
    } catch (_) {
      return Future<void>.value();
    }
    if (!_queue.add(event)) return Future<void>.value();
    _scheduleFlush();
    return Future<void>.value();
  }

  /// Waits for any in-flight transmission and attempts any remaining queue
  /// (test support and explicit retry point).
  Future<void> flush() {
    _scheduleFlush();
    return _flushQueue;
  }

  Future<void> _sessionAction(Future<void> Function() action) {
    final generation = _generation;
    if (!_consent.enabled) return Future<void>.value();
    return _serialize(() async {
      if (generation != _generation || !_consent.enabled) return;
      await action();
    });
  }

  Future<void> startRound({required String gameId, required String contentVersion}) =>
      _sessionAction(() async {
    if (_pendingRound != null) await _endRound(AnalyticsRoundEndReason.restart);
    _pendingRound = PendingRound(sessionId: _randomToken(), gameId: gameId,
      contentVersion: contentVersion, startedAtUtc: DateTime.now().toUtc());
    final event = _newEvent(sessionId: _pendingRound!.sessionId,
      kind: AnalyticsEventKind.roundStarted);
    await _persistPendingRound();
    await enqueue(event);
  });

  Future<void> itemShown({required String itemId, required int itemIndex}) =>
      _sessionAction(() async {
    final pending = _pendingRound;
    if (pending == null || (pending.lastShownItemId == itemId &&
        pending.lastShownItemIndex == itemIndex)) return;
    _pendingRound = pending.copyWith(lastShownItemId: itemId,
      lastShownItemIndex: itemIndex, itemResolved: false);
    final event = _newEvent(sessionId: pending.sessionId,
      kind: AnalyticsEventKind.itemShown, itemId: itemId, itemIndex: itemIndex);
    await _persistPendingRound();
    await enqueue(event);
  });

  Future<void> itemAnswered({required String itemId, required int itemIndex,
    required AnalyticsOutcome outcome}) => _sessionAction(() async {
    final pending = _pendingRound;
    if (pending == null || pending.itemResolved ||
        pending.lastShownItemId != itemId || pending.lastShownItemIndex != itemIndex) return;
    _pendingRound = pending.copyWith(itemResolved: true);
    final answered = _newEvent(sessionId: pending.sessionId,
      kind: AnalyticsEventKind.itemAnswered, itemId: itemId, itemIndex: itemIndex,
      outcome: outcome);
    final resolved = _newEvent(sessionId: pending.sessionId,
      kind: AnalyticsEventKind.itemResolved, itemId: itemId, itemIndex: itemIndex);
    await _persistPendingRound();
    await enqueue(answered);
    await enqueue(resolved);
  });

  Future<void> endRound({required AnalyticsRoundEndReason reason,
    String? itemId, int? itemIndex}) => _sessionAction(() => _endRound(reason));

  Future<void> _endRound(AnalyticsRoundEndReason reason) async {
    final pending = _pendingRound;
    if (pending == null) return;
    final event = _newEvent(sessionId: pending.sessionId,
      kind: AnalyticsEventKind.roundEnded, itemId: pending.lastShownItemId,
      itemIndex: pending.lastShownItemIndex, reason: reason,
      itemState: pending.lastShownItemId == null ? null : pending.itemResolved
        ? AnalyticsItemState.resolved : AnalyticsItemState.unresolved);
    _pendingRound = null;
    await enqueue(event);
    await _clearPendingRoundStorage();
  }

  /// Called once at app launch, regardless of the interrupted game's identity.
  Future<void> reconcileInterruptedRound({String? gameId}) =>
      _sessionAction(() => _endRound(AnalyticsRoundEndReason.inferredInterruption));

  AnalyticsEvent _newEvent({
    required String sessionId,
    required AnalyticsEventKind kind,
    String? itemId,
    int? itemIndex,
    AnalyticsOutcome? outcome,
    AnalyticsRoundEndReason? reason,
    AnalyticsItemState? itemState,
    DateTime? timestampUtc,
  }) {
    final pending = _pendingRound;
    return AnalyticsEvent(
      eventId: _randomToken(),
      sessionId: sessionId,
      installationId: _consent.installationId!,
      gameId: pending!.gameId,
      contentVersion: pending.contentVersion,
      itemId: itemId,
      itemIndex: itemIndex,
      timestampUtc: timestampUtc ?? DateTime.now().toUtc(),
      kind: kind,
      outcome: outcome,
      reason: reason,
      itemState: itemState,
    );
  }

  void _scheduleFlush() {
    _flushQueue = _flushQueue.then((_) => _flush());
  }

  Future<void> _flush() async {
    if (!_consent.enabled) return;
    final generation = _generation;
    final secret = _consent.deletionSecret;
    final events = _queue.drain();
    if (events.isEmpty) return;
    try {
      await _transport.sendEvents(events, deletionSecret: secret);
    } catch (_) {
      if (generation != _generation || !_consent.enabled) return;
      for (final event in events) {
        _queue.add(event);
      }
    }
  }

  Future<void> _persistConsent() async {
    final storage = _consentStorage;
    if (storage == null) return;
    try {
      await storage.write(encodeConsentState(_consent));
    } catch (_) {
      // Persistence is best-effort; the in-memory decision still applies.
    }
  }

  Future<void> _persistPendingRound() async {
    final storage = _pendingRoundStorage;
    final pending = _pendingRound;
    if (storage == null || pending == null) return;
    try {
      await storage.write(encodePendingRound(pending));
    } catch (_) {
      // Best-effort only.
    }
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
