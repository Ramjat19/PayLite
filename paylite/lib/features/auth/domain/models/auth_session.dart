import 'package:paylite/core/utils/json_readers.dart';

/// Device-bound credentials returned after a successful login.
///
/// The token is intentionally only a model value. Persisting it securely is
/// the responsibility of the secure-session store introduced in a later phase.
class AuthSession {
  const AuthSession({required this.token, required this.deviceId});

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      token: readRequiredString(json, 'token'),
      deviceId: readRequiredString(json, 'deviceId'),
    );
  }

  final String token;
  final String deviceId;

  Map<String, Object?> toJson() => <String, Object?>{
    'token': token,
    'deviceId': deviceId,
  };

  @override
  bool operator ==(Object other) {
    return other is AuthSession &&
        other.token == token &&
        other.deviceId == deviceId;
  }

  @override
  int get hashCode => Object.hash(token, deviceId);
}
