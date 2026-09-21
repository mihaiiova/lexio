import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:lexio/analytics/analytics_service.dart';
import 'package:lexio/app/app.dart';

Future<void> _shot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

/// Waits for async content loading (rootBundle + shared_preferences) that
/// runs on the real event loop, then settles remaining animations.
Future<void> _waitForContent(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  await tester.pumpAndSettle();
}

/// Games use a mix of app-bar back controls and summary action rows.
Future<void> _leaveGame(WidgetTester tester) async {
  final backButton = find.byType(BackButton);
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
  } else {
    final backIcon = find.byIcon(Icons.arrow_back);
    if (backIcon.evaluate().isNotEmpty) {
      await tester.tap(backIcon);
    } else {
      await tester.tap(find.text('Înapoi la jocuri'));
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture app screenshots', (tester) async {
    await AnalyticsService.initialize();
    await tester.pumpWidget(const LexioApp());
    await tester.pumpAndSettle();

    await _shot(binding, tester, '01_home');

    const games = <String, String>{
      'Corect sau greșit?': '02_grammar',
      'Ce înseamnă?': '03_vocabulary',
      'Vorba vine': '04_idioms',
      'Găsește greșeala': '05_spot',
    };

    for (final entry in games.entries) {
      final title = find.text(entry.key);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await _waitForContent(tester);

      await _shot(binding, tester, entry.value);

      if (entry.key == 'Corect sau greșit?') {
        for (var question = 0; question < 15; question++) {
          final answerButton = find.text('Corect');
          if (answerButton.evaluate().isEmpty) break;
          await tester.tap(answerButton);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();

          final nextButton = find.text('Următoarea');
          if (nextButton.evaluate().isNotEmpty) {
            await tester.tap(nextButton);
            await tester.pumpAndSettle();
          }
        }
        expect(find.text('RUNDĂ ÎNCHEIATĂ'), findsOneWidget);
        await _shot(binding, tester, '06_summary');
      }

      await _leaveGame(tester);
    }
  });
}
