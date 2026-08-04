import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_game_summary.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';

void main() {
  testWidgets('keeps actions fixed while review items scroll', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var replayCount = 0;
    var backCount = 0;
    final items = List.generate(
      8,
      (index) => LexioReviewItem(
        wrongAnswer: 'Greșeală ${index + 1}',
        correctAnswer: 'Corect ${index + 1}',
        explanation: 'Explicație ${index + 1}',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameSummary(
            gameNumber: '02',
            gameTitle: 'Ce înseamnă?',
            accentColor: LexioColors.coral,
            correctCount: 8,
            totalCount: 10,
            reviewItems: items,
            onPlayAgain: () => replayCount++,
            onBack: () => backCount++,
          ),
        ),
      ),
    );

    expect(find.text('8 din 10'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsOneWidget);
    expect(find.text('Foarte bine.'), findsNothing);
    final replayTop = tester.getTopLeft(find.text('Joacă din nou')).dy;

    await tester.scrollUntilVisible(
      find.text('Greșeală 8'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(tester.getTopLeft(find.text('Joacă din nou')).dy, replayTop);
    await tester.tap(find.text('Joacă din nou'));
    await tester.tap(find.text('Înapoi la jocuri'));
    expect(replayCount, 1);
    expect(backCount, 1);
  });

  testWidgets('hides review heading when the round has no mistakes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameSummary(
            gameNumber: '03',
            gameTitle: 'Vorba vine',
            accentColor: LexioColors.teal,
            correctCount: 10,
            totalCount: 10,
            reviewItems: const [],
            onPlayAgain: () {},
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.text('10 din 10'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsNothing);
    expect(find.text('Joacă din nou'), findsOneWidget);
    expect(find.text('Înapoi la jocuri'), findsOneWidget);
  });
}
