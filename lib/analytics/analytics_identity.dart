import 'dart:convert';
import 'dart:math';

/// Pseudonymous installation identity plus a separate deletion secret.
///
/// The installation id is not a credential; deletion requests are authorized
/// by the deletion secret and are server-verified. Both tokens are random and
/// are created only when the user enables analytics.
final class AnalyticsIdentity {
  const AnalyticsIdentity({
    required this.installationId,
    required this.deletionSecret,
  });

  final String installationId;
  final String deletionSecret;

  static AnalyticsIdentity generate({Random? random}) {
    final rng = random ?? Random.secure();
    return AnalyticsIdentity(
      installationId: _randomToken(rng),
      deletionSecret: _randomToken(rng),
    );
  }
}

String _randomToken(Random rng) {
  final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
