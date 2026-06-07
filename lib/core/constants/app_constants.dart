class AppConstants {
  AppConstants._();

  static const String appName = 'Qui Go au Bled';
  static const String appVersion = '1.0.0';

  // API Backend (Railway)
  // En développement : http://10.0.2.2:3000/api (Android emulator) ou http://localhost:3000/api (web)
  // En production : mettre l'URL Railway ici
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // Transport order number format
  static const String orderPrefix = 'TRP';

  // Pagination
  static const int pageSize = 20;

  // Max file sizes
  static const int maxImageSizeMb = 5;
  static const int maxWeightKg = 50;
  static const double minPricePerKg = 1.0;
  static const double maxPricePerKg = 100.0;

  // Review bounds
  static const int minRating = 1;
  static const int maxRating = 5;

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // WhatsApp deep link base
  static const String whatsappScheme = 'https://wa.me/?text=';
}
