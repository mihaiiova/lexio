import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/idioms_game.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/idioms/widgets/idioms_summary.dart';

void main() {
  testWidgets('forwards discovery counts to the shared summary', (
    tester,
  ) async {
    final exercise = IdiomExercise(
      id: 'one',
      expression: 'a pune umărul',
      meaning: 'a ajuta',
      example: 'Toți au pus umărul la proiect.',
      highlightedText: 'au pus umărul',
      options: const ['a pleca', 'a ajuta', 'a aștepta'],
      correctOptionIndex: 1,
      category: 'test',
      difficulty: 1,
    );
    final state = IdiomsGameState(exercises: [exercise]);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: IdiomsSummary(
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
