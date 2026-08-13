import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/analytics/analytics_service.dart';
import 'package:lexio/app/app.dart';

Future<void> _pumpPastConsent(WidgetTester tester) async {
  await tester.pumpWidget(const LexioApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Fără statistici'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AnalyticsService.resetForTesting();
  });

  testWidgets('App renders home screen', (WidgetTester tester) async {
    await _pumpPastConsent(tester);

    expect(find.text('Slove'), findsOneWidget);
    expect(find.text('Provocarea zilei'), findsNothing);
    expect(find.text('Alege un joc'), findsNothing);
    expect(find.text('Corect sau greșit?'), findsOneWidget);
    expect(find.text('Ce înseamnă?'), findsOneWidget);
    expect(find.text('Vorba vine'), findsOneWidget);
    expect(find.text('Găsește greșeala'), findsOneWidget);
    expect(find.text('În pregătire'), findsNothing);

    expect(find.byType(InkWell), findsNWidgets(5));
  });
}
