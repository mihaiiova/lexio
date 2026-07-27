import 'grammar_content.dart';

final class GrammarGameState {
  final List<GrammarExercise> exercises;
  final int currentIndex;
  final int correctCount;
  final int totalAnswered;
  final bool? lastAnswerCorrect;
  final bool isFinished;
  final List<bool?> results;

  GrammarGameState({
    required this.exercises,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.totalAnswered = 0,
    this.lastAnswerCorrect,
    this.isFinished = false,
    List<bool?>? results,
  }) : results = results ?? List.filled(exercises.length, null);

  GrammarExercise get currentExercise => exercises[currentIndex];

  double get progress =>
      exercises.isEmpty ? 0 : totalAnswered / exercises.length;

  int get remaining => exercises.length - totalAnswered;

  GrammarGameState answer(bool playerSaysCorrect) {
    final actualCorrect = currentExercise.isCorrect;
    final isRight = playerSaysCorrect == actualCorrect;

    final newResults = List<bool?>.from(results);
    newResults[currentIndex] = isRight;

    return GrammarGameState(
      exercises: exercises,
      currentIndex: currentIndex,
      correctCount: isRight ? correctCount + 1 : correctCount,
      totalAnswered: totalAnswered + 1,
      lastAnswerCorrect: isRight,
      isFinished: false,
      results: newResults,
    );
  }

  GrammarGameState next() {
    final nextIndex = currentIndex + 1;
    if (nextIndex >= exercises.length) {
      return GrammarGameState(
        exercises: exercises,
        currentIndex: currentIndex,
        correctCount: correctCount,
        totalAnswered: totalAnswered,
        lastAnswerCorrect: null,
        isFinished: true,
        results: results,
      );
    }

    return GrammarGameState(
      exercises: exercises,
      currentIndex: nextIndex,
      correctCount: correctCount,
      totalAnswered: totalAnswered,
      lastAnswerCorrect: null,
      isFinished: false,
      results: results,
    );
  }
}
