import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/app/app.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/spot/spot_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/vocabulary/vocabulary_screen.dart';

void main() {
  testWidgets('Home screen renders all game titles', (tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
  });

  testWidgets('Home screen opens the in-app privacy policy', (tester) async {
    await tester.pumpWidget(const LexioApp());

    expect(find.text('Confidențialitate'), findsOneWidget);
    expect(find.text('Asistență'), findsNothing);

    await tester.ensureVisible(find.text('Confidențialitate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confidențialitate'));
    await tester.pumpAndSettle();

    expect(find.text('Politica de confidențialitate'), findsOneWidget);
    expect(find.text('Ce date colectăm'), findsOneWidget);
    expect(find.textContaining('Firebase Analytics'), findsWidgets);
  });

  testWidgets('App title text is present', (tester) async {
    await tester.pumpWidget(const LexioApp());
    expect(find.text('Slove'), findsOneWidget);
  });

  testWidgets('game entries expose button semantics with Romanian labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    expect(_hasLabel(tester, 'Joc 01: Corect sau greșit?'), isTrue);
    expect(_hasLabel(tester, 'Joc 02: Ce înseamnă?'), isTrue);
    expect(_hasLabel(tester, 'Joc 03: Vorba vine'), isTrue);
    expect(_hasLabel(tester, 'Joc 04: Găsește greșeala'), isTrue);
    expect(_hasButtonLabel(tester, 'Joc 01: Corect sau greșit?'), isTrue);

    handle.dispose();
  });

  testWidgets('grammar answer controls expose button semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: GrammarScreen(exercises: [_grammarIncorrect()]),
      ),
    );
    await tester.pumpAndSettle();

    expect(_hasButtonLabel(tester, 'Corect'), isTrue);
    expect(_hasButtonLabel(tester, 'Greșit'), isTrue);
    expect(_hasLabel(tester, 'Progres: 0 din 1'), isTrue);

    await tester.tap(find.text('Corect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(_hasButtonLabel(tester, 'Următoarea întrebare'), isTrue);

    handle.dispose();
  });

  testWidgets('vocabulary controls expose back and progress semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: VocabularyScreen(exercises: [_vocabulary()]),
      ),
    );
    await tester.pumpAndSettle();

    expect(_hasLabel(tester, 'Înapoi la jocuri'), isTrue);
    expect(_hasLabel(tester, 'Progres: 0 din 1'), isTrue);
    expect(_hasButtonLabel(tester, 'foarte simplu'), isTrue);
    expect(_hasButtonLabel(tester, 'dificil și obositor'), isTrue);

    handle.dispose();
  });

  testWidgets('idioms controls expose back and progress semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: IdiomsScreen(exercises: [_idiom()]),
      ),
    );
    await tester.pumpAndSettle();

    expect(_hasLabel(tester, 'Înapoi la jocuri'), isTrue);
    expect(_hasLabel(tester, 'Progres: 0 din 1'), isTrue);

    handle.dispose();
  });

  testWidgets('spot exposes back, timer, and progress semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: SpotScreen(texts: [_spotText()]),
      ),
    );
    await tester.pump();

    expect(_hasLabel(tester, 'Înapoi la jocuri'), isTrue);
    expect(_hasLabel(tester, 'Timp rămas: 01:00'), isTrue);
    expect(_hasLabel(tester, 'Progres: 0 din 1 texte'), isTrue);
    expect(_hasButtonLabel(tester, 'Mie'), isTrue);

    handle.dispose();
  });
}

List<SemanticsData> _allSemantics(WidgetTester tester) {
  // ignore: deprecated_member_use
  final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root == null) return const [];
  final result = <SemanticsData>[];
  void visit(SemanticsNode node) {
    result.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return result;
}

String _accessibleName(SemanticsData data) =>
    data.label.isNotEmpty ? data.label : data.tooltip;

bool _hasLabel(WidgetTester tester, String text) {
  return _allSemantics(tester).any(
    (data) => _accessibleName(data).contains(text),
  );
}

bool _hasButtonLabel(WidgetTester tester, String text) {
  return _allSemantics(tester).any(
    (data) =>
        data.flagsCollection.isButton && _accessibleName(data).contains(text),
  );
}

GrammarExercise _grammarIncorrect() {
  return GrammarExercise(
    id: 'g1',
    sentence: 'Am văzut multe filme interesante.',
    category: 'test',
    topic: 'test',
    isCorrect: false,
    explanation: 'Propoziția este corectă.',
    correctSentence: 'Am văzut multe filme interesante.',
    difficulty: 1,
    tags: const [],
    pairId: null,
  );
}

VocabularyExercise _vocabulary() {
  return VocabularyExercise(
    id: 'v1',
    word: 'anevoios',
    partOfSpeech: 'adjectiv',
    definition: 'care se realizează cu dificultate',
    example: 'Drumul a fost anevoios.',
    options: const ['foarte simplu', 'dificil și obositor', 'plin de culoare'],
    correctOptionIndex: 1,
    explanation: 'Cuvântul descrie ceva care cere mult efort.',
    category: 'însușiri',
    synonyms: const ['dificil', 'obositor'],
    difficulty: 1,
  );
}

IdiomExercise _idiom() {
  return IdiomExercise(
    id: 'i1',
    expression: 'a pune umărul',
    meaning: 'a contribui prin ajutor',
    example: 'Toți au pus umărul la proiect.',
    highlightedText: 'au pus umărul',
    options: const ['a pleca', 'a ajuta', 'a aștepta'],
    correctOptionIndex: 1,
    category: 'cooperare',
    difficulty: 1,
  );
}

SpotText _spotText() {
  return SpotText(
    id: 's1',
    type: 'story',
    title: 'Test',
    difficulty: 1,
    content: 'Mie îmi place să citesc.',
    mistakes: [
      SpotMistake(
        wordIndex: 0,
        wordCount: 1,
        token: 'Mie',
        replacement: 'Mi-e',
        explanation: '„Mi-e” este forma corectă.',
        category: 'ortografie',
        topic: 'cratima',
      ),
    ],
  );
}
