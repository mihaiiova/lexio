import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/progress/user_progress.dart';

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
      expect(exercise.difficulty, inInclusiveRange(1, 5));
    }
  });

  test('contains exercises at every difficulty level', () async {
    final exercises = await VocabularyContent.load();

    expect(
      exercises.map((exercise) => exercise.difficulty).toSet(),
      equals({1, 2, 3, 4, 5}),
    );
  });

  test('exposes 100 distinct notion IDs for discovery progress', () async {
    final exercises = await VocabularyContent.load();

    final notions = VocabularyContent.distinctNotionIds();

    expect(notions, hasLength(100));
    expect(notions, equals(exercises.map((e) => e.notionId).toSet()));
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
        for (final difficulty in [1, 2, 3, 4, 5])
          round.where((exercise) => exercise.difficulty == difficulty).length,
      ],
      [2, 2, 2, 2, 2],
    );
  });

  test('adaptiveRound serves exercises easy-to-hard', () async {
    await VocabularyContent.load();

    final round = VocabularyContent.adaptiveRound(100, const GameProgress());

    expect(round, hasLength(100));
    final difficulties = round.map((e) => e.difficulty).toList();
    expect(difficulties, List<int>.from(difficulties)..sort());
  });
}
