import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';

void main() {
  testWidgets('grammar entry navigates to the injected grammar screen', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Corect sau greșit?'));
    await tester.pumpAndSettle();
    expect(find.text('GRAMMAR_SCREEN'), findsOneWidget);
  });

  testWidgets('vocabulary entry navigates to the injected vocabulary screen', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Ce înseamnă?'));
    await tester.pumpAndSettle();
    expect(find.text('VOCABULARY_SCREEN'), findsOneWidget);
  });

  testWidgets('idioms entry navigates to the injected idioms screen', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Vorba vine'));
    await tester.pumpAndSettle();
    expect(find.text('IDIOMS_SCREEN'), findsOneWidget);
  });

  testWidgets('spot entry navigates to the injected spot screen', (
    tester,
  ) async {
    await _pumpHome(tester);
    await tester.tap(find.text('Găsește greșeala'));
    await tester.pumpAndSettle();
    expect(find.text('SPOT_SCREEN'), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) {
  return tester.pumpWidget(
    MaterialApp(
      theme: LexioTheme.light,
      home: HomeScreen(
        grammarScreenBuilder: () => const _TargetScreen('GRAMMAR_SCREEN'),
        vocabularyScreenBuilder: () =>
            const _TargetScreen('VOCABULARY_SCREEN'),
        idiomsScreenBuilder: () => const _TargetScreen('IDIOMS_SCREEN'),
        spotScreenBuilder: () => const _TargetScreen('SPOT_SCREEN'),
      ),
    ),
  );
}

final class _TargetScreen extends StatelessWidget {
  const _TargetScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
