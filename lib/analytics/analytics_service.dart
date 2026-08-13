import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

sealed class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final analytics = FirebaseAnalytics.instance;
      await analytics.setConsent(
        adStorageConsentGranted: false,
        analyticsStorageConsentGranted: true,
        adPersonalizationSignalsConsentGranted: false,
        adUserDataConsentGranted: false,
      );
      await analytics.setAnalyticsCollectionEnabled(true);
      _analytics = analytics;
    } catch (error) {
      debugPrint('AnalyticsService: Firebase unavailable: $error');
    }
  }

  static Future<void> logGameOpened(String gameId) async {
    try {
      await _analytics?.logEvent(
        name: 'game_opened',
        parameters: {'game_id': gameId},
      );
    } catch (error) {
      debugPrint('AnalyticsService: failed to log game_opened: $error');
    }
  }

  static Future<void> logGameCompleted(
    String gameId, {
    required int score,
    required int durationSeconds,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'game_completed',
        parameters: {
          'game_id': gameId,
          'score': score,
          'duration_seconds': durationSeconds,
        },
      );
    } catch (error) {
      debugPrint('AnalyticsService: failed to log game_completed: $error');
    }
  }

  static Future<void> logGameAbandoned(String gameId) async {
    try {
      await _analytics?.logEvent(
        name: 'game_abandoned',
        parameters: {'game_id': gameId},
      );
    } catch (error) {
      debugPrint('AnalyticsService: failed to log game_abandoned: $error');
    }
  }
}
