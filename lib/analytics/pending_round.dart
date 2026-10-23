import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A round that started but has not yet been closed.
///
/// Persisted so an app termination can be reconciled on the next launch as an
/// `inferred_interruption` — we do not claim the kill was observed live.
final class PendingRound {
  const PendingRound({
    required this.sessionId,
    required this.installationId,
    required this.gameId,
    required this.contentVersion,
    required this.startedAtUtc,
    this.lastShownItemId,
    this.lastShownItemIndex,
    this.itemResolved = false,
  });

  final String sessionId;
  final String installationId;
  final String gameId;
  final String contentVersion;
  final DateTime startedAtUtc;
  final String? lastShownItemId;
  final int? lastShownItemIndex;
  final bool itemResolved;

  PendingRound copyWith({
    String? lastShownItemId,
    int? lastShownItemIndex,
    bool? itemResolved,
  }) {
    return PendingRound(
      sessionId: sessionId,
      installationId: installationId,
      gameId: gameId,
      contentVersion: contentVersion,
      startedAtUtc: startedAtUtc,
      lastShownItemId: lastShownItemId ?? this.lastShownItemId,
      lastShownItemIndex: lastShownItemIndex ?? this.lastShownItemIndex,
      itemResolved: itemResolved ?? this.itemResolved,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'installationId': installationId,
    'gameId': gameId,
    'contentVersion': contentVersion,
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'lastShownItemId': lastShownItemId,
    'lastShownItemIndex': lastShownItemIndex,
    'itemResolved': itemResolved,
  };

  factory PendingRound.fromJson(Map<String, dynamic> json) {
    return PendingRound(
      sessionId: json['sessionId'] as String,
      installationId: json['installationId'] as String,
      gameId: json['gameId'] as String,
      contentVersion: json['contentVersion'] as String,
      startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
      lastShownItemId: json['lastShownItemId'] as String?,
      lastShownItemIndex: json['lastShownItemIndex'] as int?,
      itemResolved: json['itemResolved'] as bool? ?? false,
    );
  }
}

abstract class PendingRoundStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

final class SharedPreferencesPendingRoundStorage
    implements PendingRoundStorage {
  SharedPreferencesPendingRoundStorage(
    this._key, [
    SharedPreferencesAsync? preferences,
  ]) : _preferences = preferences ?? SharedPreferencesAsync();

  final String _key;
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);

  @override
  Future<void> clear() => _preferences.remove(_key);
}

/// Encodes a [PendingRound] for persistence.
String encodePendingRound(PendingRound round) => jsonEncode(round.toJson());
