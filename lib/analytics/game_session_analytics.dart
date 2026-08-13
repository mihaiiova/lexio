import 'dart:async';

import 'analytics_service.dart';

/// Tracks a single game session and emits exactly one analytics event:
/// [AnalyticsService.logGameCompleted] on completion, or
/// [AnalyticsService.logGameAbandoned] when the session ends unfinished.
class GameSessionAnalytics {
  GameSessionAnalytics(this.gameId);

  final String gameId;
  final Stopwatch _stopwatch = Stopwatch();
  bool _active = false;
  bool _ended = false;

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
    unawaited(
      AnalyticsService.logGameCompleted(
        gameId,
        score: score,
        durationSeconds: _stopwatch.elapsed.inSeconds,
      ),
    );
  }

  void dispose() {
    if (!_active || _ended) return;
    _ended = true;
    _active = false;
    _stopwatch.stop();
    unawaited(AnalyticsService.logGameAbandoned(gameId));
  }
}
