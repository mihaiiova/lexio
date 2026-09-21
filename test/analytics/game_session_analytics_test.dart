import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/game_session_analytics.dart';

void main() {
  test('records completion with score and a non-negative duration', () {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics('grammar', sink: sink);

    session.start();
    session.complete(7);

    expect(sink.completions, hasLength(1));
    final completion = sink.completions.single;
    expect(completion.gameId, 'grammar');
    expect(completion.score, 7);
    expect(completion.durationSeconds, greaterThanOrEqualTo(0));
    expect(sink.abandonments, isEmpty);
  });

  test('records abandonment when disposed unfinished', () {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics('grammar', sink: sink);

    session.start();
    session.dispose();

    expect(sink.abandonments, ['grammar']);
    expect(sink.completions, isEmpty);
  });

  test('does not record abandonment after completion', () {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics('grammar', sink: sink);

    session.start();
    session.complete(3);
    session.dispose();

    expect(sink.completions, hasLength(1));
    expect(sink.abandonments, isEmpty);
  });

  test('does not record anything before start', () {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics('grammar', sink: sink);

    session.dispose();

    expect(sink.completions, isEmpty);
    expect(sink.abandonments, isEmpty);
  });

  testWidgets('records abandonment after the background delay', (tester) async {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics(
      'spot',
      sink: sink,
      backgroundAbandonmentDelay: const Duration(minutes: 1),
    );

    session.start();
    session.markBackgrounded();
    await tester.pump(const Duration(minutes: 1));

    expect(sink.abandonments, ['spot']);
    expect(sink.completions, isEmpty);
  });

  testWidgets('resuming before the delay prevents abandonment', (
    tester,
  ) async {
    final sink = _RecordingSink();
    final session = GameSessionAnalytics(
      'spot',
      sink: sink,
      backgroundAbandonmentDelay: const Duration(minutes: 1),
    );

    session.start();
    session.markBackgrounded();
    await tester.pump(const Duration(seconds: 30));
    session.markResumed();
    await tester.pump(const Duration(minutes: 2));

    expect(sink.abandonments, isEmpty);

    session.dispose();
    expect(sink.abandonments, ['spot']);
  });
}

final class _RecordingSink extends GameSessionAnalyticsSink {
  final List<_Completion> completions = [];
  final List<String> abandonments = [];

  @override
  void recordCompletion(String gameId, int score, int durationSeconds) {
    completions.add(
      _Completion(
        gameId: gameId,
        score: score,
        durationSeconds: durationSeconds,
      ),
    );
  }

  @override
  void recordAbandonment(String gameId) {
    abandonments.add(gameId);
  }
}

final class _Completion {
  const _Completion({
    required this.gameId,
    required this.score,
    required this.durationSeconds,
  });

  final String gameId;
  final int score;
  final int durationSeconds;
}
