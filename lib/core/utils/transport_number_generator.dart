class TransportNumberGenerator {
  TransportNumberGenerator._();

  /// Order numbers are now generated server-side.
  /// This method is kept for compatibility only.
  static Future<String> generate() async {
    return '';
  }
}
