import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_repository.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_settings_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_transport.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/consent_storage.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/pending_round.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/idioms/idioms_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/spot/spot_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/vocabulary/vocabulary_content.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/home/home_screen.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/progress/user_progress.dart';

void main() {
  setUp(() {
    // Seed empty content so HomeScreen discovery does not wait on rootBundle.
    GrammarContent.seed(const []);
    VocabularyContent.seed(const []);
    IdiomsContent.seed(const []);
    SpotContent.seed(const []);
  });

  testWidgets('launch recovers a different game once without entering Grammar', (tester) async {
    final consent = _MemoryConsentStorage();
    final pending = _MemoryPendingRoundStorage();
    final first = await AnalyticsRepository.load(storage: consent,
      pendingRoundStorage: pending, transport: _FakeTransport());
    await first.enable();
    await first.startRound(gameId: 'spot', contentVersion: '1');
    await first.itemShown(itemId: 'spot_1', itemIndex: 0);
    await first.flush();
    final transport = _FakeTransport();
    final relaunched = await AnalyticsRepository.load(storage: consent,
      pendingRoundStorage: pending, transport: transport);
    final progress = await ProgressRepository.load(storage: _MemoryProgressStorage());
    await tester.pumpWidget(MaterialApp(home: HomeScreen(
      analyticsRepository: relaunched, progressRepository: progress)));
    await tester.pumpAndSettle();
    await relaunched.flush();
    expect(transport.events, hasLength(1));
    expect(transport.events.single.gameId, 'spot');
    expect(transport.events.single.reason, AnalyticsRoundEndReason.inferredInterruption);
    expect(transport.events.single.toJson()['itemState'], 'unresolved');
    await tester.pump();
    await relaunched.reconcileInterruptedRound();
    await relaunched.flush();
    expect(transport.events, hasLength(1));
  });

  testWidgets('first-launch opt-in enables collection', (tester) async {
    final analytics = await _undecidedRepo();
    final progress = await ProgressRepository.load(
      storage: _MemoryProgressStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: HomeScreen(
          progressRepository: progress,
          analyticsRepository: analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Analiză anonimă'), findsOneWidget);
    expect(find.textContaining('calitatea exercițiilor'), findsOneWidget);

    await tester.tap(find.text('Permite'));
    await tester.pumpAndSettle();

    expect(analytics.isConsentEnabled, isTrue);
  });

  testWidgets('first-launch opt-in can be declined without losing gameplay', (
    tester,
  ) async {
    final analytics = await _undecidedRepo();
    final progress = await ProgressRepository.load(
      storage: _MemoryProgressStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: HomeScreen(
          progressRepository: progress,
          analyticsRepository: analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nu, mulțumesc'));
    await tester.pumpAndSettle();

    expect(analytics.isConsentEnabled, isFalse);
    expect(analytics.isConsentUndecided, isFalse);
  });

  testWidgets('settings entry opens the analytics settings screen', (
    tester,
  ) async {
    final analytics = await _undecidedRepo();
    final progress = await ProgressRepository.load(
      storage: _MemoryProgressStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: HomeScreen(
          progressRepository: progress,
          analyticsRepository: analytics,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Dismiss the first-launch prompt first.
    await tester.tap(find.text('Nu, mulțumesc'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Setări'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setări'));
    await tester.pumpAndSettle();

    expect(find.byType(AnalyticsSettingsScreen), findsOneWidget);
  });
}

Future<AnalyticsRepository> _undecidedRepo() {
  return AnalyticsRepository.load(
    storage: _MemoryConsentStorage(),
    pendingRoundStorage: _MemoryPendingRoundStorage(),
    transport: _FakeTransport(),
    random: Random(1),
  );
}

final class _FakeTransport implements AnalyticsTransport {
  final events = <AnalyticsEvent>[];
  @override
  Future<void> sendEvents(List<AnalyticsEvent> eventsToSend, {String? deletionSecret}) async { events.addAll(eventsToSend); }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {}
}

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    value = updated;
  }
}

final class _MemoryPendingRoundStorage implements PendingRoundStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    value = updated;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

final class _MemoryProgressStorage implements ProgressStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    value = updated;
  }
}
