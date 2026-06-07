class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String search = '/search';
  static const String adList = '/ads';
  static const String adDetail = '/ads/:adId';
  static const String createAd = '/ads/create';
  static const String myAds = '/my-ads';
  static const String transporterProfile = '/transporter/:userId';
  static const String myRequests = '/my-requests';
  static const String requestDetail = '/my-requests/:requestId';
  static const String myTransports = '/my-transports';
  static const String orderDetail = '/my-transports/:orderId';
  static const String cancelOrder = '/my-transports/:orderId/cancel';
  static const String dashboard = '/dashboard';
  static const String reviews = '/reviews/:transporterId';
  static const String createReview = '/review/create/:orderId';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String resetPassword = '/reset-password';
  static const String admin = '/admin';
}
