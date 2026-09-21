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
  testWidgets('shows the word alongside the wrong answer and explanation', (
    tester,
  ) async {
    final exercise = VocabularyExercise(
      id: 'one',
      word: 'curios',
      partOfSpeech: 'adjectiv',
      definition: 'dornic să afle lucruri noi',
      example: 'Curios, Vlad a deschis atlasul.',
      options: const [
        'nepăsător',
        'dornic să afle lucruri noi',
        'supărat fără motiv',
      ],
      correctOptionIndex: 1,
      explanation: 'O persoană curioasă caută informații.',
      category: 'trăsături',
      synonyms: const ['interesat'],
      difficulty: 1,
    );
    final state = VocabularyGameState(
      exercises: [exercise],
    ).answer(0).next();

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: VocabularySummary(
            state: state,
            onPlayAgain: () {},
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.text('0 din 1'), findsOneWidget);
    expect(find.text(exercise.word), findsOneWidget);
    expect(find.text('nepăsător'), findsOneWidget);
    expect(
      find.text('Corect: dornic să afle lucruri noi', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(exercise.explanation), findsOneWidget);
  });

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
