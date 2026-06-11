// Conditional export: uses localStorage on web, flutter_secure_storage on native.
// NOTE: dart.library.html is deprecated in Flutter 3.x; we use dart.library.io
// (available only on native) as a more reliable condition.
export 'token_service_web.dart'
    if (dart.library.io) 'token_service_io.dart';
