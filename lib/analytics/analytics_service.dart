import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';

sealed class AnalyticsService {
  AnalyticsService._();

  static const _consentKey = 'analytics_consent_v1';

  static FirebaseAnalytics? _analytics;
  static bool? _consent;

  /// `null` = no decision yet, `true` = granted, `false` = declined.
  static bool? get consent => _consent;

  @visibleForTesting
  static void resetForTesting() {
    _analytics = null;
    _consent = null;
  }

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _analytics = FirebaseAnalytics.instance;
    } catch (error) {
      debugPrint('AnalyticsService: Firebase unavailable: $error');
      return;
    }

    // Start private; collection is enabled only after explicit consent.
    await _applyConsent(false);

    try {
      final preferences = SharedPreferencesAsync();
      final stored = await preferences.getBool(_consentKey);
      if (stored != null) {
        _consent = stored;
        await _applyConsent(stored);
      }
    } catch (error) {
      debugPrint('AnalyticsService: failed to read consent: $error');
    }
  }

  static Future<void> setConsent(bool granted) async {
    _consent = granted;
    try {
      final preferences = SharedPreferencesAsync();
      await preferences.setBool(_consentKey, granted);
    } catch (error) {
      debugPrint('AnalyticsService: failed to persist consent: $error');
    }
    await _applyConsent(granted);
  }

  static Future<void> _applyConsent(bool granted) async {
    try {
      await _analytics?.setConsent(
        adStorageConsentGranted: false,
        analyticsStorageConsentGranted: granted,
        adPersonalizationSignalsConsentGranted: false,
        adUserDataConsentGranted: false,
      );
      await _analytics?.setAnalyticsCollectionEnabled(granted);
    } catch (error) {
      debugPrint('AnalyticsService: failed to apply consent: $error');
    }
  }

  static Future<void> logGameOpened(String gameId) async {
    if (_consent != true) return;
    try {
      await _analytics?.logEvent(
        name: 'game_opened',
        parameters: {'game_id': gameId},
      );
    } catch (error) {
      debugPrint('AnalyticsService: failed to log game_opened: $error');
    }
  }
}
