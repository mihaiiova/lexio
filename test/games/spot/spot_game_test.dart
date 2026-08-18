import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/games/spot/spot_game.dart';
import 'package:lexio/games/spot/spot_content.dart';

void main() {
  group('SpotGameState', () {
    final texts = [
      SpotText(
        id: 'test_1',
        type: 'story',
        title: 'Test text',
        difficulty: 1,
        content: 'Salut ce faci in oras',
        mistakes: [
          const SpotMistake(
            wordIndex: 3,
            token: 'in',
            replacement: 'în',
            explanation: 'Diacritice lipsă.',
            category: 'ortografie',
            topic: 'diacritice',
          ),
          const SpotMistake(
            wordIndex: 4,
            token: 'oras',
            replacement: 'oraș',
            explanation: 'Diacritice lipsă.',
            category: 'ortografie',
            topic: 'diacritice',
          ),
        ],
      ),
      SpotText(
        id: 'test_2',
        type: 'email',
        title: 'Test email',
        difficulty: 1,
        content: 'Mam dus la magazin',
        mistakes: [
          const SpotMistake(
            wordIndex: 0,
            token: 'Mam',
            replacement: 'M-am',
            explanation: 'Cratimă lipsă.',
            category: 'ortografie',
            topic: 'cratimă',
          ),
        ],
      ),
    ];

    SpotGameState createState({DateTime? startTime}) =>
        SpotGameState(texts: texts, startTime: startTime);

    test('initial state has correct defaults', () {
      final state = createState();

      expect(state.currentTextIndex, 0);
      expect(state.isFinished, false);
      expect(state.mistakesFound, 0);
      expect(state.totalMistakesInCurrentText, 2);
      expect(state.allMistakesFoundInCurrentText, false);
      expect(state.textsCompleted, 0);
      expect(state.totalCorrectTaps, 0);
      expect(state.totalIncorrectTaps, 0);
      expect(state.accuracy, 1.0);
      expect(state.mode, SpotGameMode.normal);
    });

    test('empty state ignores actions without accessing a text', () {
      final state = SpotGameState(texts: const []);

      expect(state.mistakesFound, 0);
      expect(state.totalMistakesInCurrentText, 0);
      expect(state.tapWord(0).state, same(state));
      expect(state.nextText(), same(state));
      expect(state.checkTimerExpiry(), same(state));
      expect(state.checkAnswers(), same(state));
    });

    test('tapWord finds a mistake', () {
      final state = createState();
      final outcome = state.tapWord(3);

      expect(outcome.result, SpotTapResult.found);
      expect(outcome.mistake, isNotNull);
      expect(outcome.mistake!.token, 'in');
      expect(outcome.state.mistakesFound, 1);
      expect(outcome.state.totalCorrectTaps, 1);
      expect(outcome.state.totalIncorrectTaps, 0);
      expect(outcome.state.allMistakesFoundInCurrentText, false);
    });

    test('tapWord on correct word records incorrect tap', () {
      final state = createState();
      final outcome = state.tapWord(0);

      expect(outcome.result, SpotTapResult.incorrect);
      expect(outcome.mistake, isNull);
      expect(outcome.state.mistakesFound, 0);
      expect(outcome.state.totalIncorrectTaps, 1);
      expect(outcome.state.shakingWordIndex, 0);
    });

    test('tapWord on already found mistake returns alreadyFound', () {
      final state = createState();
      final afterFirst = state.tapWord(3);
      final outcome = afterFirst.state.tapWord(3);

      expect(outcome.result, SpotTapResult.alreadyFound);
      expect(outcome.state.mistakesFound, 1);
    });

    test('clearShaker resets shakingWordIndex', () {
      final state = createState();
      final afterTap = state.tapWord(0);
      final cleared = afterTap.state.clearShaker();

      expect(cleared.shakingWordIndex, isNull);
      expect(afterTap.state.shakingWordIndex, 0);
    });

    test('isFoundMistakeWord returns true after finding', () {
      final state = createState();
      final afterFind = state.tapWord(3);

      expect(state.isFoundMistakeWord(3), false);
      expect(afterFind.state.isFoundMistakeWord(3), true);
      expect(afterFind.state.isFoundMistakeWord(0), false);
    });

    test('isUnfoundMistakeWord returns true for unfound mistakes', () {
      final state = createState();

      expect(state.isUnfoundMistakeWord(3), true);
      expect(state.isUnfoundMistakeWord(4), true);
      expect(state.isUnfoundMistakeWord(0), false);

      final afterFind = state.tapWord(3);
      expect(afterFind.state.isUnfoundMistakeWord(3), false);
      expect(afterFind.state.isUnfoundMistakeWord(4), true);
    });

    test('displayedWord always returns the original word', () {
      final state = createState();

      expect(state.displayedWord(3), 'in');
      final afterFind = state.tapWord(3);
      expect(afterFind.state.displayedWord(3), 'in');
    });

    test('allMistakesFoundInCurrentText is true after all found', () {
      final state = createState();
      final state1 = state.tapWord(3).state;
      final state2 = state1.tapWord(4).state;

      expect(state2.mistakesFound, 2);
      expect(state2.allMistakesFoundInCurrentText, true);
    });

    test('nextText advances to next text and resets startTime', () {
      final state = createState();
      final allFound = state.tapWord(3).state.tapWord(4).state;
      final next = allFound.nextText();

      expect(next.currentTextIndex, 1);
      expect(next.mistakesFound, 0);
      expect(next.totalMistakesInCurrentText, 1);
    });

    test('nextText on last text finishes game', () {
      final state = createState();
      final text1Done = state.tapWord(3).state.tapWord(4).state;
      final text2 = text1Done.nextText();
      final text2Done = text2.tapWord(0).state;
      final finished = text2Done.nextText();

      expect(finished.isFinished, true);
      expect(finished.textsCompleted, 2);
    });

    group('deadline-based timer', () {
      test('remainingSeconds computed from startTime', () {
        final now = DateTime(2025, 1, 1, 12, 0, 0);
        final state = SpotGameState(texts: texts, startTime: now);

        final atStart = state.remainingSecondsAt(now);
        expect(atStart, 60);

        final after30 = state.remainingSecondsAt(
          now.add(const Duration(seconds: 30)),
        );
        expect(after30, 30);

        final after61 = state.remainingSecondsAt(
          now.add(const Duration(seconds: 61)),
        );
        expect(after61, 0);
      });

      test('isTimerExpired true when deadline passed', () {
        final now = DateTime(2025, 1, 1, 12, 0, 0);
        final state = SpotGameState(texts: texts, startTime: now);

        final expired =
            state.elapsedAt(now.add(const Duration(seconds: 61))).inSeconds >=
            60;
        expect(expired, true);
      });

      test('remainingSeconds floors at zero', () {
        final now = DateTime(2025, 1, 1, 12, 0, 0);
        final state = SpotGameState(texts: texts, startTime: now);

        final after120 = state.remainingSecondsAt(
          now.add(const Duration(seconds: 120)),
        );
        expect(after120, 0);
      });
    });

    test('checkTimerExpiry advances on non-last text when expired', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final state = SpotGameState(
        texts: texts,
        startTime: now.subtract(const Duration(seconds: 61)),
      );

      expect(state.isTimerExpired, isTrue);
      final advanced = state.checkTimerExpiry();
      expect(advanced.currentTextIndex, 1);
    });

    test('checkTimerExpiry finishes game on last text when expired', () {
      final now = DateTime(2025, 1, 1, 12, 0, 0);
      final state = SpotGameState(
        texts: texts,
        currentTextIndex: 1,
        startTime: now.subtract(const Duration(seconds: 61)),
      );

      expect(state.isTimerExpired, isTrue);
      final finished = state.checkTimerExpiry();
      expect(finished.isFinished, true);
    });

    test('checkTimerExpiry does nothing when not expired', () {
      final state = SpotGameState(texts: texts, startTime: DateTime.now());

      final result = state.checkTimerExpiry();
      expect(result.currentTextIndex, state.currentTextIndex);
    });

    test('score calculation', () {
      final state = createState()
          .tapWord(3)
          .state
          .tapWord(0)
          .state
          .tapWord(4)
          .state;

      expect(state.totalCorrectTaps, 2);
      expect(state.totalIncorrectTaps, 1);
      expect(state.score, 2 * 100 - 1 * 25);
    });

    test('accuracy calculation', () {
      var state = createState();
      expect(state.accuracy, 1.0);

      state = state.tapWord(3).state;
      expect(state.accuracy, 1.0);

      state = state.tapWord(0).state;
      expect(state.accuracy, 1 / 2);

      state = state.tapWord(4).state;
      expect(state.accuracy, 2 / 3);
    });

    test('multi-word mistakes can be found from any word in their range', () {
      final state = SpotGameState(
        texts: [
          SpotText(
            id: 'multi_word',
            type: 'news',
            title: 'Test expresie',
            difficulty: 2,
            content: 'Au fost anunțate alegeri electorale pentru luna mai.',
            mistakes: const [
              SpotMistake(
                wordIndex: 3,
                wordCount: 2,
                token: 'alegeri electorale',
                replacement: 'alegeri',
                explanation: 'Cuvântul „electorale” este redundant.',
                category: 'exprimare',
                topic: 'pleonasm',
              ),
            ],
          ),
        ],
      );

      final outcome = state.tapWord(4);

      expect(outcome.result, SpotTapResult.found);
      expect(outcome.state.isFoundMistakeWord(3), isTrue);
      expect(outcome.state.isFoundMistakeWord(4), isTrue);
      expect(outcome.state.mistakesFound, 1);
    });
  });
}
