import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  static const _key = 'access_token';
  final _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _key, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _key);

  Future<void> clearAccessToken() =>
      _storage.delete(key: _key);
}   