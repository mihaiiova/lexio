import 'dart:async';

import 'package:lexio/analytics/analytics_event.dart';
import 'package:lexio/analytics/analytics_repository.dart';
import 'package:lexio/analytics/analytics_transport.dart';
import 'package:lexio/analytics/consent_storage.dart';
import 'package:lexio/analytics/pending_round.dart';

class MemoryAnalyticsStorage implements ConsentStorage {
  String? value;
  Completer<void>? writeGate;
  final snapshots = <String>[];
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    await writeGate?.future;
    this.value = value;
    snapshots.add(value);
  }
}

class MemoryRoundStorage implements PendingRoundStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

class RecordingAnalyticsTransport implements AnalyticsTransport {
  final events = <AnalyticsEvent>[];
  bool offline = false;
  @override
  Future<void> sendEvents(
    List<AnalyticsEvent> events, {
    String? deletionSecret,
  }) async {
    if (offline) throw StateError('offline');
    this.events.addAll(events);
  }

  @override
  Future<void> requestDeletion({
    required String installationId,
    required String deletionSecret,
  }) async {}
}

Future<AnalyticsRepository> analyticsRepository(
  RecordingAnalyticsTransport transport, {
  bool enabled = true,
  MemoryAnalyticsStorage? storage,
  MemoryAnalyticsStorage? queue,
  DateTime Function()? clock,
}) async {
  final repo = await AnalyticsRepository.load(
    storage: storage ?? MemoryAnalyticsStorage(),
    queueStorage: queue ?? MemoryAnalyticsStorage(),
    pendingRoundStorage: MemoryRoundStorage(),
    transport: transport,
    clock: clock,
  );
  if (enabled) await repo.enable();
  return repo;
}
