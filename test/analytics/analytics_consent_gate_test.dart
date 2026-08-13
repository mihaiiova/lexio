import 'package:flutter_test/flutter_test.dart';

import 'package:lexio/analytics/analytics_service.dart';
import 'package:lexio/app/app.dart';

void main() {
  setUp(() {
    AnalyticsService.resetForTesting();
  });

  testWidgets('first launch shows the analytics consent gate', (tester) async {
    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    expect(find.text('Statistici anonime'), findsOneWidget);
    expect(find.text('Sunt de acord'), findsOneWidget);
    expect(find.text('Fără statistici'), findsOneWidget);
    expect(find.text('Slove'), findsNothing);
  });

  testWidgets('declining consent opens the home screen with analytics off', (
    tester,
  ) async {
    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fără statistici'));
    await tester.pumpAndSettle();

    expect(AnalyticsService.consent, isFalse);
    expect(find.text('Slove'), findsOneWidget);
  });

  testWidgets('accepting consent opens the home screen with analytics on', (
    tester,
  ) async {
    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sunt de acord'));
    await tester.pumpAndSettle();

    expect(AnalyticsService.consent, isTrue);
    expect(find.text('Slove'), findsOneWidget);
  });

  testWidgets('gate is skipped once consent has been decided', (tester) async {
    AnalyticsService.resetForTesting();
    await AnalyticsService.setConsent(false);

    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    expect(find.text('Statistici anonime'), findsNothing);
    expect(find.text('Slove'), findsOneWidget);
  });
}
