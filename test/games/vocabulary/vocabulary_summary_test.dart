import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_game.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/widgets/vocabulary_summary.dart';

void main() {
  testWidgets('forwards discovery counts to the shared summary', (
    tester,
  ) async {
    final state = VocabularyGameState(
      exercises: [
        VocabularyExercise(
          id: 'one',
          word: 'curios',
          partOfSpeech: 'adjectiv',
          definition: 'dornic să afle lucruri noi',
          example: 'Curios, Vlad a deschis atlasul.',
          options: const ['a', 'b', 'c'],
          correctOptionIndex: 0,
          explanation: 'e',
          category: 'c',
          synonyms: const ['s'],
          difficulty: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: VocabularySummary(
            state: state,
            discoveredCount: 30,
            discoveredTotal: 100,
            onPlayAgain: () {},
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.text('30 din 100'), findsOneWidget);
  });
}
