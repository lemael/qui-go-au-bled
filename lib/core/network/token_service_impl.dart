import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unified TokenService — works on ALL platforms (web, Android, iOS, desktop)
/// without relying on conditional exports that are unreliable in dart2js builds.
///
/// On web : flutter_secure_storage_web stores under localStorage
///           with key "FlutterSecureStorage.auth_token".
/// On native: flutter_secure_storage uses the platform keychain/keystore.
class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  static Future<String?> getToken() => _storage.read(key: _key);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  static Future<void> clearToken() => _storage.delete(key: _key);
}
