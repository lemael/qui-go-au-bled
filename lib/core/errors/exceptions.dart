class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Erreur de connexion réseau']);
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
  @override
  String toString() => 'NotFoundException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([
    this.message = 'Vous n\'êtes pas autorisé à effectuer cette action',
  ]);
  @override
  String toString() => 'UnauthorizedException: $message';
}
