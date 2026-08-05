import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_game_summary.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/typography.dart';

void main() {
  testWidgets('scrolls the full summary and exposes a close action', (
    tester,
  ) async {
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
            accentColor: LexioColors.coral,
            correctCount: 8,
            totalCount: 10,
            reviewItems: items,
            onPlayAgain: () => replayCount++,
            onClose: () => backCount++,
          ),
        ),
      ),
    );

    expect(find.text('8 din 10'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsOneWidget);
    expect(find.text('Foarte bine.'), findsNothing);
    expect(find.text('Slove'), findsNothing);
    expect(find.text('Ce înseamnă?'), findsNothing);
    expect(find.text('Înapoi la jocuri'), findsNothing);
    expect(find.byTooltip('Închide'), findsOneWidget);

    final result = tester.widget<Text>(find.text('8 din 10'));
    expect(result.style?.fontSize, LexioTextStyles.displayLarge.fontSize);

    await tester.drag(
      find.byKey(const ValueKey('summary_scroll_view')),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Închide'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Joacă din nou'),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Joacă din nou'));
    await tester.scrollUntilVisible(
      find.byTooltip('Închide'),
      -300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byTooltip('Închide'));
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
            accentColor: LexioColors.teal,
            correctCount: 10,
            totalCount: 10,
            reviewItems: const [],
            onPlayAgain: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('10 din 10'), findsOneWidget);
    expect(find.text('DE REVĂZUT'), findsNothing);
    expect(find.text('Joacă din nou'), findsOneWidget);
    expect(find.byTooltip('Închide'), findsOneWidget);
  });
}
