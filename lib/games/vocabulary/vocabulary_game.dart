import 'vocabulary_content.dart';

final class VocabularyGameState {
  final List<VocabularyExercise> exercises;
  final int currentIndex;
  final int correctCount;
  final int totalAnswered;
  final List<int?> selectedOptionIndices;
  final List<bool?> results;
  final bool isFinished;

  VocabularyGameState({
    required this.exercises,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.totalAnswered = 0,
    List<int?>? selectedOptionIndices,
    List<bool?>? results,
    this.isFinished = false,
  }) : selectedOptionIndices =
           selectedOptionIndices ?? List<int?>.filled(exercises.length, null),
       results = results ?? List<bool?>.filled(exercises.length, null);

  VocabularyExercise get currentExercise => exercises[currentIndex];

  int? get selectedOptionIndex => selectedOptionIndices[currentIndex];

  bool get hasAnswered => selectedOptionIndex != null;

  bool? get lastAnswerCorrect => hasAnswered
      ? selectedOptionIndex == currentExercise.correctOptionIndex
      : null;

  double get progress =>
      exercises.isEmpty ? 0 : totalAnswered / exercises.length;

  VocabularyGameState answer(int optionIndex) {
    if (hasAnswered ||
        optionIndex < 0 ||
        optionIndex >= currentExercise.options.length) {
      return this;
    }

    final isCorrect = optionIndex == currentExercise.correctOptionIndex;
    final updatedResults = List<bool?>.from(results);
    final updatedSelections = List<int?>.from(selectedOptionIndices);
    updatedResults[currentIndex] = isCorrect;
    updatedSelections[currentIndex] = optionIndex;

    return VocabularyGameState(
      exercises: exercises,
      currentIndex: currentIndex,
      correctCount: isCorrect ? correctCount + 1 : correctCount,
      totalAnswered: totalAnswered + 1,
      selectedOptionIndices: updatedSelections,
      results: updatedResults,
    );
  }

  VocabularyGameState next() {
    if (!hasAnswered) return this;

    final nextIndex = currentIndex + 1;
    if (nextIndex >= exercises.length) {
      return VocabularyGameState(
        exercises: exercises,
        currentIndex: currentIndex,
        correctCount: correctCount,
        totalAnswered: totalAnswered,
        selectedOptionIndices: selectedOptionIndices,
        results: results,
        isFinished: true,
      );
    }

    return VocabularyGameState(
      exercises: exercises,
      currentIndex: nextIndex,
      correctCount: correctCount,
      totalAnswered: totalAnswered,
      selectedOptionIndices: selectedOptionIndices,
      results: results,
    );
  }
}
