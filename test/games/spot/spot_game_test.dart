import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/games/spot/spot_game.dart';
import 'package:lexio/games/spot/spot_content.dart';

void main() {
  group('SpotGameState', () {
    final texts = [
      SpotText(
        id: 'test_1',
        type: 'whatsapp',
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

    SpotGameState createState() => SpotGameState(texts: texts);

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

    test('nextText advances to next text', () {
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

    test('tick decrements remainingSeconds', () {
      final state = SpotGameState(texts: texts, mode: SpotGameMode.timed);
      expect(state.remainingSeconds, 60);

      final afterTick = state.tick();
      expect(afterTick.remainingSeconds, 59);
    });

    test('tick auto-advances when timer expires on non-last text', () {
      final state = SpotGameState(
        texts: texts,
        mode: SpotGameMode.timed,
        remainingSeconds: 1,
      );
      final afterTick = state.tick();
      expect(afterTick.currentTextIndex, 1);
      expect(afterTick.remainingSeconds, 60);
      expect(afterTick.isFinished, false);
    });

    test('tick finishes game when timer expires on last text', () {
      final state = SpotGameState(
        texts: texts,
        mode: SpotGameMode.timed,
        currentTextIndex: 1,
        remainingSeconds: 1,
      );
      final afterTick = state.tick();
      expect(afterTick.isFinished, true);
    });

    test('nextText resets timer', () {
      final state = createState()
          .tapWord(3)
          .state
          .tapWord(4)
          .state;
      expect(state.remainingSeconds, 60);

      final afterTick = state.tick();
      expect(afterTick.remainingSeconds, 59);

      final next = afterTick.nextText();
      expect(next.currentTextIndex, 1);
      expect(next.remainingSeconds, 60);
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
  });
}
