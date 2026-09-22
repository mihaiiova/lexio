import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/content/content_bundle_service.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/content/content_runtime.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/games/grammar/grammar_content.dart';

String _minimalBundle(String notionId) {
  return jsonEncode({
    'schemaVersion': 1,
    'grammar': [
      {
        'id': 'w0',
        'notionId': notionId,
        'sentence': 'x',
        'category': 'c',
        'topic': 't',
        'isCorrect': false,
        'explanation': 'e',
        'correctSentence': 'y',
        'difficulty': 1,
        'tags': <String>[],
        'pairId': notionId,
      },
    ],
    'vocabulary': <dynamic>[],
    'idioms': <dynamic>[],
    'spotTexts': <dynamic>[],
    'hyphenationPairs': <dynamic>[],
  });
}

String _manifest(int version, {int schemaVersion = 1, String? url}) {
  return jsonEncode({
    'schemaVersion': schemaVersion,
    'contentVersion': version,
    'bundleUrl': url ?? 'https://content.example/content_bundle_$version.json',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentManifest', () {
    test('parses a valid manifest', () {
      final manifest = ContentManifest.fromString(_manifest(3));
      expect(manifest.schemaVersion, 1);
      expect(manifest.contentVersion, 3);
      expect(manifest.bundleUrl, contains('content_bundle_3.json'));
    });

    test('rejects an unsupported schema version', () {
      expect(
        () => ContentManifest.fromString(_manifest(3, schemaVersion: 2)),
        throwsFormatException,
      );
    });

    test('rejects a non-positive content version', () {
      expect(
        () => ContentManifest.fromString(_manifest(0)),
        throwsFormatException,
      );
    });

    test('rejects an empty bundle URL', () {
      expect(
        () => ContentManifest.fromString(_manifest(3, url: '')),
        throwsFormatException,
      );
    });
  });

  group('ContentBundleService', () {
    test('uses a valid cached bundle on cold start', () async {
      final cache = _FakeCache()
        ..bundles[2] = _minimalBundle('n_cached')
        ..version = 2;

      final service = ContentBundleService(cache: cache);
      final active = await service.start();

      expect(active.grammar.single.notionId, 'n_cached');
      expect(service.activeBundle.grammar.single.notionId, 'n_cached');
    });

    test('falls back to bundled content when the cache is empty', () async {
      final service = ContentBundleService(cache: _FakeCache());
      final active = await service.start();

      final bundled = await GrammarContent.load();
      expect(active.grammar, hasLength(bundled.length));
    });

    test('falls back to bundled content when the cache is corrupt', () async {
      final cache = _FakeCache()
        ..bundles[2] = 'not-json{'
        ..version = 2;

      final service = ContentBundleService(cache: cache);
      final active = await service.start();

      final bundled = await GrammarContent.load();
      expect(active.grammar, hasLength(bundled.length));
    });

    test('stages a newer valid bundle without disturbing the active one',
        () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: _minimalBundle('n_new'),
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNotNull);
      expect(service.activeBundle.grammar.single.notionId, 'n_old');
      expect(service.pendingBundle!.grammar.single.notionId, 'n_new');
      expect(cache.version, 2);
      expect(cache.bundles[2], _minimalBundle('n_new'));

      final activated = await service.activatePending();
      expect(activated.grammar.single.notionId, 'n_new');
    });

    test('activates a staged bundle through the app content runtime', () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: _minimalBundle('n_new'),
      );
      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();
      await service.refresh();
      ContentRuntime.install(service);

      await ContentRuntime.activatePending();

      expect(service.activeBundle.grammar.single.notionId, 'n_new');
      expect(GrammarContent.distinctNotionIds(), contains('n_new'));
      ContentRuntime.reset();
    });

    test('does not re-download when the cached version is current', () async {
      final cache = _FakeCache()
        ..bundles[3] = _minimalBundle('n_current')
        ..version = 3;
      final transport = _FakeTransport(
        manifestBody: _manifest(3),
        bundleBody: _minimalBundle('n_unused'),
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(transport.fetchBundleCalls, 0);
      expect(service.pendingBundle, isNull);
    });

    test('bundle download failure leaves the active snapshot untouched', () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: _minimalBundle('n_new'),
        failBundle: true,
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(service.activeBundle.grammar.single.notionId, 'n_old');
      expect(cache.version, 1);
      expect(cache.bundles[2], isNull);
    });

    test('offline fallback leaves the active snapshot untouched', () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1;
      final transport = _FakeTransport(failManifest: true);

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(service.activeBundle.grammar.single.notionId, 'n_old');
      expect(cache.version, 1);
      expect(cache.bundles[2], isNull);
    });

    test('rejects a malformed bundle without touching the cache', () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: '{not json',
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(cache.version, 1);
      expect(cache.bundles[2], isNull);
      expect(service.pendingBundle, isNull);
    });

    test('rejects an incompatible bundle schema', () async {
      final cache = _FakeCache();
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: jsonEncode({'schemaVersion': 99, 'grammar': []}),
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(cache.version, isNull);
      expect(cache.bundles[2], isNull);
    });

    test('rejects an invalid manifest', () async {
      final cache = _FakeCache();
      final transport = _FakeTransport(manifestBody: '{bad');

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(cache.version, isNull);
    });

    test('failed bundle write leaves the cache untouched', () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1
        ..failWriteBundle = true;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: _minimalBundle('n_new'),
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      expect(cache.version, 1);
      expect(cache.bundles[2], isNull);
      expect(service.pendingBundle, isNull);
    });

    test('atomic replacement keeps the previous version on a partial write',
        () async {
      final cache = _FakeCache()
        ..bundles[1] = _minimalBundle('n_old')
        ..version = 1
        ..failWriteVersion = true;
      final transport = _FakeTransport(
        manifestBody: _manifest(2),
        bundleBody: _minimalBundle('n_new'),
      );

      final service = ContentBundleService(cache: cache, transport: transport);
      await service.start();

      final pending = await service.refresh();

      expect(pending, isNull);
      // The versioned bundle may have been written, but the version pointer was
      // not committed, so a reader still sees the previous version.
      expect(cache.version, 1);
      final read = await cache.read();
      expect(read!.version, 1);
      expect(read.bundle, _minimalBundle('n_old'));
    });
  });
}

final class _FakeTransport implements ContentTransport {
  _FakeTransport({
    this.manifestBody,
    this.bundleBody,
    this.failManifest = false,
    this.failBundle = false,
  });

  final String? manifestBody;
  final String? bundleBody;
  final bool failManifest;
  final bool failBundle;
  int fetchManifestCalls = 0;
  int fetchBundleCalls = 0;

  @override
  Future<String> fetchManifest() async {
    fetchManifestCalls++;
    if (failManifest) throw Exception('offline');
    return manifestBody ?? '';
  }

  @override
  Future<String> fetchBundle(String url) async {
    fetchBundleCalls++;
    if (failBundle) throw Exception('offline');
    return bundleBody ?? '';
  }
}

final class _FakeCache implements ContentCache {
  final Map<int, String> bundles = {};
  int? version;
  bool failWriteBundle = false;
  bool failWriteVersion = false;

  @override
  Future<CachedContent?> read() async {
    final current = version;
    if (current == null) return null;
    final bundle = bundles[current];
    if (bundle == null) return null;
    return CachedContent(version: current, bundle: bundle);
  }

  @override
  Future<void> write(CachedContent content) async {
    if (failWriteBundle) throw Exception('write bundle failed');
    bundles[content.version] = content.bundle;
    if (failWriteVersion) throw Exception('write version failed');
    version = content.version;
  }
}
