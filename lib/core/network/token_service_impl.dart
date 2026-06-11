import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Unified TokenService — works on ALL platforms (web, Android, iOS, desktop).
///
/// On web : flutter_secure_storage_web stores under localStorage with key
///           "FlutterSecureStorage.auth_token". clearToken() calls deleteAll()
///           to guarantee full cleanup (removes both the token and the
///           encryption key so no stale entry remains after logout).
/// On native: flutter_secure_storage uses the platform keychain/keystore.
class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  static Future<String?> getToken() => _storage.read(key: _key);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);

  /// Clears the auth token.
  /// Uses deleteAll() to reliably remove all secure storage entries,
  /// ensuring no stale token remains in localStorage on web.
  static Future<void> clearToken() => _storage.deleteAll();
}
