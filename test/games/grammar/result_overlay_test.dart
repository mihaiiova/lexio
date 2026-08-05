import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/widgets/result_overlay.dart';

void main() {
  testWidgets('clearly explains that a rejected correct sentence is correct', (
    tester,
  ) async {
    const exercise = GrammarExercise(
      id: 'correct',
      sentence: 'Copiii s-au întors acasă.',
      category: 'ortografie',
      topic: 'cratimă',
      isCorrect: true,
      explanation: 'Propoziția este corectă. „S-au” se scrie cu cratimă.',
      correctSentence: null,
      difficulty: 1,
      tags: [],
      pairId: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: const Scaffold(body: ResultOverlay(exercise: exercise)),
      ),
    );

    expect(find.text('Textul este corect.'), findsOneWidget);
    expect(find.text(exercise.sentence), findsOneWidget);
    expect(find.text(exercise.explanation), findsOneWidget);
  });
}
