import 'content_bundle_service.dart';
import 'content_version.dart';

/// Coordinates the app-wide content snapshot at round boundaries.
final class ContentRuntime {
  ContentRuntime._();

  static ContentBundleService? _service;

  static void install(ContentBundleService service) {
    _service = service;
  }

  static Future<void> activatePending() async {
    await _service?.activatePending();
  }

  /// Identifies the active content snapshot for analytics attribution.
  ///
  /// Bundled revisions use the same generated manifest version as remote content.
  static String get activeContentVersion =>
      _service?.activeContentVersion ?? bundledContentVersion;

  static void reset() {
    _service = null;
  }
}
