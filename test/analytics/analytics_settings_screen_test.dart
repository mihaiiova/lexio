import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/analytics/analytics_repository.dart';
import 'package:lexio/analytics/analytics_settings_screen.dart';
import 'package:lexio/analytics/analytics_transport.dart';
import 'package:lexio/analytics/consent_storage.dart';
import 'package:lexio/analytics/pending_round.dart';
import 'package:lexio/design/components/lexio_button.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/privacy/privacy_screen.dart';
import 'package:lexio/reviews/app_review_service.dart';

void main() {
  testWidgets(
    'review button opens the store directly without a native prompt',
    (tester) async {
      var storeOpens = 0;
      var requests = 0;
      final repo = await _repo();
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: AnalyticsSettingsScreen(
            analytics: repo,
            reviewService: AppReviewService(
              supported: true,
              appStoreId: '123456789',
              openStoreListing: () async {
                storeOpens++;
              },
              requestReview: () async {
                requests++;
              },
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Evaluează aplicația'));
      await tester.tap(find.text('Evaluează aplicația'));
      await tester.pumpAndSettle();
      expect(storeOpens, 1);
      expect(requests, 0);
      expect(repo.isConsentEnabled, isFalse);
    },
  );

  testWidgets('failed store link shows a Romanian error', (tester) async {
    final repo = await _repo();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: AnalyticsSettingsScreen(
          analytics: repo,
          reviewService: AppReviewService(
            supported: true,
            appStoreId: '123456789',
            openStoreListing: () async => throw StateError('store'),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Evaluează aplicația'));
    await tester.tap(find.text('Evaluează aplicația'));
    await tester.pumpAndSettle();
    expect(
      find.text('Magazinul nu a putut fi deschis. Încearcă din nou.'),
      findsOneWidget,
    );
  });

  testWidgets('renders the optional analytics section and purpose', (
    tester,
  ) async {
    final repo = await _repo();

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: AnalyticsSettingsScreen(analytics: repo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Setări'), findsOneWidget);
    expect(find.text('Analiză opțională'), findsOneWidget);
    expect(
      find.textContaining('ne ajută să îmbunătățim jocurile'),
      findsOneWidget,
    );
    expect(find.textContaining('părinți sau tutori'), findsOneWidget);
    expect(find.textContaining('pe proprie răspundere'), findsNothing);
    expect(find.byType(Switch), findsOneWidget);
  });

  for (final state in ['off', 'enabled', 'paused', 'awaiting deletion']) {
    testWidgets('privacy details stay accessible when analytics is $state', (
      tester,
    ) async {
      final transport = _FakeTransport();
      final repo = await _repo(transport);
      if (state != 'off') await repo.enable();
      if (state == 'paused') await repo.disable();
      if (state == 'awaiting deletion') {
        transport.failDeletion = true;
        expect(await repo.disableAndDelete(), isFalse);
      }
      final deletionAttempts = transport.deletions.length;
      final enabled = repo.isConsentEnabled;
      final needsDeletion = repo.needsDeletion;
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: AnalyticsSettingsScreen(analytics: repo),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Detalii despre confidențialitate'));
      await tester.tap(find.text('Detalii despre confidențialitate'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(repo.isConsentEnabled, enabled);
      expect(repo.needsDeletion, needsDeletion);
      expect(transport.deletions, hasLength(deletionAttempts));
    });
  }

  testWidgets('enables, disables and re-enables collection without deletion', (
    tester,
  ) async {
    final transport = _FakeTransport()..failDeletion = true;
    final repo = await _repo(transport);

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: AnalyticsSettingsScreen(analytics: repo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Permite analiza utilizării'), findsOneWidget);
    await tester.ensureVisible(find.text('Permite analiza utilizării'));
    await tester.tap(find.text('Permite analiza utilizării'));
    await tester.pumpAndSettle();
    expect(repo.isConsentEnabled, isTrue);
    expect(find.text('Șterge datele de pe server'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.isConsentEnabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Permite analiza utilizării'));
    await tester.tap(find.text('Permite analiza utilizării'));
    await tester.pumpAndSettle();
    expect(repo.isConsentEnabled, isTrue);
    expect(transport.deletions, isEmpty);
  });

  testWidgets('withdrawal stops future events and persists across launches', (
    tester,
  ) async {
    final storage = _MemoryConsentStorage();
    final transport = _FakeTransport();
    Future<AnalyticsRepository> load() => AnalyticsRepository.load(
      storage: storage,
      queueStorage: _MemoryConsentStorage(),
      pendingRoundStorage: _MemoryPendingRoundStorage(),
      transport: transport,
    );
    final repo = await load();
    await repo.enable();
    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: AnalyticsSettingsScreen(analytics: repo),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await repo.startRound(gameId: 'grammar', contentVersion: '1');
    await repo.itemShown(itemId: 'question', itemIndex: 0);
    await repo.flush();
    expect(transport.events, isEmpty);
    final restored = await load();
    expect(restored.isConsentEnabled, isFalse);
    expect(restored.needsDeletion, isFalse);
    expect(restored.hasRetainedIdentity, isTrue);
  });

  testWidgets(
    'deletion stays available while off and a failed request blocks opt-in',
    (tester) async {
      final transport = _FakeTransport()..failDeletion = true;
      final repo = await _repo(transport);
      await repo.enable();
      await repo.disable();
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: AnalyticsSettingsScreen(analytics: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
      await tester.ensureVisible(find.text('Șterge datele de pe server'));
      await tester.tap(find.text('Șterge datele de pe server'));
      await tester.pumpAndSettle();
      expect(repo.isConsentEnabled, isFalse);
      expect(repo.needsDeletion, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(transport.deletions, hasLength(1));
    },
  );

  testWidgets('failed withdrawal save warns and offers a durable retry', (
    tester,
  ) async {
    final storage = _MemoryConsentStorage();
    final repo = await AnalyticsRepository.load(
      queueStorage: _MemoryConsentStorage(),
      storage: storage,
      pendingRoundStorage: _MemoryPendingRoundStorage(),
      transport: _FakeTransport(),
    );
    await repo.enable();
    storage.failWrites = true;
    await tester.pumpWidget(
      MaterialApp(home: AnalyticsSettingsScreen(analytics: repo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(repo.isConsentEnabled, isFalse);
    expect(find.textContaining('nu a putut fi salvată'), findsOneWidget);
    storage.failWrites = false;
    await tester.ensureVisible(find.text('Reîncearcă salvarea opririi'));
    await tester.tap(find.text('Reîncearcă salvarea opririi'));
    await tester.pumpAndSettle();
    expect(repo.consentPersistenceFailed, isFalse);
    expect(find.textContaining('nu a putut fi salvată'), findsNothing);
  });

  for (final state in ['enabled', 'paused', 'pending deletion']) {
    testWidgets('server deletion is unavailable without an endpoint ($state)', (
      tester,
    ) async {
      var networkCalls = 0;
      final client = MockClient((request) async {
        networkCalls++;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);
      final storage = _MemoryConsentStorage();
      final repo = await AnalyticsRepository.load(
        storage: storage,
        queueStorage: _MemoryConsentStorage(),
        pendingRoundStorage: _MemoryPendingRoundStorage(),
        transport: HttpAnalyticsTransport(baseUrl: '', client: client),
      );
      await repo.enable();
      if (state == 'paused') await repo.disable();
      if (state == 'pending deletion') {
        expect(await repo.disableAndDelete(), isFalse);
      }
      final savedConsent = storage.value;
      final enabled = repo.isConsentEnabled;
      final pendingDeletion = repo.needsDeletion;
      await tester.pumpWidget(
        MaterialApp(
          theme: LexioTheme.light,
          home: AnalyticsSettingsScreen(analytics: repo),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        LexioButton,
        'Șterge datele de pe server',
      );
      expect(tester.widget<LexioButton>(button).onPressed, isNull);
      expect(
        find.textContaining('serverul de analiză nu este configurat'),
        findsOneWidget,
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(networkCalls, 0);
      expect(storage.value, savedConsent);
      expect(repo.isConsentEnabled, enabled);
      expect(repo.needsDeletion, pendingDeletion);
      expect(
        find.text('Ștergerea nu a putut fi finalizată. Încearcă din nou.'),
        findsNothing,
      );
      expect(
        find.text('Datele legate de această instalare au fost șterse.'),
        findsNothing,
      );
    });
  }

  testWidgets('deletes this installation server records', (tester) async {
    final transport = _FakeTransport();
    final repo = await _repo(transport);
    await repo.enable();

    await tester.pumpWidget(
      MaterialApp(
        theme: LexioTheme.light,
        home: AnalyticsSettingsScreen(analytics: repo),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Șterge datele de pe server'));
    await tester.pumpAndSettle();

    expect(transport.deletions, hasLength(1));
    expect(repo.isConsentEnabled, isFalse);
    expect(repo.needsDeletion, isFalse);
    expect(
      find.text('Datele legate de această instalare au fost șterse.'),
      findsOneWidget,
    );
  });
}

Future<AnalyticsRepository> _repo([_FakeTransport? transport]) {
  return AnalyticsRepository.load(
    queueStorage: _MemoryConsentStorage(),
    storage: _MemoryConsentStorage(),
    pendingRoundStorage: _MemoryPendingRoundStorage(),
    transport: transport ?? _FakeTransport(),
    random: Random(1),
  );
}

final class _FakeTransport implements AnalyticsTransport {
  @override
  bool get isConfigured => true;

  final List<Map<String, String>> deletions = [];
  final List<AnalyticsEvent> events = [];
  bool failDeletion = false;

  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> batch, {
    String? deletionSecret,
  }) async {
    events.addAll(batch);
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {
    deletions.add({
      'installationId': installationId,
      'deletionSecret': deletionSecret,
    });
    if (failDeletion) throw StateError('offline');
  }
}

final class _MemoryConsentStorage implements ConsentStorage {
  String? value;
  bool failWrites = false;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String updated) async {
    if (failWrites) throw StateError('storage unavailable');
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
