import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_game.dart';

void main() {
  group('IdiomsGameState', () {
    final exercises = [
      _exercise(id: 'one', correctOptionIndex: 1),
      _exercise(id: 'two', correctOptionIndex: 2),
    ];

    test('starts at the first unanswered exercise', () {
      final state = IdiomsGameState(exercises: exercises);

      expect(state.currentIndex, 0);
      expect(state.correctCount, 0);
      expect(state.totalAnswered, 0);
      expect(state.selectedOptionIndices, [null, null]);
      expect(state.hasAnswered, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.progress, 0);
    });

    test('records a correct answer', () {
      final state = IdiomsGameState(exercises: exercises).answer(1);

      expect(state.lastAnswerCorrect, isTrue);
      expect(state.correctCount, 1);
      expect(state.totalAnswered, 1);
      expect(state.results, [true, null]);
      expect(state.selectedOptionIndices, [1, null]);
    });

    test('records an incorrect answer', () {
      final state = IdiomsGameState(exercises: exercises).answer(0);

      expect(state.lastAnswerCorrect, isFalse);
      expect(state.correctCount, 0);
      expect(state.totalAnswered, 1);
      expect(state.results, [false, null]);
      expect(state.selectedOptionIndices, [0, null]);
    });

    test('ignores a second answer to the same exercise', () {
      final answered = IdiomsGameState(exercises: exercises).answer(0);

      expect(answered.answer(1), same(answered));
    });

    test('does not advance before an answer is selected', () {
      final state = IdiomsGameState(exercises: exercises);

      expect(state.next(), same(state));
    });

    test('finishes after the last answered exercise', () {
      var state = IdiomsGameState(exercises: exercises);
      state = state.answer(1).next();
      state = state.answer(2).next();

      expect(state.isFinished, isTrue);
      expect(state.correctCount, 2);
      expect(state.totalAnswered, 2);
      expect(state.progress, 1);
      expect(state.selectedOptionIndices, [1, 2]);
    });
  });
}

IdiomExercise _exercise({required String id, required int correctOptionIndex}) {
  return IdiomExercise(
    id: id,
    expression: 'a pune umărul',
    meaning: 'a ajuta',
    example: 'Toți au pus umărul la proiect.',
    highlightedText: 'au pus umărul',
    options: const ['a pleca', 'a ajuta', 'a aștepta'],
    correctOptionIndex: correctOptionIndex,
    category: 'test',
    difficulty: 1,
  );
}
