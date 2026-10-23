import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/games/spot/spot_content.dart';
import 'package:lexio/games/spot/spot_game.dart';
import 'package:lexio/games/spot/spot_screen.dart';
import 'package:lexio/games/spot/widgets/spot_summary.dart';

import '../../support/analytics_fakes.dart';

SpotText text(String id) => SpotText(
  id: id,
  type: 'story',
  title: 'Test',
  difficulty: 1,
  content: 'Mie place oras aici',
  mistakes: const [
    SpotMistake(
      wordIndex: 0,
      token: 'Mie',
      replacement: 'Mi-e',
      explanation: 'Cratimă',
      category: 'ortografie',
      topic: 'cratima',
    ),
    SpotMistake(
      wordIndex: 2,
      token: 'oras',
      replacement: 'oraș',
      explanation: 'Diacritice',
      category: 'ortografie',
      topic: 'diacritice',
    ),
  ],
);

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump();
}

void main() {
  testWidgets(
    'Spot observes repeat presses without changing discoveries or gameplay score',
    (tester) async {
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(transport);
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: SpotScreen(
            texts: [text('a')],
            mode: SpotGameMode.normal,
            analytics: repo,
          ),
        ),
      );
      await settle(tester);
      for (final position in [1, 1, 0, 0, 2]) {
        await tester.tap(find.byKey(ValueKey('0_$position')));
        await settle(tester);
      }
      await tester.tap(find.text('Vezi rezumatul'));
      await settle(tester);
      await repo.flush();
      final presses = transport.events
          .where((e) => e.kind.wireName == 'spot_attempt')
          .map((e) => e.toJson())
          .toList();
      expect(presses.map((e) => e['attemptDelta']), [1, 1, 1, 1, 1]);
      expect(presses.map((e) => e['correctDiscoveryDelta']), [0, 0, 1, 0, 1]);
      expect(presses.map((e) => e['distinctWrongDelta']), [1, 0, 0, 0, 0]);
      expect(
        transport.events.where(
          (e) => e.kind == AnalyticsEventKind.itemAnswered,
        ),
        isEmpty,
      );
      expect(
        transport.events.where(
          (e) => e.kind == AnalyticsEventKind.itemResolved,
        ),
        hasLength(1),
      );
      expect(transport.events.last.reason, AnalyticsRoundEndReason.completed);
      expect(
        tester.widget<SpotSummary>(find.byType(SpotSummary)).state.score,
        175,
      ); // Two discoveries minus one distinct wrong; repeats do not change score.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
