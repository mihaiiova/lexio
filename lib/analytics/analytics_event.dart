/// Versioned, bounded analytics event payloads.
///
/// Events carry only stable identifiers and bounded outcomes — never raw
/// content, exercise sentences, or free-form answers. The wire shape is
/// validated before serialization so a malformed event is rejected locally
/// rather than sent to the ingestion endpoint.
enum AnalyticsEventKind {
  roundStarted('round_started'),
  itemShown('item_shown'),
  itemAnswered('item_answered'),
  itemResolved('item_resolved'),
  roundEnded('round_ended');

  const AnalyticsEventKind(this.wireName);

  final String wireName;

  static AnalyticsEventKind? fromWireName(String value) {
    for (final kind in values) {
      if (kind.wireName == value) return kind;
    }
    return null;
  }
}

enum AnalyticsOutcome {
  correct('correct'),
  wrong('wrong');

  const AnalyticsOutcome(this.wireName);

  final String wireName;
}

enum AnalyticsRoundEndReason {
  completed('completed'),
  userBack('user_back'),
  restart('restart'),
  inferredInterruption('inferred_interruption');

  const AnalyticsRoundEndReason(this.wireName);

  final String wireName;
}

enum AnalyticsItemState { unresolved, resolved }

final class AnalyticsEvent {
  static const int schemaVersion = 1;
  static const int maxIdLength = 128;
  static const int maxGameIdLength = 64;
  static const int maxContentVersionLength = 64;

  const AnalyticsEvent({
    required this.eventId,
    required this.sessionId,
    required this.installationId,
    required this.gameId,
    required this.contentVersion,
    required this.timestampUtc,
    required this.kind,
    this.itemId,
    this.itemIndex,
    this.outcome,
    this.reason,
    this.itemState,
  });

  final String eventId;
  final String sessionId;
  final String installationId;
  final String gameId;
  final String contentVersion;
  final String? itemId;
  final int? itemIndex;
  final DateTime timestampUtc;
  final AnalyticsEventKind kind;
  final AnalyticsOutcome? outcome;
  final AnalyticsRoundEndReason? reason;
  final AnalyticsItemState? itemState;

  void validate() {
    _requireBounded(eventId, 'eventId', maxIdLength);
    _requireBounded(sessionId, 'sessionId', maxIdLength);
    _requireBounded(installationId, 'installationId', maxIdLength);
    _requireBounded(gameId, 'gameId', maxGameIdLength);
    _requireBounded(contentVersion, 'contentVersion', maxContentVersionLength);

    if (itemId != null) {
      _requireBounded(itemId!, 'itemId', maxIdLength);
    }
    if (itemIndex != null && itemIndex! < 0) {
      throw const FormatException('itemIndex must be non-negative');
    }

    if (kind != AnalyticsEventKind.roundEnded && itemState != null) {
      throw const FormatException('itemState is only valid on round_ended');
    }
    switch (kind) {
      case AnalyticsEventKind.roundStarted:
        if (outcome != null ||
            reason != null ||
            itemId != null ||
            itemIndex != null) {
          throw const FormatException(
            'round_started must not carry item or outcome fields',
          );
        }
      case AnalyticsEventKind.itemShown:
      case AnalyticsEventKind.itemResolved:
        if (itemId == null ||
            itemIndex == null ||
            outcome != null ||
            reason != null) {
          throw const FormatException(
            'item_shown requires itemId and itemIndex only',
          );
        }
      case AnalyticsEventKind.itemAnswered:
        if (itemId == null ||
            itemIndex == null ||
            outcome == null ||
            reason != null) {
          throw const FormatException(
            'item_answered requires itemId, itemIndex and outcome',
          );
        }
      case AnalyticsEventKind.roundEnded:
        if (reason == null || outcome != null ||
            (itemId == null) != (itemIndex == null) ||
            (itemId == null) != (itemState == null)) {
          throw const FormatException(
            'round_ended requires a reason and no outcome',
          );
        }
    }
  }

  Map<String, dynamic> toJson() {
    validate();
    return {
      'v': schemaVersion,
      'eventId': eventId,
      'sessionId': sessionId,
      'installationId': installationId,
      'gameId': gameId,
      'contentVersion': contentVersion,
      'itemId': itemId,
      'itemIndex': itemIndex,
      'timestampUtc': timestampUtc.toUtc().toIso8601String(),
      'kind': kind.wireName,
      'outcome': outcome?.wireName,
      'reason': reason?.wireName,
      'itemState': itemState?.name,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    if (json['v'] != schemaVersion) throw const FormatException('event version');
    final event = AnalyticsEvent(
      eventId: json['eventId'] as String,
      sessionId: json['sessionId'] as String,
      installationId: json['installationId'] as String,
      gameId: json['gameId'] as String,
      contentVersion: json['contentVersion'] as String,
      timestampUtc: DateTime.parse(json['timestampUtc'] as String).toUtc(),
      kind: AnalyticsEventKind.fromWireName(json['kind'] as String)!,
      itemId: json['itemId'] as String?, itemIndex: json['itemIndex'] as int?,
      outcome: json['outcome'] == null ? null : AnalyticsOutcome.values.firstWhere(
        (value) => value.wireName == json['outcome']),
      reason: json['reason'] == null ? null : AnalyticsRoundEndReason.values.firstWhere(
        (value) => value.wireName == json['reason']),
      itemState: json['itemState'] == null ? null : AnalyticsItemState.values.byName(json['itemState'] as String),
    );
    event.validate();
    return event;
  }

  static void _requireBounded(String value, String name, int maxLength) {
    if (value.isEmpty) {
      throw FormatException('$name must not be empty');
    }
    if (value.length > maxLength) {
      throw FormatException('$name exceeds $maxLength characters');
    }
  }
}
