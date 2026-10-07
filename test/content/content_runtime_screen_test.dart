import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/content/content_bundle_service.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/content/content_runtime.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/design/theme.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_screen.dart';

String _bundle(String id, String sentence) => jsonEncode({
  'schemaVersion': 1,
  'grammar': [
    {
      'id': id,
      'notionId': id,
      'sentence': sentence,
      'category': 'test',
      'topic': 'test',
      'isCorrect': false,
      'explanation': 'Explicație de test.',
      'correctSentence': '$sentence corectat',
      'difficulty': 1,
      'tags': <String>[],
      'pairId': id,
    },
  ],
  'vocabulary': <dynamic>[],
  'idioms': <dynamic>[],
  'spotTexts': <dynamic>[],
  'hyphenationPairs': <dynamic>[],
  'commonErrorPairs': <dynamic>[],
});

String _manifest(int version) => jsonEncode({
  'schemaVersion': 1,
  'contentVersion': version,
  'bundleUrl': 'https://content.example/content_bundle_$version.json',
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a staged update waits for the next round boundary', (
    tester,
  ) async {
    final cache = _FakeCache()
      ..version = 1
      ..bundles[1] = _bundle('old', 'Conținut vechi');
    final transport = _FakeTransport(
      manifest: _manifest(2),
      bundle: _bundle('new', 'Conținut nou'),
    );
    final service = ContentBundleService(cache: cache, transport: transport);
    await service.start();
    ContentRuntime.install(service);

    await tester.pumpWidget(
      MaterialApp(theme: LexioTheme.light, home: GrammarScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Conținut vechi'), findsOneWidget);

    await service.refresh();
    await tester.pump();
    expect(find.text('Conținut vechi'), findsOneWidget);
    expect(find.text('Conținut nou'), findsNothing);

    await tester.tap(find.text('Corect'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Următoarea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joacă din nou'));
    await tester.pumpAndSettle();

    expect(find.text('Conținut nou'), findsOneWidget);
    ContentRuntime.reset();
  });
}

final class _FakeTransport implements ContentTransport {
  _FakeTransport({required this.manifest, required this.bundle});

  final String manifest;
  final String bundle;

  @override
  Future<String> fetchManifest() async => manifest;

  @override
  Future<String> fetchBundle(String url) async => bundle;
}

final class _FakeCache implements ContentCache {
  final Map<int, String> bundles = {};
  int? version;

  @override
  Future<CachedContent?> read() async {
    final current = version;
    final bundle = current == null ? null : bundles[current];
    if (current == null || bundle == null) return null;
    return CachedContent(version: current, bundle: bundle);
  }

  @override
  Future<void> write(CachedContent content) async {
    bundles[content.version] = content.bundle;
    version = content.version;
  }
}
