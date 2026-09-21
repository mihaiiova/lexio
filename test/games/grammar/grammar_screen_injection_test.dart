import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/grammar/grammar_screen.dart';

void main() {
  testWidgets('renders injected exercises without loading content', (
    tester,
  ) async {
    final exercise = _exercise(
      id: 'one',
      sentence: 'Copiii au plecat la școală.',
      isCorrect: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [exercise]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Copiii au plecat la școală.'), findsOneWidget);
    expect(find.text('Corect'), findsOneWidget);
    expect(find.text('Greșit'), findsOneWidget);
  });

  testWidgets('a correct answer advances through injected exercises', (
    tester,
  ) async {
    final exercise = _exercise(
      id: 'one',
      sentence: 'Copiii au plecat la școală.',
      isCorrect: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [exercise]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    expect(find.text('1 din 1'), findsOneWidget);
    expect(find.text('Joacă din nou'), findsOneWidget);
  });

  testWidgets('a wrong answer shows the explanation and a next button', (
    tester,
  ) async {
    final exercise = _exercise(
      id: 'one',
      sentence: 'Am văzut multe filme interesante.',
      isCorrect: false,
      correctSentence: 'Am văzut multe filme interesante.',
      explanation: 'Propoziția este corectă.',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [exercise]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Propoziția este corectă.'), findsOneWidget);
    expect(find.text('Următoarea'), findsOneWidget);
  });
}

GrammarExercise _exercise({
  required String id,
  required String sentence,
  required bool isCorrect,
  String? correctSentence,
  String? explanation,
}) {
  return GrammarExercise(
    id: id,
    sentence: sentence,
    category: 'test',
    topic: 'test',
    isCorrect: isCorrect,
    explanation: explanation ?? 'Explicație de test.',
    correctSentence: correctSentence,
    difficulty: 1,
    tags: const [],
    pairId: null,
  );
}
