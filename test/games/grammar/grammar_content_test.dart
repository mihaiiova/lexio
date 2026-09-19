import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
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

  test('bundled grammar JSON satisfies the content validator contracts',
      () async {
    final jsonString = await rootBundle.loadString(
      'lib/content/grammar_exercises.json',
    );
    final jsonList = json.decode(jsonString) as List<dynamic>;

    final ids = <String>{};
    for (final entry in jsonList) {
      final map = entry as Map<String, dynamic>;
      final id = map['id'] as String;

      expect(id, isNotEmpty);
      expect(ids.add(id), isTrue, reason: 'duplicate id: $id');
      expect(map['sentence'], isNotEmpty, reason: id);
      expect(map['isCorrect'], isA<bool>(), reason: id);
      expect(map['explanation'], isNotEmpty, reason: id);
      expect(map['category'], isNotEmpty, reason: id);
      expect(map['topic'], isNotEmpty, reason: id);
      expect(map['difficulty'], inInclusiveRange(1, 3), reason: id);

      if (!(map['isCorrect'] as bool)) {
        expect(map['correctSentence'], isNotNull, reason: id);
        expect(map['correctSentence'], isNot(map['sentence']), reason: id);
      }
    }
  });
}
