import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/analytics/analytics_repository.dart';
import 'package:lexio/analytics/analytics_settings_screen.dart';
import 'package:lexio/analytics/analytics_transport.dart';
import 'package:lexio/analytics/consent_storage.dart';
import 'package:lexio/analytics/pending_round.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/privacy/privacy_screen.dart';

void main() {
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

  for (final state in ['off', 'enabled', 'awaiting deletion']) {
    testWidgets('privacy details stay accessible when analytics is $state', (
      tester,
    ) async {
      final transport = _FakeTransport();
      final repo = await _repo(transport);
      if (state != 'off') await repo.enable();
      if (state == 'awaiting deletion') await repo.disable();
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
      expect(transport.deletions, isEmpty);
    });
  }

  testWidgets('enables and disables collection from the switch', (
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
    expect(repo.needsDeletion, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(find.textContaining('Înainte de reactivare'), findsOneWidget);
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
    expect(restored.needsDeletion, isTrue);
  });

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
  final List<Map<String, String>> deletions = [];
  final List<AnalyticsEvent> events = [];

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
