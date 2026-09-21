import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/games/grammar/grammar_game.dart';
import 'package:lexio/games/grammar/grammar_content.dart';

void main() {
  group('GrammarGameState', () {
    final exercises = [
      GrammarExercise(
        id: '1',
        sentence: 'Test corect.',
        category: 'acord',
        topic: 'acord',
        isCorrect: true,
        explanation: 'E corect.',
        correctSentence: null,
        difficulty: 1,
        tags: [],
        pairId: null,
      ),
      GrammarExercise(
        id: '2',
        sentence: 'Test gresit.',
        category: 'cratime',
        topic: 'cratime',
        isCorrect: false,
        explanation: 'E gre\u0219it.',
        correctSentence: 'Varianta bun\u0103.',
        difficulty: 2,
        tags: [],
        pairId: null,
      ),
    ];

    test('initial state has correct defaults', () {
      final state = GrammarGameState(exercises: exercises);
      expect(state.currentIndex, 0);
      expect(state.correctCount, 0);
      expect(state.totalAnswered, 0);
      expect(state.lastAnswerCorrect, isNull);
      expect(state.isFinished, false);
      expect(state.progress, 0);
      expect(state.remaining, 2);
    });

    test('currentExercise returns correct exercise', () {
      final state = GrammarGameState(exercises: exercises);
      expect(state.currentExercise.id, '1');
    });

    test('answer correctly identifies a correct answer', () {
      final state = GrammarGameState(exercises: exercises);
      final next = state.answer(true);
      expect(next.lastAnswerCorrect, true);
      expect(next.correctCount, 1);
      expect(next.totalAnswered, 1);
    });

    test('answer correctly identifies an incorrect answer', () {
      final state = GrammarGameState(exercises: exercises);
      final next = state.answer(false);
      expect(next.lastAnswerCorrect, false);
      expect(next.correctCount, 0);
      expect(next.totalAnswered, 1);
    });

    test('answer ignores a second answer to the same exercise', () {
      final state = GrammarGameState(exercises: exercises);
      final answered = state.answer(true);

      expect(answered.answer(false), same(answered));
    });

    test('results tracks per-question outcomes', () {
      var state = GrammarGameState(exercises: exercises);
      state = state.answer(true);
      expect(state.results[0], true);
      state = state.next();
      state = state.answer(true);
      expect(state.results[1], false);
    });

    test('next advances to next exercise', () {
      var state = GrammarGameState(exercises: exercises);
      state = state.answer(true);
      state = state.next();
      expect(state.currentIndex, 1);
      expect(state.lastAnswerCorrect, isNull);
      expect(state.currentExercise.id, '2');
    });

    test('isFinished is true after answering all questions', () {
      var state = GrammarGameState(exercises: exercises);
      state = state.answer(true);
      state = state.next();
      state = state.answer(false);
      state = state.next();
      expect(state.isFinished, true);
    });

    test('next ignores an incomplete or finished exercise', () {
      final initial = GrammarGameState(exercises: exercises);
      final answered = initial.answer(true);
      final next = answered.next();
      final finished = next.answer(false).next();

      expect(initial.next(), same(initial));
      expect(finished.next(), same(finished));
    });

    test('progress counts only correct answers', () {
      var state = GrammarGameState(exercises: exercises);
      state = state.answer(true);
      state = state.next();
      state = state.answer(true);
      state = state.next();

      expect(state.progress, 0.5);
    });

    test('progress is 1.0 after every answer is correct', () {
      var state = GrammarGameState(exercises: exercises);
      state = state.answer(true);
      state = state.next();
      state = state.answer(false);
      state = state.next();

      expect(state.progress, 1.0);
    });
  });
}
