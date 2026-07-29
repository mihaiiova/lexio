import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_game.dart';

void main() {
  group('VocabularyGameState', () {
    final exercises = [
      _exercise(id: 'one', correctOptionIndex: 1),
      _exercise(id: 'two', correctOptionIndex: 2),
    ];

    test('starts at the first unanswered exercise', () {
      final state = VocabularyGameState(exercises: exercises);

      expect(state.currentIndex, 0);
      expect(state.correctCount, 0);
      expect(state.totalAnswered, 0);
      expect(state.selectedOptionIndex, isNull);
      expect(state.hasAnswered, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.progress, 0);
    });

    test('records a correct answer', () {
      final state = VocabularyGameState(exercises: exercises).answer(1);

      expect(state.selectedOptionIndex, 1);
      expect(state.lastAnswerCorrect, isTrue);
      expect(state.correctCount, 1);
      expect(state.totalAnswered, 1);
      expect(state.results, [true, null]);
    });

    test('records an incorrect answer', () {
      final state = VocabularyGameState(exercises: exercises).answer(0);

      expect(state.lastAnswerCorrect, isFalse);
      expect(state.correctCount, 0);
      expect(state.totalAnswered, 1);
      expect(state.results, [false, null]);
    });

    test('ignores a second answer to the same exercise', () {
      final answered = VocabularyGameState(exercises: exercises).answer(0);

      expect(answered.answer(1), same(answered));
    });

    test('does not advance before an answer is selected', () {
      final state = VocabularyGameState(exercises: exercises);

      expect(state.next(), same(state));
    });

    test('finishes after the last answered exercise', () {
      var state = VocabularyGameState(exercises: exercises);
      state = state.answer(1).next();
      state = state.answer(2).next();

      expect(state.isFinished, isTrue);
      expect(state.correctCount, 2);
      expect(state.totalAnswered, 2);
      expect(state.progress, 1);
    });
  });
}

VocabularyExercise _exercise({
  required String id,
  required int correctOptionIndex,
}) {
  return VocabularyExercise(
    id: id,
    word: 'cuvânt $id',
    partOfSpeech: 'substantiv',
    definition: 'definiție',
    example: 'Acesta este un exemplu.',
    options: const ['prima', 'a doua', 'a treia'],
    correctOptionIndex: correctOptionIndex,
    explanation: 'Aceasta este explicația.',
    category: 'test',
    synonyms: const ['sinonim', 'echivalent'],
    difficulty: 1,
  );
}
