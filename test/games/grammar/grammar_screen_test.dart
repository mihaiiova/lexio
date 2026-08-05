import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/games/grammar/grammar_screen.dart';

void main() {
  testWidgets('round shows summary after completing all exercises', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GrammarScreen()));

    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.pump();

    for (int i = 0; i < 15; i++) {
      await tester.tap(find.text('Corect'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 400));

      final nextBtn = find.text('Următoarea');
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn);
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
    expect(find.byTooltip('Închide'), findsNothing);
    expect(find.text('Joacă din nou'), findsOneWidget);
    expect(find.text('Înapoi la jocuri'), findsOneWidget);
  });
}
