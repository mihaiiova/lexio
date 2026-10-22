import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'analytics_event.dart';

/// Sends bounded event batches and authenticated deletion requests.
abstract class AnalyticsTransport {
  Future<void> sendEvents(List<AnalyticsEvent> events, {String? deletionSecret});

  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  });
}

/// Production transport backed by the already-present `http` package.
///
/// The endpoint comes from `String.fromEnvironment('ANALYTICS_ENDPOINT')`.
/// When it is unset, both operations no-op so the app stays safe offline and
/// in development without any network traffic.
final class HttpAnalyticsTransport implements AnalyticsTransport {
  HttpAnalyticsTransport({
    String? baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _baseUrl = baseUrl ?? const String.fromEnvironment('ANALYTICS_ENDPOINT'),
       _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<void> sendEvents(List<AnalyticsEvent> events, {String? deletionSecret}) async {
    if (_baseUrl.isEmpty) {
      debugPrint(
        'AnalyticsTransport: ANALYTICS_ENDPOINT is unset; events are not sent.',
      );
      return;
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/events'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'deletionSecret': ?deletionSecret,
            'events': events.map((event) => event.toJson()).toList(),
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('analytics events rejected: ${response.statusCode}');
    }
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {
    if (_baseUrl.isEmpty) {
      debugPrint(
        'AnalyticsTransport: ANALYTICS_ENDPOINT is unset; deletion is a no-op.',
      );
      return;
    }

    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/delete'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'installationId': installationId,
            'deletionSecret': deletionSecret,
          }),
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('analytics deletion rejected: ${response.statusCode}');
    }
  }
}
