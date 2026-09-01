import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../../lib/design/components/lexio_discovery_progress.dart';
// ignore: avoid_relative_lib_imports
import '../../../lib/design/theme.dart';

void main() {
  testWidgets('renders fill fraction and count label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: const Scaffold(
          body: LexioDiscoveryProgress(discovered: 12, total: 100),
        ),
      ),
    );

    expect(find.text('12 din 100'), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, closeTo(0.12, 0.0001));
  });

  testWidgets('exposes a single semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: const Scaffold(
          body: LexioDiscoveryProgress(discovered: 3, total: 10),
        ),
      ),
    );

    expect(find.bySemanticsLabel('3 din 10'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('handles empty, full, and zero-total boundaries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              LexioDiscoveryProgress(discovered: 0, total: 100),
              LexioDiscoveryProgress(discovered: 100, total: 100),
              LexioDiscoveryProgress(discovered: 0, total: 0),
            ],
          ),
        ),
      ),
    );

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(indicators, hasLength(3));
    expect(indicators[0].value, 0);
    expect(indicators[1].value, 1);
    expect(indicators[2].value, 0);
    expect(find.text('0 din 100'), findsOneWidget);
    expect(find.text('100 din 100'), findsOneWidget);
    expect(find.text('0 din 0'), findsOneWidget);
  });
}
