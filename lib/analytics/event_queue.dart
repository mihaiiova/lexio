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

  void clear() => _events.clear();
}
