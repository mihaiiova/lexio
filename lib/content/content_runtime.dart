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

  static void reset() {
    _service = null;
  }
}
