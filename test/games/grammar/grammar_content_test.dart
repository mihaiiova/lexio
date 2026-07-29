import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/content/hyphenation_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'grammar content generates exercises from every hyphenation pair',
    () async {
      final pairs = await HyphenationContent.load();
      final exercises = await GrammarContent.load();
      final generated = exercises
          .where((exercise) => exercise.hyphenationPairId != null)
          .toList();
      final expectedConcepts = pairs.fold<int>(
        0,
        (total, pair) => total + (pair.unhyphenatedIsValid ? 2 : 1),
      );

      expect(generated, hasLength(expectedConcepts * 2));
      expect(
        generated.where((exercise) => exercise.isCorrect),
        hasLength(expectedConcepts),
      );
      expect(
        generated.where((exercise) => !exercise.isCorrect),
        hasLength(expectedConcepts),
      );
      expect(
        generated.map((exercise) => exercise.id).toSet(),
        hasLength(generated.length),
      );

      for (final pair in pairs) {
        final pairExercises = generated
            .where((exercise) => exercise.hyphenationPairId == pair.id)
            .toList();
        expect(
          pairExercises,
          hasLength(pair.unhyphenatedIsValid ? 4 : 2),
          reason: pair.id,
        );
      }
      expect(
        exercises.map((exercise) => exercise.difficulty).toSet(),
        containsAll({1, 2, 3, 4, 5}),
      );
    },
  );
}
