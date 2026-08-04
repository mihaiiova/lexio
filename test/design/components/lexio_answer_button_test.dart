import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/colors.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_answer_button.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';

void main() {
  testWidgets('applies feedback colors and handles taps', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioAnswerButton(
            label: 'Răspuns',
            state: LexioAnswerButtonState.incorrect,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(LexioAnswerButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, LexioColors.redMuted);
    expect(decoration.border!.top.color, LexioColors.red);

    await tester.tap(find.text('Răspuns'));
    expect(tapped, isTrue);
  });

  testWidgets('disabled answer does not handle taps', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: Scaffold(
          body: LexioAnswerButton(
            label: 'Indisponibil',
            state: LexioAnswerButtonState.disabled,
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Indisponibil'));
    expect(tapCount, 0);
  });
}
