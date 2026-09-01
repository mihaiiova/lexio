import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_game.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/widgets/grammar_summary.dart';

void main() {
  testWidgets('adapts a wrong grammar answer to the shared summary', (
    tester,
  ) async {
    final exercise = GrammarExercise(
      id: 'one',
      sentence: 'Mi-ar place să citesc.',
      category: 'verb',
      topic: 'condițional',
      isCorrect: false,
      explanation: 'Forma corectă este „mi-ar plăcea”.',
      correctSentence: 'Mi-ar plăcea să citesc.',
      difficulty: 1,
      tags: const [],
      pairId: null,
    );
    final state = GrammarGameState(exercises: [exercise]).answer(true).next();

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: GrammarSummary(state: state, onPlayAgain: () {}, onBack: () {}),
        ),
      ),
    );

    expect(find.text('0 din 1'), findsOneWidget);
    expect(find.text(exercise.sentence), findsOneWidget);
    expect(
      find.text('Corect: ${exercise.correctSentence}', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(exercise.explanation), findsOneWidget);
  });

  testWidgets('forwards discovery counts to the shared summary', (
    tester,
  ) async {
    final exercise = GrammarExercise(
      id: 'one',
      sentence: 'Mi-ar place să citesc.',
      category: 'verb',
      topic: 'condițional',
      isCorrect: false,
      explanation: 'Forma corectă este „mi-ar plăcea”.',
      correctSentence: 'Mi-ar plăcea să citesc.',
      difficulty: 1,
      tags: const [],
      pairId: null,
    );
    final state = GrammarGameState(exercises: [exercise]);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: GrammarSummary(
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
