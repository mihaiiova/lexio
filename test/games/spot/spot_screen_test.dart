import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/games/spot/spot_screen.dart';

void main() {
  testWidgets('shows a safe empty state when no texts are supplied', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SpotScreen(texts: [])));

    expect(find.text('Nu există texte disponibile'), findsOneWidget);
  });
}
