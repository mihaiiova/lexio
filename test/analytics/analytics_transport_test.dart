import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_event.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/analytics/analytics_transport.dart';

void main() {
  group('HttpAnalyticsTransport', () {
    test('reports unavailable delivery when endpoint is unset', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final transport = HttpAnalyticsTransport(client: client);
      await expectLater(transport.sendEvents([_event()]), throwsStateError);
      await expectLater(
        transport.requestDeletion(
          installationId: 'inst_1',
          deletionSecret: 'secret',
        ),
        throwsStateError,
      );

      expect(called, isFalse);
    });

    test('posts event batches to the events endpoint', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });

      final transport = HttpAnalyticsTransport(
        baseUrl: 'https://analytics.example',
        client: client,
      );
      await transport.sendEvents([_event()]);

      expect(captured.method, 'POST');
      expect(captured.url.toString(), 'https://analytics.example/v1/events');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final events = body['events'] as List<dynamic>;
      expect(events, hasLength(1));
      expect((events.single as Map<String, dynamic>)['kind'], 'round_started');
    });

    test('rejects a non-success event response', () async {
      final client = MockClient((request) async => http.Response('{}', 400));
      final transport = HttpAnalyticsTransport(
        baseUrl: 'https://analytics.example',
        client: client,
      );

      expect(transport.sendEvents([_event()]), throwsException);
    });

    test('includes the deletion secret for first registration', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{"ok":true}', 202);
      });

      final transport = HttpAnalyticsTransport(
        baseUrl: 'https://analytics.example',
        client: client,
      );
      await transport.sendEvents([_event()], deletionSecret: 'secret_1');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['deletionSecret'], 'secret_1');
      expect(body['events'], hasLength(1));
    });

    test('posts an authenticated deletion request', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{"deleted":true}', 200);
      });

      final transport = HttpAnalyticsTransport(
        baseUrl: 'https://analytics.example',
        client: client,
      );
      await transport.requestDeletion(
        installationId: 'inst_1',
        deletionSecret: 'secret_1',
      );

      expect(captured.url.toString(), 'https://analytics.example/v1/delete');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['installationId'], 'inst_1');
      expect(body['deletionSecret'], 'secret_1');
    });
  });
}

AnalyticsEvent _event() {
  return AnalyticsEvent(
    eventId: 'ev_1',
    sessionId: 's_1',
    installationId: 'inst_1',
    gameId: 'grammar',
    contentVersion: 'bundled',
    timestampUtc: DateTime.utc(2026),
    kind: AnalyticsEventKind.roundStarted,
  );
}
