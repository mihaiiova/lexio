import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/games/spot/spot_screen.dart';

void main() {
  testWidgets('renders injected texts without loading content', (tester) async {
    final text = _spotText();

    await tester.pumpWidget(
      MaterialApp(theme: LexioTheme.light, home: SpotScreen(texts: [text])),
    );
    await tester.pump();

    expect(find.text('Mie'), findsOneWidget);
    expect(find.text('01:00'), findsOneWidget);
  });

  testWidgets('tapping a mistake reveals its correction', (tester) async {
    final text = _spotText();

    await tester.pumpWidget(
      MaterialApp(theme: LexioTheme.light, home: SpotScreen(texts: [text])),
    );
    await tester.pump();

    await tester.tap(find.text('Mie'));
    await tester.pump();

    expect(find.text('Mi-e'), findsOneWidget);
  });
}

SpotText _spotText() {
  return SpotText(
    id: 'spot_one',
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
