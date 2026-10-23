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
  Future<void> enable() async {
    final identity = AnalyticsIdentity.generate(random: _random);
    if (_consentStorage == null || needsDeletion || _consent.enabled) return;
    final next = ConsentState(
      enabled: true,
      installationId: identity.installationId,
      deletionSecret: identity.deletionSecret,
    );
    try {
      await _consentStorage.write(encodeConsentState(next));
      _consent = next;
      _consentWasPersisted = true;
      _pendingRound = null;
      await _clearPendingRoundStorage();
    } catch (_) {
      _consent = ConsentState.disabled;
    }
  }

  /// Records a first-launch decline without any identity to delete.
  Future<void> decline() async {
    _consent = ConsentState.disabled;
    _consentWasPersisted = true;
    _queue.clear();
    _pendingRound = null;
    await _clearPendingRoundStorage();
    await _persistConsent();
  }

  /// Stops collection, clears the queue, and marks the retained identity as
  /// needing server-side deletion.
  Future<void> disable() async {
    final hadIdentity = _consent.hasIdentity;
    _consent = _consent.copyWith(
      enabled: false,
      needsDeletion: hadIdentity,
    );
    _consentWasPersisted = true;
    _queue.clear();
    _pendingRound = null;
    await _clearPendingRoundStorage();
    await _persistConsent();
  }

  /// Requests server deletion for the retained identity and clears it on
  /// acknowledgment. Returns false when the request failed and must be retried.
  Future<bool> disableAndDelete() async {
    final installationId = _consent.installationId;
    final deletionSecret = _consent.deletionSecret;
    _queue.clear();

    if (!_consent.hasIdentity) {
      _consent = ConsentState.disabled;
      _consentWasPersisted = true;
      _pendingRound = null;
      await _clearPendingRoundStorage();
      await _persistConsent();
      return true;
    }

    try {
      await _transport.requestDeletion(
        installationId: installationId!,
        deletionSecret: deletionSecret!,
      );
    } catch (_) {
      _consent = _consent.copyWith(enabled: false, needsDeletion: true);
      _consentWasPersisted = true;
      await _persistConsent();
      return false;
    }

    _consent = ConsentState.disabled;
    _consentWasPersisted = true;
    _pendingRound = null;
    await _clearPendingRoundStorage();
    await _persistConsent();
    return true;
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

  Future<void> startRound({
    required String gameId,
    required String contentVersion,
  }) async {
    if (!_consent.enabled || _consent.installationId == null) return;

    _pendingRound = PendingRound(
      sessionId: _randomToken(),
      gameId: gameId,
      contentVersion: contentVersion,
      startedAtUtc: DateTime.now().toUtc(),
    );
    await _persistPendingRound();
    await enqueue(
      _newEvent(
        sessionId: _pendingRound!.sessionId,
        kind: AnalyticsEventKind.roundStarted,
      ),
    );
  }

  Future<void> itemShown({
    required String itemId,
    required int itemIndex,
  }) async {
    final pending = _pendingRound;
    if (pending == null || !_consent.enabled) return;

    _pendingRound = pending.copyWith(
      lastShownItemId: itemId,
      lastShownItemIndex: itemIndex,
    );
    await _persistPendingRound();
    await enqueue(
      _newEvent(
        sessionId: pending.sessionId,
        kind: AnalyticsEventKind.itemShown,
        itemId: itemId,
        itemIndex: itemIndex,
      ),
    );
  }

  Future<void> itemAnswered({
    required String itemId,
    required int itemIndex,
    required AnalyticsOutcome outcome,
  }) async {
    final pending = _pendingRound;
    if (pending == null || !_consent.enabled) return;

    _pendingRound = pending.copyWith(
      lastShownItemId: itemId,
      lastShownItemIndex: itemIndex,
    );
    await _persistPendingRound();
    await enqueue(
      _newEvent(
        sessionId: pending.sessionId,
        kind: AnalyticsEventKind.itemAnswered,
        itemId: itemId,
        itemIndex: itemIndex,
        outcome: outcome,
      ),
    );
  }

  Future<void> endRound({
    required AnalyticsRoundEndReason reason,
    String? itemId,
    int? itemIndex,
  }) async {
    final pending = _pendingRound;
    if (pending == null) return;

    if (_consent.enabled) {
      await enqueue(
        _newEvent(
          sessionId: pending.sessionId,
          kind: AnalyticsEventKind.roundEnded,
          itemId: itemId ?? pending.lastShownItemId,
          itemIndex: itemIndex ?? pending.lastShownItemIndex,
          reason: reason,
        ),
      );
    }

    _pendingRound = null;
    await _clearPendingRoundStorage();
  }

  /// Closes a round left pending from a previous launch as an inferred
  /// interruption, using only the last shown item and its bounded timestamp.
  Future<void> reconcileInterruptedRound({required String gameId}) async {
    final pending = _pendingRound;
    if (pending == null) return;

    if (!_consent.enabled || pending.gameId != gameId) {
      _pendingRound = null;
      await _clearPendingRoundStorage();
      return;
    }

    await enqueue(
      _newEvent(
        sessionId: pending.sessionId,
        kind: AnalyticsEventKind.roundEnded,
        itemId: pending.lastShownItemId,
        itemIndex: pending.lastShownItemIndex,
        reason: AnalyticsRoundEndReason.inferredInterruption,
      ),
    );

    _pendingRound = null;
    await _clearPendingRoundStorage();
  }

  AnalyticsEvent _newEvent({
    required String sessionId,
    required AnalyticsEventKind kind,
    String? itemId,
    int? itemIndex,
    AnalyticsOutcome? outcome,
    AnalyticsRoundEndReason? reason,
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
    );
  }

  void _scheduleFlush() {
    _flushQueue = _flushQueue.then((_) => _flush());
  }

  Future<void> _flush() async {
    final events = _queue.drain();
    if (events.isEmpty) return;
    try {
      await _transport.sendEvents(events, deletionSecret: _consent.deletionSecret);
    } catch (_) {
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
