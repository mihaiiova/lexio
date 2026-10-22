import 'content_bundle_service.dart';

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
  /// Returns `bundled` when no remote content service is installed or when
  /// the bundled assets are the active snapshot.
  static String get activeContentVersion =>
      _service?.activeContentVersion ?? 'bundled';

  static void reset() {
    _service = null;
  }
}
