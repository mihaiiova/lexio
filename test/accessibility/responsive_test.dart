import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/privacy/privacy_screen.dart';

const _sizes = <String, Size>{
  '320x568': Size(320, 568),
  '375x667': Size(375, 667),
  'tablet': Size(800, 1280),
};

void main() {
  for (final entry in _sizes.entries) {
    final label = entry.key;
    final size = entry.value;

    testWidgets('home renders without overflow at $label', (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );
      await _expectNoOverflow(tester);
    });

    testWidgets('grammar renders without overflow at $label', (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: GrammarScreen(exercises: [_grammarIncorrect()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await _expectNoOverflow(tester);
    });

    testWidgets('grammar summary renders without overflow at $label', (
      tester,
    ) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: GrammarScreen(exercises: [_grammarCorrect()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Corect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await _expectNoOverflow(tester);
      expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    });

    testWidgets('vocabulary renders without overflow at $label', (
      tester,
    ) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: VocabularyScreen(exercises: [_vocabulary()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('foarte simplu'));
      await _expectNoOverflow(tester);
    });

    testWidgets('idioms renders without overflow at $label', (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: IdiomsScreen(exercises: [_idiom()]),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('a pleca'));
      await _expectNoOverflow(tester);
    });

    testWidgets('spot renders without overflow at $label', (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: SpotScreen(texts: [_spotText()]),
        ),
      );
      await tester.pump();
      await _expectNoOverflow(tester);
    });

    testWidgets('spot summary renders without overflow at $label', (
      tester,
    ) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: SpotScreen(texts: [_spotText()]),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Mie'));
      await tester.pump();
      await tester.tap(find.text('Vezi rezumatul'));
      await tester.pump();
      await _expectNoOverflow(tester);
      expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    });

    testWidgets('privacy renders without overflow at $label', (tester) async {
      _setSize(tester, size);
      await tester.pumpWidget(
        const MaterialApp(home: PrivacyScreen()),
      );
      await _expectNoOverflow(tester);
    });
  }
}

Future<void> _expectNoOverflow(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'layout overflow detected');
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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

GrammarExercise _grammarCorrect() {
  return GrammarExercise(
    id: 'g2',
    sentence: 'Copiii au plecat la școală.',
    category: 'test',
    topic: 'test',
    isCorrect: true,
    explanation: 'Propoziția este corectă.',
    correctSentence: null,
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
