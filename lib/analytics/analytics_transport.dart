import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'analytics_event.dart';

/// Sends bounded event batches and authenticated deletion requests.
abstract class AnalyticsTransport {
  /// Configuration only; this does not imply that the server is reachable.
  bool get isConfigured;

  Future<void> sendEvents(
    List<AnalyticsEvent> events, {
    String? deletionSecret,
  });

  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  });
}

/// Production transport backed by the already-present `http` package.
///
/// The endpoint comes from `String.fromEnvironment('ANALYTICS_ENDPOINT')`.
/// An unset endpoint fails delivery so queued events and deletion credentials
/// are retained for a later explicit retry.
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
  bool get isConfigured {
    final endpoint = Uri.tryParse(_baseUrl);
    return endpoint != null &&
        endpoint.scheme == 'https' &&
        endpoint.host.isNotEmpty;
  }

  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> events, {
    String? deletionSecret,
  }) async {
    if (!isConfigured) throw StateError('analytics endpoint unavailable');

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
    if (!isConfigured) throw StateError('analytics endpoint unavailable');

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
