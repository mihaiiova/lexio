import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/home/discovery_catalog.dart';
import 'package:lexio/home/home_screen.dart';
import 'package:lexio/progress/user_progress.dart';

import '../support/analytics_fakes.dart';

class MemoryProgressStorage implements ProgressStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String value) async {}
}

void main() {
  testWidgets(
    'Home passes one consented repository into all four real game screens',
    (tester) async {
      await tester.runAsync(DiscoveryCatalog.totalNotionsByGame);
      final transport = RecordingAnalyticsTransport();
      final repo = await analyticsRepository(transport);
      final progress = await ProgressRepository.load(
        storage: MemoryProgressStorage(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: HomeScreen(
            progressRepository: progress,
            analyticsRepository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final entry in {
        'Ce înseamnă?': 'vocabulary',
        'Vorba vine': 'idioms',
        'Găsește greșeala': 'spot',
        'Corect sau greșit?': 'grammar',
      }.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events.last.gameId, entry.value);
        expect(transport.events.last.kind.wireName, 'item_shown');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await repo.flush();
        expect(transport.events.last.reason?.wireName, 'user_back');
      }
    },
  );
}
