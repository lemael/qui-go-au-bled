// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Token storage for web platform using window.localStorage directly.
/// This bypasses flutter_secure_storage_web which may fail to properly
/// delete entries, causing stale tokens to persist after logout.
class TokenService {
  static const _key = 'auth_token';

  static Future<String?> getToken() async =>
      html.window.localStorage[_key];

  static Future<void> saveToken(String token) async =>
      html.window.localStorage[_key] = token;

  static Future<void> clearToken() async =>
      html.window.localStorage.remove(_key);
}
