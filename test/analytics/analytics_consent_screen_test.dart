import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexio/analytics/analytics_consent_screen.dart';
import 'package:lexio/analytics/analytics_repository.dart';
import 'package:lexio/design/components/lexio_button.dart';
import 'package:lexio/design/theme.dart';
import 'package:lexio/privacy/privacy_screen.dart';

import '../support/analytics_fakes.dart';

void main() {
  testWidgets('both consent choices use white-on-black full-width buttons', (
    tester,
  ) async {
    final repo = await analyticsRepository(
      RecordingAnalyticsTransport(),
      enabled: false,
    );
    await _openConsent(tester, repo);
    for (final label in ['Permite analiza utilizării', 'Nu, mulțumesc']) {
      final button = tester.widget<LexioButton>(
        find.widgetWithText(LexioButton, label),
      );
      expect(button.isExpanded, isTrue);
      final control = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, label),
      );
      expect(control.style!.backgroundColor!.resolve({}), Colors.black);
      expect(control.style!.foregroundColor!.resolve({}), Colors.white);
    }
  });

  testWidgets('onboarding omits the removed assurances', (tester) async {
    final repo = await analyticsRepository(
      RecordingAnalyticsTransport(),
      enabled: false,
    );
    await _openConsent(tester, repo);
    expect(
      find.text('Nu colectăm nume, răspunsuri sau texte introduse.'),
      findsNothing,
    );
    expect(
      find.text('Jocurile funcționează la fel și fără acord.'),
      findsNothing,
    );
  });

  testWidgets('reading privacy does not choose or enable analytics', (
    tester,
  ) async {
    final transport = RecordingAnalyticsTransport();
    final repo = await analyticsRepository(transport, enabled: false);
    await _openConsent(tester, repo);
    await repo.startRound(gameId: 'grammar', contentVersion: '1');
    await repo.flush();
    expect(transport.events, isEmpty);

    await tester.ensureVisible(find.text('Detalii despre confidențialitate'));
    await tester.tap(find.text('Detalii despre confidențialitate'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(repo.isConsentEnabled, isFalse);
    expect(repo.isConsentUndecided, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Ne ajuți să îmbunătățim Slove?'), findsOneWidget);
    expect(repo.isConsentUndecided, isTrue);
    expect(transport.events, isEmpty);
  });

  testWidgets('back leaves safely without affirmative consent', (tester) async {
    final transport = RecordingAnalyticsTransport();
    final storage = MemoryAnalyticsStorage();
    final repo = await analyticsRepository(
      transport,
      enabled: false,
      storage: storage,
    );
    await _openConsent(tester, repo);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Jocuri'), findsOneWidget);
    expect(repo.isConsentEnabled, isFalse);
    expect(repo.isConsentUndecided, isFalse);
    final restored = await analyticsRepository(
      transport,
      enabled: false,
      storage: storage,
    );
    expect(restored.isConsentUndecided, isFalse);
    expect(restored.isConsentEnabled, isFalse);
  });

  testWidgets('failed activation returns to games with collection off', (
    tester,
  ) async {
    final transport = RecordingAnalyticsTransport();
    final repo = await analyticsRepository(
      transport,
      enabled: false,
      storage: _FailingStorage(),
    );
    await _openConsent(tester, repo);
    await tester.ensureVisible(find.text('Permite analiza utilizării'));
    await tester.tap(find.text('Permite analiza utilizării'));
    await tester.pumpAndSettle();
    expect(find.text('Jocuri'), findsOneWidget);
    expect(repo.isConsentEnabled, isFalse);
    expect(find.textContaining('Analiza rămâne oprită'), findsOneWidget);
    expect(transport.events, isEmpty);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(1024, 768),
  ]) {
    for (final scale in [1.0, 2.0, 3.2]) {
      testWidgets(
        'consent at $size and text scale $scale remains readable and actionable',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repo = await analyticsRepository(
            RecordingAnalyticsTransport(),
            enabled: false,
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: LexioTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: AnalyticsConsentScreen(repository: repo),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final label in [
            'Permite analiza utilizării',
            'Nu, mulțumesc',
            'Detalii despre confidențialitate',
          ]) {
            final finder = find.text(label);
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();
            expect(finder.hitTestable(), findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(finder);
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '$label is truncated',
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('consent actions have accessible labels and tap targets', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = await analyticsRepository(
      RecordingAnalyticsTransport(),
      enabled: false,
    );
    await _openConsent(tester, repo);
    await tester.ensureVisible(find.text('Permite analiza utilizării'));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}

Future<void> _openConsent(WidgetTester tester, AnalyticsRepository repo) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: LexioTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showAnalyticsConsentScreen(context, repo),
            child: const Text('Jocuri'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Jocuri'));
  await tester.pumpAndSettle();
}

class _FailingStorage extends MemoryAnalyticsStorage {
  @override
  Future<void> write(String value) async =>
      throw StateError('storage unavailable');
}
