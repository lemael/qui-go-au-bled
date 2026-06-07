import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'auth_token';

  static Future<String?> getToken() => _storage.read(key: _key);
  static Future<void> saveToken(String token) => _storage.write(key: _key, value: token);
  static Future<void> clearToken() => _storage.delete(key: _key);
}
