import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/progress/user_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads 60 valid idiom exercises', () async {
    final exercises = await IdiomsContent.load();

    expect(exercises, hasLength(60));
    expect(
      exercises.map((exercise) => exercise.id).toSet(),
      hasLength(exercises.length),
    );
    expect(
      exercises.map((exercise) => exercise.expression).toSet(),
      hasLength(exercises.length),
    );

    for (final exercise in exercises) {
      expect(exercise.expression, isNotEmpty);
      expect(exercise.meaning, isNotEmpty);
      expect(exercise.example, isNotEmpty);
      expect(exercise.highlightedText, isNotEmpty);
      expect(
        exercise.example.toLowerCase(),
        contains(exercise.highlightedText.toLowerCase()),
      );
      expect(exercise.options, hasLength(3));
      expect(exercise.correctOptionIndex, inInclusiveRange(0, 2));
      expect(exercise.category, isNotEmpty);
      expect(exercise.difficulty, inInclusiveRange(1, 5));
    }
  });

  test('contains exercises at every difficulty level', () async {
    final exercises = await IdiomsContent.load();

    for (final difficulty in [1, 2, 3, 4, 5]) {
      expect(
        exercises.where((exercise) => exercise.difficulty == difficulty),
        isNotEmpty,
      );
    }
  });

  test('exposes 60 distinct notion IDs for discovery progress', () async {
    final exercises = await IdiomsContent.load();

    final notions = IdiomsContent.distinctNotionIds();

    expect(notions, hasLength(60));
    expect(notions, equals(exercises.map((e) => e.notionId).toSet()));
  });

  test('creates a balanced round with distinct exercises', () async {
    await IdiomsContent.load();

    final round = IdiomsContent.randomRound(10);

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

  test('adaptiveRound serves expressions easy-to-hard', () async {
    await IdiomsContent.load();

    final round = IdiomsContent.adaptiveRound(60, const GameProgress());

    expect(round, hasLength(60));
    final difficulties = round.map((e) => e.difficulty).toList();
    expect(difficulties, List<int>.from(difficulties)..sort());
  });
}
