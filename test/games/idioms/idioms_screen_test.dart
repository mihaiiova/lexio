import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/widgets/idiom_sentence.dart';

void main() {
  testWidgets('highlights the idiom inside its example', (tester) async {
    final exercise = _exercise(
      id: 'one',
      expression: 'a pune umărul',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [exercise]);

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(IdiomSentence),
        matching: find.byType(RichText),
      ),
    );
    final sentence = richText.text as TextSpan;
    final highlightedIdiom = sentence.children![1] as TextSpan;

    expect(sentence.toPlainText(), exercise.example);
    expect(highlightedIdiom.text, 'au pus umărul');
    expect(highlightedIdiom.style!.fontWeight, FontWeight.w800);
    expect(highlightedIdiom.style!.backgroundColor, LexioColors.blueMuted);
  });

  testWidgets('advances immediately after a correct answer', (tester) async {
    final first = _exercise(
      id: 'one',
      expression: 'a pune umărul',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );
    final second = _exercise(
      id: 'two',
      expression: 'a bate câmpii',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [first, second]);

    await tester.tap(find.text('a ajuta'));
    await tester.pumpAndSettle();

    expect(find.text(second.example, findRichText: true), findsOneWidget);
    expect(find.text('Răspuns greșit'), findsNothing);
  });

  testWidgets('shows the meaning after an incorrect answer', (tester) async {
    final exercise = _exercise(
      id: 'one',
      expression: 'a pune umărul',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [exercise]);

    await tester.tap(find.text('a pleca'));
    await tester.pumpAndSettle();

    expect(find.text('Răspuns greșit'), findsOneWidget);
    expect(find.text(exercise.meaning), findsOneWidget);
    expect(find.text('Continuă'), findsOneWidget);
    expect(find.text('a pleca'), findsNothing);
    expect(find.text('a ajuta'), findsNothing);
    expect(find.text('a aștepta'), findsNothing);
  });

  testWidgets('finishes a mixed round', (tester) async {
    final first = _exercise(
      id: 'one',
      expression: 'a pune umărul',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );
    final second = _exercise(
      id: 'two',
      expression: 'a bate câmpii',
      highlightedText: 'au pus umărul',
      correctOptionIndex: 1,
    );

    await _pumpGame(tester, [first, second]);

    await tester.tap(find.text('a pleca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuă'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('a ajuta'));
    await tester.pumpAndSettle();

    expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    expect(find.text('1 din 2'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsOneWidget);
    expect(find.text('a pleca'), findsOneWidget);
    expect(find.text('Corect: a ajuta', findRichText: true), findsOneWidget);
    expect(
      find.text('„a pune umărul” înseamnă a contribui prin ajutor.'),
      findsOneWidget,
    );
    expect(find.text('Joacă din nou'), findsOneWidget);
    expect(find.text('Înapoi la jocuri'), findsOneWidget);
  });
}

Future<void> _pumpGame(WidgetTester tester, List<IdiomExercise> exercises) {
  return tester.pumpWidget(
    MaterialApp(
      theme: LexioTheme.light,
      home: IdiomsScreen(exercises: exercises),
    ),
  );
}

IdiomExercise _exercise({
  required String id,
  required String expression,
  required String highlightedText,
  required int correctOptionIndex,
}) {
  return IdiomExercise(
    id: id,
    expression: expression,
    meaning: 'a contribui prin ajutor',
    example: 'Toți au pus umărul la proiect.',
    highlightedText: highlightedText,
    options: const ['a pleca', 'a ajuta', 'a aștepta'],
    correctOptionIndex: correctOptionIndex,
    category: 'cooperare',
    difficulty: 1,
  );
}
