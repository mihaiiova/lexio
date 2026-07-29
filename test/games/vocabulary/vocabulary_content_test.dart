import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads 100 valid vocabulary exercises', () async {
    final exercises = await VocabularyContent.load();

    expect(exercises, hasLength(100));
    expect(
      exercises.map((exercise) => exercise.id).toSet(),
      hasLength(exercises.length),
    );
    expect(
      exercises.map((exercise) => exercise.word).toSet(),
      hasLength(exercises.length),
    );

    for (final exercise in exercises) {
      expect(exercise.id, isNotEmpty);
      expect(exercise.word, isNotEmpty);
      expect(exercise.partOfSpeech, isNotEmpty);
      expect(exercise.definition, isNotEmpty);
      expect(exercise.example, isNotEmpty);
      expect(exercise.options, hasLength(3));
      expect(exercise.correctOptionIndex, inInclusiveRange(0, 2));
      expect(exercise.correctOption, isNotEmpty);
      expect(exercise.explanation, isNotEmpty);
      expect(exercise.category, isNotEmpty);
      expect(exercise.synonyms, hasLength(greaterThanOrEqualTo(2)));
      expect(exercise.difficulty, inInclusiveRange(1, 3));
    }
  });

  test('contains exercises at every difficulty level', () async {
    final exercises = await VocabularyContent.load();

    expect(
      exercises.map((exercise) => exercise.difficulty).toSet(),
      equals({1, 2, 3}),
    );
  });

  test('creates a round with distinct exercises', () async {
    await VocabularyContent.load();

    final round = VocabularyContent.randomRound(10);

    expect(round, hasLength(10));
    expect(
      round.map((exercise) => exercise.id).toSet(),
      hasLength(round.length),
    );
    expect(
      [
        for (final difficulty in [1, 2, 3])
          round.where((exercise) => exercise.difficulty == difficulty).length,
      ],
      [4, 3, 3],
    );
  });
}
