import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_game_card.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';

void main() {
  testWidgets('renders number, title, and chevron and handles tap', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            number: '01',
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            progress: 0.6,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('01'), findsOneWidget);
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    await tester.tap(find.text('Corect sau greșit?'));
    expect(tapped, isTrue);
  });

  testWidgets('fills width proportional to progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            number: '01',
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            progress: 0.6,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fill = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('game_card_fill')),
    );
    expect(fill.widthFactor, closeTo(0.6, 0.001));
  });

  testWidgets('clamps progress and fills zero and full', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            number: '01',
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            progress: -1,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var fill = tester.widget<FractionallySizedBox>(
      find.byKey(const ValueKey('game_card_fill')),
    );
    expect(fill.widthFactor, 0.0);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioGameCard(
            number: '01',
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            progress: 2,
            onTap: () {},
          ),
        ),
      ),
    );
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
            number: '01',
            title: 'Corect sau greșit?',
            accentColor: LexioColors.primary,
            mutedColor: LexioColors.blueMuted,
            progress: 0.6,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Joc 01: Corect sau greșit?, progres 60%'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
