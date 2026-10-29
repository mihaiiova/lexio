import 'dart:convert';

import 'analytics_event.dart';

/// A bounded, deduplicating in-memory buffer for unsent events.
///
/// Adding is nonblocking and never throws. The queue is FIFO and drops the
/// oldest event once it reaches [maxSize] so a runaway round cannot grow
/// memory without bound.
final class AnalyticsEventQueue {
  AnalyticsEventQueue({this.maxSize = 1000}) : assert(maxSize > 0);

  final int maxSize;
  final List<AnalyticsEvent> _events = [];

  int get length => _events.length;

  bool get isEmpty => _events.isEmpty;

  /// Adds [event] unless an event with the same id is already queued.
  ///
  /// Returns false for duplicates.
  bool add(AnalyticsEvent event) {
    if (_events.any((existing) => existing.eventId == event.eventId)) {
      return false;
    }
    if (_events.length >= maxSize) {
      _events.removeAt(0);
    }
    _events.add(event);
    return true;
  }

  /// Removes and returns every queued event, oldest first.
  List<AnalyticsEvent> drain() {
    final snapshot = List<AnalyticsEvent>.from(_events);
    _events.clear();
    return snapshot;
  }

  List<AnalyticsEvent> get events => List.unmodifiable(_events);

  /// Leaves retryable events in place until acknowledgment, at most 100 per request.
  List<AnalyticsEvent> batch() {
    final batch = <AnalyticsEvent>[];
    var bytes = 256; // Envelope and deletion credential overhead.
    for (final event in _events.take(100)) {
      final size = utf8.encode(jsonEncode(event.toJson())).length + 1;
      if (bytes + size > 60000) break;
      bytes += size;
      batch.add(event);
    }
    return batch;
  }

  void acknowledge(List<AnalyticsEvent> batch) {
    final ids = batch.map((event) => event.eventId).toSet();
    _events.removeWhere((event) => ids.contains(event.eventId));
  }

  void clear() => _events.clear();
}
