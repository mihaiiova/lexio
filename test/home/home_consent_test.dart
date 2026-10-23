import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_consent_dialog.dart';
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

  testWidgets(
    'launch recovers a different game once without entering Grammar',
    (tester) async {
      final consent = _MemoryConsentStorage();
      final queue = _MemoryConsentStorage();
      final pending = _MemoryPendingRoundStorage();
      final first = await AnalyticsRepository.load(
        queueStorage: queue,
        storage: consent,
        pendingRoundStorage: pending,
        transport: _FakeTransport(),
      );
      await first.enable();
      await first.startRound(gameId: 'spot', contentVersion: '1');
      await first.itemShown(itemId: 'spot_1', itemIndex: 0);
      await first.flush();
      final transport = _FakeTransport();
      final relaunched = await AnalyticsRepository.load(
        queueStorage: queue,
        storage: consent,
        pendingRoundStorage: pending,
        transport: transport,
      );
      final progress = await ProgressRepository.load(
        storage: _MemoryProgressStorage(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            analyticsRepository: relaunched,
            progressRepository: progress,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await relaunched.flush();
      expect(transport.events, hasLength(1));
      expect(transport.events.single.gameId, 'spot');
      expect(
        transport.events.single.reason,
        AnalyticsRoundEndReason.inferredInterruption,
      );
      expect(transport.events.single.toJson()['itemState'], 'unresolved');
      await tester.pump();
      await relaunched.reconcileInterruptedRound();
      await relaunched.flush();
      expect(transport.events, hasLength(1));
    },
  );

  for (final label in ['Permite', 'Nu, mulțumesc']) {
    testWidgets('consent $label submits once and keeps underlying route', (
      tester,
    ) async {
      final storage = _MemoryConsentStorage()..gate = Completer<void>();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        queueStorage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: _FakeTransport(),
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: LexioTheme.light,
          home: const Scaffold(body: Text('root route')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAnalyticsConsentDialog(context, repo),
              child: const Text('underlying route'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('underlying route'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.tap(
        find.text(label == 'Permite' ? 'Nu, mulțumesc' : 'Permite'),
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      storage.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('underlying route'), findsOneWidget);
      expect(find.text('Analiză opțională'), findsNothing);
      expect(storage.writes, 1);
      expect(repo.isConsentEnabled, label == 'Permite');
    });
  }

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

    expect(find.text('Analiză opțională'), findsOneWidget);
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
    queueStorage: _MemoryConsentStorage(),
    storage: _MemoryConsentStorage(),
    pendingRoundStorage: _MemoryPendingRoundStorage(),
    transport: _FakeTransport(),
    random: Random(1),
  );
}

final class _FakeTransport implements AnalyticsTransport {
  final events = <AnalyticsEvent>[];
  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> eventsToSend, {
    String? deletionSecret,
  }) async {
    events.addAll(eventsToSend);
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {}
}

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;
  Completer<void>? gate;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    writes++;
    await gate?.future;
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
