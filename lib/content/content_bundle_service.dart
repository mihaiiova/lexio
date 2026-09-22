import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'content_bundle.dart';

/// A parsed, versioned manifest that points at a remote content bundle.
final class ContentManifest {
  const ContentManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.bundleUrl,
  });

  final int schemaVersion;
  final int contentVersion;
  final String bundleUrl;

  factory ContentManifest.fromString(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('manifest must be a JSON object');
    }
    final schemaVersion = decoded['schemaVersion'] as int? ?? -1;
    final contentVersion = decoded['contentVersion'] as int? ?? -1;
    final bundleUrl = decoded['bundleUrl'] as String? ?? '';
    if (schemaVersion != ContentBundle.supportedSchemaVersion) {
      throw const FormatException('unsupported manifest schema version');
    }
    if (contentVersion <= 0) {
      throw const FormatException('manifest contentVersion must be positive');
    }
    if (bundleUrl.isEmpty) {
      throw const FormatException('manifest bundleUrl must not be empty');
    }
    return ContentManifest(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      bundleUrl: bundleUrl,
    );
  }
}

/// Fetches raw manifest and bundle bytes over the network.
abstract class ContentTransport {
  Future<String> fetchManifest();
  Future<String> fetchBundle(String url);
}

/// Persists the last validated bundle and the version it belongs to.
///
/// Implementations must replace both atomically from the reader's point of
/// view: a read observes either the previous version or the new version, never
/// a half-written pair.
abstract class ContentCache {
  Future<CachedContent?> read();
  Future<void> write(CachedContent content);
}

final class CachedContent {
  const CachedContent({required this.version, required this.bundle});

  final int version;
  final String bundle;
}

final class SharedPreferencesContentCache implements ContentCache {
  SharedPreferencesContentCache([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _versionKey = 'content_bundle_version';

  final SharedPreferencesAsync _preferences;

  @override
  Future<CachedContent?> read() async {
    final version = await _preferences.getInt(_versionKey);
    if (version == null) return null;
    final bundle = await _preferences.getString(_bundleKey(version));
    if (bundle == null) return null;
    return CachedContent(version: version, bundle: bundle);
  }

  @override
  Future<void> write(CachedContent content) async {
    // Write the immutable versioned bundle first; the version pointer is the
    // commit point, so a crash between the two leaves the previous bundle
    // active.
    await _preferences.setString(
      _bundleKey(content.version),
      content.bundle,
    );
    await _preferences.setInt(_versionKey, content.version);
  }

  String _bundleKey(int version) => 'content_bundle_v$version';
}

final class HttpContentTransport implements ContentTransport {
  HttpContentTransport(this._manifestUrl, {http.Client? client})
    : _client = client ?? http.Client();

  final String _manifestUrl;
  final http.Client _client;

  @override
  Future<String> fetchManifest() => _getBody(_manifestUrl);

  @override
  Future<String> fetchBundle(String url) => _getBody(url);

  Future<String> _getBody(String url) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('content fetch failed with ${response.statusCode}');
    }
    return response.body;
  }
}

/// Owns cold-start content resolution and one background manifest check.
///
/// - `start()` resolves the active snapshot (valid cache first, bundled
///   fallback) and applies it. Callers then trigger a single background
///   `refresh()` to check the manifest.
/// - `refresh()` downloads and validates a newer bundle and stages it as
///   `pendingBundle` without disturbing the active snapshot.
/// - `activatePending()` swaps the staged bundle in before the next round.
final class ContentBundleService {
  ContentBundleService({required this.cache, this.transport});

  final ContentCache cache;
  final ContentTransport? transport;

  ContentBundle? _active;
  ContentBundle? _pending;

  ContentBundle get activeBundle => _active!;
  ContentBundle? get pendingBundle => _pending;

  Future<ContentBundle> start() async {
    _active = await _loadCachedOrBundled();
    _active!.apply();
    return _active!;
  }

  Future<ContentBundle?> refresh() async {
    final transport = this.transport;
    if (transport == null) return null;
    try {
      final manifest = ContentManifest.fromString(
        await transport.fetchManifest(),
      );
      final cached = await cache.read();
      if (cached != null && manifest.contentVersion <= cached.version) {
        return null;
      }

      final bundleRaw = await transport.fetchBundle(manifest.bundleUrl);
      // Parsing validates schema and content before anything is written.
      final bundle = ContentBundle.fromString(bundleRaw);
      await cache.write(
        CachedContent(
          version: manifest.contentVersion,
          bundle: bundleRaw,
        ),
      );
      _pending = bundle;
      return bundle;
    } catch (_) {
      // Failed, malformed, or incompatible update: leave the active snapshot
      // and any previous cache untouched.
      return null;
    }
  }

  Future<ContentBundle> activatePending() async {
    final pending = _pending;
    if (pending != null) {
      _active = pending;
      _pending = null;
      pending.apply();
    }
    return _active!;
  }

  Future<ContentBundle> _loadCachedOrBundled() async {
    try {
      final cached = await cache.read();
      if (cached != null) {
        return ContentBundle.fromString(cached.bundle);
      }
    } catch (_) {
      // Corrupt cache: fall through to bundled content.
    }
    return ContentBundle.loadBundled();
  }
}
