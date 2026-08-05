import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/vocabulary_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/vocabulary/widgets/vocabulary_sentence.dart';

void main() {
  testWidgets('shows the sentence with the target word in extra bold', (
    tester,
  ) async {
    final exercise = _exercise(
      id: 'one',
      word: 'anevoios',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [exercise]);

    expect(find.text('Ce înseamnă?'), findsNothing);
    expect(find.text('anevoios'), findsNothing);
    expect(find.byType(VocabularySentence), findsOneWidget);
    expect(find.text('foarte simplu'), findsOneWidget);
    expect(find.text('dificil și obositor'), findsOneWidget);
    expect(find.text('plin de culoare'), findsOneWidget);

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(VocabularySentence),
        matching: find.byType(RichText),
      ),
    );
    final sentence = richText.text as TextSpan;
    final highlightedWord = sentence.children![1] as TextSpan;

    expect(sentence.toPlainText(), exercise.example);
    expect(highlightedWord.text, 'anevoios');
    expect(highlightedWord.style!.fontWeight, FontWeight.w800);
    expect(highlightedWord.style!.backgroundColor, LexioColors.blueMuted);
  });

  testWidgets('advances immediately after a correct answer', (tester) async {
    final first = _exercise(id: 'one', word: 'anevoios', correctOptionIndex: 1);
    final second = _exercise(id: 'two', word: 'efemer', correctOptionIndex: 1);

    await _pumpGame(tester, [first, second]);

    await tester.tap(find.text('dificil și obositor'));
    await tester.pumpAndSettle();

    expect(find.text(second.example, findRichText: true), findsOneWidget);
    expect(find.text('Răspuns greșit'), findsNothing);
    expect(find.text('Continuă'), findsNothing);
  });

  testWidgets('replaces the actions with correction after a wrong answer', (
    tester,
  ) async {
    final exercise = _exercise(
      id: 'one',
      word: 'anevoios',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [exercise]);

    await tester.tap(find.text('foarte simplu'));
    await tester.pumpAndSettle();

    expect(find.text('Răspuns greșit'), findsOneWidget);
    expect(find.text(exercise.definition), findsOneWidget);
    expect(find.text('Sinonime: dificil, obositor'), findsOneWidget);
    expect(find.text('Continuă'), findsOneWidget);
    expect(find.text('foarte simplu'), findsNothing);
    expect(find.text('dificil și obositor'), findsNothing);
    expect(find.text('plin de culoare'), findsNothing);
  });

  testWidgets('continues after a wrong answer and finishes the round', (
    tester,
  ) async {
    final first = _exercise(id: 'one', word: 'anevoios', correctOptionIndex: 1);
    final second = _exercise(id: 'two', word: 'efemer', correctOptionIndex: 1);

    await _pumpGame(tester, [first, second]);

    await tester.tap(find.text('foarte simplu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuă'));
    await tester.pumpAndSettle();

    expect(find.text(second.example, findRichText: true), findsOneWidget);

    await tester.tap(find.text('dificil și obositor'));
    await tester.pumpAndSettle();

    expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    expect(find.text('1 din 2'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsOneWidget);
    expect(find.text('foarte simplu'), findsOneWidget);
    expect(
      find.text('Corect: dificil și obositor', findRichText: true),
      findsOneWidget,
    );
    expect(find.text(first.explanation), findsOneWidget);
    expect(find.byTooltip('Închide'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Joacă din nou'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Joacă din nou'), findsOneWidget);
    expect(find.text('Înapoi la jocuri'), findsNothing);
  });
}

Future<void> _pumpGame(
  WidgetTester tester,
  List<VocabularyExercise> exercises,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: LexioTheme.light,
      home: VocabularyScreen(exercises: exercises),
    ),
  );
}

VocabularyExercise _exercise({
  required String id,
  required String word,
  required int correctOptionIndex,
}) {
  return VocabularyExercise(
    id: id,
    word: word,
    partOfSpeech: 'adjectiv',
    definition: 'care se realizează cu dificultate',
    example: 'Drumul a fost $word.',
    options: const ['foarte simplu', 'dificil și obositor', 'plin de culoare'],
    correctOptionIndex: correctOptionIndex,
    explanation: 'Cuvântul descrie ceva care cere mult efort.',
    category: 'însușiri',
    synonyms: const ['dificil', 'obositor'],
    difficulty: 1,
  );
}
