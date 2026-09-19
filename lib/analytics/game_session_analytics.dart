import 'dart:async';

import 'analytics_service.dart';

/// Receives lifecycle events emitted by [GameSessionAnalytics].
///
/// The production implementation forwards to [AnalyticsService]; tests inject a
/// recording sink so lifecycle events are deterministic and observable.
abstract class GameSessionAnalyticsSink {
  const GameSessionAnalyticsSink();

  void recordCompletion(String gameId, int score, int durationSeconds);
  void recordAbandonment(String gameId);
}

/// Default sink that forwards events to the real [AnalyticsService].
final class AnalyticsServiceSink extends GameSessionAnalyticsSink {
  const AnalyticsServiceSink();

  @override
  void recordCompletion(String gameId, int score, int durationSeconds) {
    unawaited(
      AnalyticsService.logGameCompleted(
        gameId,
        score: score,
        durationSeconds: durationSeconds,
      ),
    );
  }

  @override
  void recordAbandonment(String gameId) {
    unawaited(AnalyticsService.logGameAbandoned(gameId));
  }
}

/// Tracks a single game session and emits exactly one analytics event:
/// [AnalyticsService.logGameCompleted] on completion, or
/// [AnalyticsService.logGameAbandoned] when the session ends unfinished.
class GameSessionAnalytics {
  GameSessionAnalytics(
    this.gameId, {
    GameSessionAnalyticsSink? sink,
    this.backgroundAbandonmentDelay = const Duration(minutes: 5),
  }) : _sink = sink ?? const AnalyticsServiceSink();

  final String gameId;
  final GameSessionAnalyticsSink _sink;

  /// How long a session may stay backgrounded before it is abandoned.
  final Duration backgroundAbandonmentDelay;

  final Stopwatch _stopwatch = Stopwatch();
  bool _active = false;
  bool _ended = false;
  bool _backgrounded = false;
  Timer? _backgroundTimer;

  void start() {
    _active = true;
    _ended = false;
    _stopwatch
      ..reset()
      ..start();
  }

  void complete(int score) {
    if (!_active || _ended) return;
    _ended = true;
    _active = false;
    _stopwatch.stop();
    _cancelBackgroundTimer();
    _sink.recordCompletion(gameId, score, _stopwatch.elapsed.inSeconds);
  }

  /// Marks the session as backgrounded; if it stays backgrounded past
  /// [backgroundAbandonmentDelay] it is abandoned.
  void markBackgrounded() {
    if (!_active || _ended) return;
    _backgrounded = true;
    _cancelBackgroundTimer();
    _backgroundTimer = Timer(
      backgroundAbandonmentDelay,
      _abandonIfStillBackgrounded,
    );
  }

  void markResumed() {
    _backgrounded = false;
    _cancelBackgroundTimer();
  }

  void dispose() {
    _abandon();
  }

  void _abandonIfStillBackgrounded() {
    if (!_backgrounded) return;
    _abandon();
  }

  void _abandon() {
    if (!_active || _ended) return;
    _ended = true;
    _active = false;
    _stopwatch.stop();
    _cancelBackgroundTimer();
    _sink.recordAbandonment(gameId);
  }

  void _cancelBackgroundTimer() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
  }
}
