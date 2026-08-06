import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/games/spot/spot_game.dart';
import 'package:lexio/games/spot/spot_content.dart';
import 'package:lexio/progress/user_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<SpotText> spotTexts;

  setUpAll(() async {
    spotTexts = await SpotContent.load();
  });

  group('SpotGameState integration', () {
    test('completes a normal five-text round with real content', () {
      final session = SpotContent.adaptiveSession(5, GameProgress());
      expect(session.length, 5);

      var state = SpotGameState(texts: session, mode: SpotGameMode.timed);

      for (int t = 0; t < 5; t++) {
        final mistakes = state.currentText.mistakes;
        for (final m in mistakes) {
          final outcome = state.tapWord(m.wordIndex);
          expect(outcome.result, SpotTapResult.found);
          state = outcome.state;
        }
        expect(state.allMistakesFoundInCurrentText, isTrue);

        if (t < 4) {
          state = state.nextText();
          expect(state.isFinished, isFalse);
        } else {
          state = state.nextText();
          expect(state.isFinished, isTrue);
        }
      }

      expect(state.textsCompleted, 5);
      expect(state.totalCorrectTaps, greaterThan(0));
      expect(state.score, greaterThan(0));
    });

    test('timer expiry advances text on non-last text', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final session = SpotContent.adaptiveSession(5, GameProgress());
      final state = SpotGameState(
        texts: session,
        mode: SpotGameMode.timed,
        startTime: now.subtract(const Duration(seconds: 61)),
      );

      expect(state.isTimerExpired, isTrue);
      expect(state.currentTextIndex, 0);

      final advanced = state.checkTimerExpiry();
      expect(advanced.currentTextIndex, 1);
      expect(advanced.isFinished, isFalse);
    });

    test('timer expiry finishes game on last text', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final session = SpotContent.adaptiveSession(5, GameProgress());
      final state = SpotGameState(
        texts: session,
        mode: SpotGameMode.timed,
        currentTextIndex: 4,
        startTime: now.subtract(const Duration(seconds: 61)),
      );

      expect(state.isTimerExpired, isTrue);

      final finished = state.checkTimerExpiry();
      expect(finished.isFinished, isTrue);
    });

    test('remainingSeconds derived from wall-clock startTime', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final session = SpotContent.adaptiveSession(1, GameProgress());
      final state = SpotGameState(
        texts: session,
        mode: SpotGameMode.timed,
        startTime: now,
      );

      expect(state.remainingSecondsAt(now), 60);
      expect(state.remainingSecondsAt(now.add(const Duration(seconds: 10))), 50);
      expect(state.remainingSecondsAt(now.add(const Duration(seconds: 120))), 0);
    });

    test('replay creates fresh state with new texts', () {
      final session = SpotContent.adaptiveSession(5, GameProgress());
      final state = SpotGameState(texts: session, mode: SpotGameMode.timed);

      expect(state.remainingSeconds, 60);
      expect(state.isFinished, isFalse);
      expect(state.currentTextIndex, 0);
      expect(state.totalCorrectTaps, 0);
    });

    test('answer checking is idempotent', () {
      final session = SpotContent.adaptiveSession(1, GameProgress());
      var state = SpotGameState(texts: session, mode: SpotGameMode.normal);

      state = state.checkAnswers();
      expect(state.isChecking, isTrue);

      final outcome = state.tapWord(state.currentText.mistakes.first.wordIndex);
      expect(outcome.result, SpotTapResult.found);
      expect(outcome.state.isChecking, isTrue);
    });

    test('incorrect taps tracked correctly in final score', () {
      final session = SpotContent.adaptiveSession(1, GameProgress());
      var state = SpotGameState(texts: session, mode: SpotGameMode.timed);

      final mistakes = state.currentText.mistakes;
      for (final m in mistakes) {
        state = state.tapWord(m.wordIndex).state;
      }

      state = state.tapWord(0).state;

      expect(state.totalIncorrectTaps, 1);
      expect(state.totalCorrectTaps, mistakes.length);
      final baseScore = state.totalCorrectTaps * 100;
      final penalty = state.totalIncorrectTaps * 25;
      expect(state.score, lessThanOrEqualTo(baseScore - penalty + 60 * 5));
    });

    test('multi-text progress tracking', () {
      final session = SpotContent.adaptiveSession(3, GameProgress());
      var state = SpotGameState(texts: session, mode: SpotGameMode.normal);

      expect(state.textsCompleted, 0);

      for (final m in state.currentText.mistakes) {
        state = state.tapWord(m.wordIndex).state;
      }
      state = state.nextText();
      expect(state.textsCompleted, 1);
      expect(state.currentTextIndex, 1);

      for (final m in state.currentText.mistakes) {
        state = state.tapWord(m.wordIndex).state;
      }
      state = state.nextText();
      expect(state.textsCompleted, 2);

      for (final m in state.currentText.mistakes) {
        state = state.tapWord(m.wordIndex).state;
      }
      state = state.nextText();
      expect(state.textsCompleted, 3);
      expect(state.isFinished, isTrue);
    });
  });

  group('SpotContent integration', () {
    test('spot corpus has 60 texts', () {
      expect(spotTexts, hasLength(60));
    });

    test('every text has between 3 and 4 mistakes', () {
      for (final text in spotTexts) {
        expect(text.mistakes.length, anyOf(equals(3), equals(4)));
      }
    });

    test('every mistake token appears in its text content', () {
      for (final text in spotTexts) {
        for (final m in text.mistakes) {
          expect(
            text.content.contains(m.token),
            isTrue,
            reason: 'token "${m.token}" not in "${text.content}"',
          );
        }
      }
    });

    test('adaptiveSession returns requested count', () {
      final session = SpotContent.adaptiveSession(5, GameProgress());
      expect(session.length, 5);
    });

    test('adaptiveSession returns texts with valid difficulty', () {
      final session = SpotContent.adaptiveSession(5, GameProgress());
      for (final text in session) {
        expect(text.difficulty, greaterThan(0));
      }
    });

    test('content loading is repeatable', () async {
      final load1 = await SpotContent.load();
      final load2 = await SpotContent.load();
      expect(load1.length, equals(load2.length));
    });
  });
}
