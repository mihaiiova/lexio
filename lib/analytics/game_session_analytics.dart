import 'dart:async';

import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

abstract interface class GameSessionAnalyticsSink {
  Future<void> logCompleted(
    String gameId, {
    required int score,
    required int durationSeconds,
  });

  Future<void> logAbandoned(String gameId);
}

final class _AnalyticsServiceSessionSink implements GameSessionAnalyticsSink {
  const _AnalyticsServiceSessionSink();

  @override
  Future<void> logCompleted(
    String gameId, {
    required int score,
    required int durationSeconds,
  }) => AnalyticsService.logGameCompleted(
    gameId,
    score: score,
    durationSeconds: durationSeconds,
  );

  @override
  Future<void> logAbandoned(String gameId) =>
      AnalyticsService.logGameAbandoned(gameId);
}

/// Tracks a single game session and emits exactly one analytics event.
///
/// A session is abandoned after 30 seconds in a hidden or paused state. A
/// resumed session cancels the pending abandonment and remains completable.
class GameSessionAnalytics with WidgetsBindingObserver {
  GameSessionAnalytics(
    this.gameId, {
    GameSessionAnalyticsSink? sink,
    this.backgroundAbandonmentDelay = const Duration(seconds: 30),
  }) : _sink = sink ?? const _AnalyticsServiceSessionSink();

  final String gameId;
  final Duration backgroundAbandonmentDelay;
  final GameSessionAnalyticsSink _sink;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _backgroundTimer;
  bool _active = false;
  bool _ended = false;
  bool _isObservingLifecycle = false;

  void start() {
    _backgroundTimer?.cancel();
    _active = true;
    _ended = false;
    _stopwatch
      ..reset()
      ..start();
    if (!_isObservingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _isObservingLifecycle = true;
    }
  }

  void complete(int score) {
    if (!_active || _ended) return;
    _end();
    unawaited(
      _sink.logCompleted(
        gameId,
        score: score,
        durationSeconds: _stopwatch.elapsed.inSeconds,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active || _ended) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _backgroundTimer?.cancel();
        _backgroundTimer = null;
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _scheduleBackgroundAbandonment();
        return;
      case AppLifecycleState.detached:
        _abandon();
        return;
      case AppLifecycleState.inactive:
        return;
    }
  }

  void dispose() => _abandon();

  void _scheduleBackgroundAbandonment() {
    if (_backgroundTimer != null) return;
    _backgroundTimer = Timer(backgroundAbandonmentDelay, _abandon);
  }

  void _abandon() {
    if (!_active || _ended) return;
    _end();
    unawaited(_sink.logAbandoned(gameId));
  }

  void _end() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _ended = true;
    _active = false;
    _stopwatch.stop();
    if (_isObservingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _isObservingLifecycle = false;
    }
  }
}
