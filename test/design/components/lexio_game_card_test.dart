import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_game_card.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/typography.dart';

void main() {
  testWidgets('renders card content and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            discovered: 12,
            total: 234,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('12/234'), findsOneWidget);
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Corect sau greșit?')).style?.fontSize,
      LexioTextStyles.displayMedium.fontSize,
    );

    await tester.tap(find.text('Corect sau greșit?'));
    expect(tapped, isTrue);
  });

  testWidgets('fills width proportionally and clamps bounds', (tester) async {
    Future<void> pumpCard(int discovered, int total) {
      return tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: Scaffold(
            body: LexioGameCard(
              title: 'Corect sau greșit?',
              accentColor: LexioColors.primary,
              mutedColor: LexioColors.blueMuted,
              discovered: discovered,
              total: total,
              onTap: () {},
            ),
          ),
        ),
      );
    }

    await pumpCard(60, 100);
    await tester.pumpAndSettle();
    var fill = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('game_card_fill')),
    );
    expect(fill.widthFactor, closeTo(0.6, 0.001));

    await pumpCard(150, 100);
    await tester.pumpAndSettle();
    fill = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('game_card_fill')),
    );
    expect(fill.widthFactor, 1.0);
  });

  testWidgets('exposes an accessible label with progress', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            discovered: 12,
            total: 234,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Joc Corect sau greșit?, progres 12 din 234'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
