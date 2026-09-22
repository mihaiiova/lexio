import 'dart:async';

import 'package:flutter/material.dart';

import 'analytics/analytics_service.dart';
import 'app/app.dart';
import 'content/content_bundle_service.dart';

/// Compile-time base URL for static content. Empty in development and tests,
/// where the app serves bundled content and never checks the manifest.
const _contentBaseUrl = String.fromEnvironment('CONTENT_BASE_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.initialize();
  await _startContentBundleService();
  runApp(const LexioApp());
}

Future<void> _startContentBundleService() async {
  try {
    final service = ContentBundleService(
      cache: SharedPreferencesContentCache(),
      transport: _contentBaseUrl.isEmpty
          ? null
          : HttpContentTransport('$_contentBaseUrl/manifest.json'),
    );
    // Resolve the active snapshot (valid cache first, bundled fallback) and
    // apply it before the first frame.
    await service.start();
    // One background manifest check; a newer bundle is staged, not applied,
    // until the next round boundary.
    unawaited(service.refresh());
  } catch (_) {
    // If content resolution fails, screens still load bundled assets lazily.
  }
}
