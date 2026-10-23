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
    expect(find.textContaining('calitatea exercițiilor'), findsOneWidget);
    expect(find.textContaining('pe proprie răspundere'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

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
    expect(find.text('Permite'), findsOneWidget);
    await tester.tap(find.text('Permite'));
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

  testWidgets('failed withdrawal save warns and offers a durable retry', (
    tester,
  ) async {
    final storage = _MemoryConsentStorage();
    final repo = await AnalyticsRepository.load(
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
    storage: _MemoryConsentStorage(),
    pendingRoundStorage: _MemoryPendingRoundStorage(),
    transport: transport ?? _FakeTransport(),
    random: Random(1),
  );
}

final class _FakeTransport implements AnalyticsTransport {
  final List<Map<String, String>> deletions = [];

  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> events, {
    String? deletionSecret,
  }) async {}

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
