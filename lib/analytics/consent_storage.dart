import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persisted consent settings for the installation-linked analytics collector.
///
/// Default is off. A failed or unknown read resolves to [ConsentState.disabled]
/// so collection never turns on by accident.
final class ConsentState {
  const ConsentState({
    this.enabled = false,
    this.installationId,
    this.deletionSecret,
    this.needsDeletion = false,
  });

  static const ConsentState disabled = ConsentState();

  final bool enabled;
  final String? installationId;
  final String? deletionSecret;

  /// An explicit deletion request is pending; ordinary opt-out keeps this off.
  final bool needsDeletion;

  bool get hasIdentity =>
      installationId != null &&
      installationId!.isNotEmpty &&
      deletionSecret != null &&
      deletionSecret!.isNotEmpty;

  ConsentState copyWith({
    bool? enabled,
    String? installationId,
    String? deletionSecret,
    bool? needsDeletion,
  }) {
    return ConsentState(
      enabled: enabled ?? this.enabled,
      installationId: installationId ?? this.installationId,
      deletionSecret: deletionSecret ?? this.deletionSecret,
      needsDeletion: needsDeletion ?? this.needsDeletion,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'installationId': installationId,
    'deletionSecret': deletionSecret,
    'needsDeletion': needsDeletion,
  };

  factory ConsentState.fromJson(Map<String, dynamic> json) {
    return ConsentState(
      enabled: json['enabled'] as bool? ?? false,
      installationId: json['installationId'] as String?,
      deletionSecret: json['deletionSecret'] as String?,
      needsDeletion: json['needsDeletion'] as bool? ?? false,
    );
  }
}

abstract class ConsentStorage {
  Future<String?> read();
  Future<void> write(String value);
}

final class SharedPreferencesConsentStorage implements ConsentStorage {
  SharedPreferencesConsentStorage(
    this._key, [
    SharedPreferencesAsync? preferences,
  ]) : _preferences = preferences ?? SharedPreferencesAsync();

  final String _key;
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);
}

/// Encodes a [ConsentState] for persistence.
String encodeConsentState(ConsentState state) => jsonEncode(state.toJson());
