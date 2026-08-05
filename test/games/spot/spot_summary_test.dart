import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/spot_game.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/widgets/spot_summary.dart';

void main() {
  testWidgets('lists unfound mistakes and incorrect taps', (tester) async {
    final text = SpotText(
      id: 'one',
      type: 'story',
      title: 'Test',
      difficulty: 1,
      content: 'Pisica are ghiare.',
      mistakes: const [
        SpotMistake(
          wordIndex: 2,
          token: 'ghiare',
          replacement: 'gheare',
          explanation: 'Forma corectă este „gheare”.',
          category: 'ortografie',
          topic: 'scriere',
        ),
      ],
    );
    final state = SpotGameState(
      texts: [text],
      incorrectTapWordIndices: [
        {0},
      ],
      isFinished: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: SpotSummary(state: state, onPlayAgain: () {}, onClose: () {}),
        ),
      ),
    );

    expect(find.text('0 din 1'), findsOneWidget);
    expect(find.text('ghiare'), findsOneWidget);
    expect(find.text('Corect: gheare', findRichText: true), findsOneWidget);
    expect(find.text('Ai selectat „Pisica”.'), findsOneWidget);
  });
}
