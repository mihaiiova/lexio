import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only scheduling. Store APIs intentionally reveal neither display nor
/// submission, so the cooldown tracks requests, never successful reviews.
class AppReviewService {
  AppReviewService({
    Future<SharedPreferences> Function()? preferences,
    DateTime Function()? now,
    Future<bool> Function()? isAvailable,
    Future<void> Function()? requestReview,
    Future<void> Function()? openStoreListing,
    bool? supported,
    String appStoreId = const String.fromEnvironment('APP_STORE_ID'),
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now,
       _isAvailable = isAvailable ?? InAppReview.instance.isAvailable,
       _requestReview = requestReview ?? InAppReview.instance.requestReview,
       _openStoreListing =
           openStoreListing ??
           (() =>
               InAppReview.instance.openStoreListing(appStoreId: appStoreId)),
       _supported =
           supported ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.iOS)),
       canOpenStore =
           (supported ??
               (!kIsWeb &&
                   (defaultTargetPlatform == TargetPlatform.android ||
                       defaultTargetPlatform == TargetPlatform.iOS))) &&
           (defaultTargetPlatform != TargetPlatform.iOS ||
               RegExp(r'^\d+$').hasMatch(appStoreId));

  static final instance = AppReviewService();
  static const _firstUseKey = 'app_review_first_use';
  static const _roundsKey = 'app_review_completed_rounds';
  static const _lastRequestKey = 'app_review_last_request';
  static const minimumRounds = 5;
  static const minimumAge = Duration(days: 7);
  static const cooldown = Duration(days: 120);

  final Future<SharedPreferences> Function() _preferences;
  final DateTime Function() _now;
  final Future<bool> Function() _isAvailable;
  final Future<void> Function() _requestReview;
  final Future<void> Function() _openStoreListing;
  final bool _supported;
  final bool canOpenStore;
  bool _busy = false;

  Future<void> initialize() async {
    if (!_supported) return;
    try {
      final prefs = await _preferences();
      if (!prefs.containsKey(_firstUseKey)) {
        await prefs.setInt(_firstUseKey, _now().millisecondsSinceEpoch);
      }
    } catch (_) {
      // Reviews must never affect offline play or startup.
    }
  }

  Future<void> onRoundCompleted({required bool Function() canPrompt}) async {
    if (!_supported || _busy) return;
    _busy = true;
    try {
      await initialize();
      final prefs = await _preferences();
      final now = _now();
      final rounds = (prefs.getInt(_roundsKey) ?? 0) + 1;
      if (!await prefs.setInt(_roundsKey, rounds)) return;
      final firstUse = prefs.getInt(_firstUseKey);
      final lastRequest = prefs.getInt(_lastRequestKey);
      if (firstUse == null ||
          rounds < minimumRounds ||
          now.difference(DateTime.fromMillisecondsSinceEpoch(firstUse)) <
              minimumAge ||
          (lastRequest != null &&
              now.difference(DateTime.fromMillisecondsSinceEpoch(lastRequest)) <
                  cooldown)) {
        return;
      }
      if (!await _isAvailable() || !canPrompt()) return;
      // Persist before calling the API, including when the OS suppresses it.
      if (!await prefs.setInt(_lastRequestKey, now.millisecondsSinceEpoch)) {
        return;
      }
      if (!canPrompt()) return;
      await _requestReview();
    } catch (_) {
      // Missing stores, platform errors and storage failures are non-fatal.
    } finally {
      _busy = false;
    }
  }

  Future<bool> openStore() async {
    if (!canOpenStore) return false;
    try {
      await _openStoreListing();
      return true;
    } catch (_) {
      return false;
    }
  }
}
