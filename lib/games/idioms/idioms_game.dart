import 'idioms_content.dart';

final class IdiomsGameState {
  final List<IdiomExercise> exercises;
  final int currentIndex;
  final int correctCount;
  final int totalAnswered;
  final int? selectedOptionIndex;
  final List<bool?> results;
  final bool isFinished;

  IdiomsGameState({
    required this.exercises,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.totalAnswered = 0,
    this.selectedOptionIndex,
    List<bool?>? results,
    this.isFinished = false,
  }) : results = results ?? List<bool?>.filled(exercises.length, null);

  IdiomExercise get currentExercise => exercises[currentIndex];

  bool get hasAnswered => selectedOptionIndex != null;

  bool? get lastAnswerCorrect => hasAnswered
      ? selectedOptionIndex == currentExercise.correctOptionIndex
      : null;

  double get progress =>
      exercises.isEmpty ? 0 : totalAnswered / exercises.length;

  IdiomsGameState answer(int optionIndex) {
    if (hasAnswered ||
        optionIndex < 0 ||
        optionIndex >= currentExercise.options.length) {
      return this;
    }

    final isCorrect = optionIndex == currentExercise.correctOptionIndex;
    final updatedResults = List<bool?>.from(results);
    updatedResults[currentIndex] = isCorrect;

    return IdiomsGameState(
      exercises: exercises,
      currentIndex: currentIndex,
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      totalAnswered: totalAnswered + 1,
      selectedOptionIndex: optionIndex,
      results: updatedResults,
    );
  }

  IdiomsGameState next() {
    if (!hasAnswered) return this;

    final nextIndex = currentIndex + 1;
    if (nextIndex >= exercises.length) {
      return IdiomsGameState(
        exercises: exercises,
        currentIndex: currentIndex,
        correctCount: correctCount,
        totalAnswered: totalAnswered,
        results: results,
        isFinished: true,
      );
    }

    return IdiomsGameState(
      exercises: exercises,
      currentIndex: nextIndex,
      correctCount: correctCount,
      totalAnswered: totalAnswered,
      results: results,
    );
  }
}
