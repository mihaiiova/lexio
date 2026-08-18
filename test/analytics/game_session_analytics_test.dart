import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/game_session_analytics.dart';

void main() {
  group('GameSessionAnalytics', () {
    testWidgets('abandons an unfinished backgrounded session exactly once', (
      tester,
    ) async {
      final sink = _RecordingSessionSink();
      final session = GameSessionAnalytics(
        'grammar',
        sink: sink,
        backgroundAbandonmentDelay: const Duration(milliseconds: 30),
      )..start();

      session.didChangeAppLifecycleState(AppLifecycleState.hidden);
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 31));

      expect(sink.abandonedGameIds, ['grammar']);
      session.complete(100);
      await tester.pump();
      expect(sink.completedGameIds, isEmpty);

      session.dispose();
    });

    testWidgets('resuming before the timeout keeps the session completable', (
      tester,
    ) async {
      final sink = _RecordingSessionSink();
      final session = GameSessionAnalytics(
        'vocabulary',
        sink: sink,
        backgroundAbandonmentDelay: const Duration(milliseconds: 30),
      )..start();

      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 10));
      session.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 30));
      session.complete(200);
      await tester.pump();

      expect(sink.abandonedGameIds, isEmpty);
      expect(sink.completedGameIds, ['vocabulary']);

      session.dispose();
    });

    testWidgets('completed sessions never emit abandonment events', (
      tester,
    ) async {
      final sink = _RecordingSessionSink();
      final session = GameSessionAnalytics(
        'idioms',
        sink: sink,
        backgroundAbandonmentDelay: const Duration(milliseconds: 30),
      )..start();

      session.complete(300);
      session.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 31));
      session.dispose();

      expect(sink.completedGameIds, ['idioms']);
      expect(sink.abandonedGameIds, isEmpty);
    });

    testWidgets('disposing an unfinished session abandons it exactly once', (
      tester,
    ) async {
      final sink = _RecordingSessionSink();
      final session = GameSessionAnalytics('spot', sink: sink)..start();

      session.dispose();
      session.dispose();
      await tester.pump();

      expect(sink.abandonedGameIds, ['spot']);
    });
  });
}

final class _RecordingSessionSink implements GameSessionAnalyticsSink {
  final List<String> completedGameIds = [];
  final List<String> abandonedGameIds = [];

  @override
  Future<void> logAbandoned(String gameId) async {
    abandonedGameIds.add(gameId);
  }

  @override
  Future<void> logCompleted(
    String gameId, {
    required int score,
    required int durationSeconds,
  }) async {
    completedGameIds.add(gameId);
  }
}
