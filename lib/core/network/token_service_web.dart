// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Token storage for web platform using window.localStorage directly.
/// This bypasses flutter_secure_storage_web which may fail to properly
/// delete entries, causing stale tokens to persist after logout.
class TokenService {
  static const _key = 'auth_token';
  // Ancien format flutter_secure_storage_web (migration backward-compat)
  static const _legacyKey = 'FlutterSecureStorage.$_key';
  static const _legacyMasterKey = 'FlutterSecureStorage';

  /// Retourne le token : lit d'abord la clé courante, sinon l'ancienne.
  /// Note : l'ancien token est chiffré → on ne peut pas le réutiliser,
  /// donc si seule l'ancienne clé est présente on retourne null
  /// (l'utilisateur devra se reconnecter).
  static Future<String?> getToken() async =>
      html.window.localStorage[_key];

  static Future<void> saveToken(String token) async =>
      html.window.localStorage[_key] = token;

  /// Supprime le token courant ET les anciennes clés flutter_secure_storage
  /// pour garantir une déconnexion propre quelle que soit la version de l'app.
  static Future<void> clearToken() async {
    html.window.localStorage.remove(_key);
    html.window.localStorage.remove(_legacyKey);
    html.window.localStorage.remove(_legacyMasterKey);
  }
}
