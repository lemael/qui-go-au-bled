import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/edit_profile_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/profile_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/reviews/presentation/screens/create_review_screen.dart';
import '../features/reviews/presentation/screens/reviews_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/transport_ads/presentation/screens/ad_detail_screen.dart';
import '../features/transport_ads/presentation/screens/ad_list_screen.dart';
import '../features/transport_ads/presentation/screens/create_ad_screen.dart';
import '../features/transport_ads/presentation/screens/home_screen.dart';
import '../features/transport_ads/presentation/screens/my_ads_screen.dart';
import '../features/transport_ads/presentation/screens/search_screen.dart';
import '../features/transport_orders/presentation/screens/cancel_order_screen.dart';
import '../features/transport_orders/presentation/screens/my_transports_screen.dart';
import '../features/transport_orders/presentation/screens/order_detail_screen.dart';
import '../features/transport_requests/presentation/screens/my_requests_screen.dart';
import '../features/transport_requests/presentation/screens/request_detail_screen.dart';
import '../features/transporter/presentation/screens/transporter_profile_screen.dart';
import 'routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.resetPassword;

      if (state.matchedLocation == AppRoutes.splash) return null;

      if (!isAuthenticated && !isAuthRoute) return AppRoutes.login;
      if (isAuthenticated && isAuthRoute) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.adList,
            builder: (context, state) => const AdListScreen(),
          ),
          GoRoute(
            path: AppRoutes.createAd,
            builder: (context, state) => const CreateAdScreen(),
          ),
          GoRoute(
            path: '/ads/:adId',
            builder: (context, state) {
              final adId = state.pathParameters['adId']!;
              return AdDetailScreen(adId: adId);
            },
          ),
          GoRoute(
            path: AppRoutes.myAds,
            builder: (context, state) => const MyAdsScreen(),
          ),
          GoRoute(
            path: '/transporter/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return TransporterProfileScreen(userId: userId);
            },
          ),
          GoRoute(
            path: AppRoutes.myRequests,
            builder: (context, state) => const MyRequestsScreen(),
          ),
          GoRoute(
            path: '/my-requests/:requestId',
            builder: (context, state) {
              final requestId = state.pathParameters['requestId']!;
              return RequestDetailScreen(requestId: requestId);
            },
          ),
          GoRoute(
            path: AppRoutes.myTransports,
            builder: (context, state) => const MyTransportsScreen(),
          ),
          GoRoute(
            path: '/my-transports/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderDetailScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: '/my-transports/:orderId/cancel',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return CancelOrderScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/reviews/:transporterId',
            builder: (context, state) {
              final transporterId = state.pathParameters['transporterId']!;
              return ReviewsScreen(transporterId: transporterId);
            },
          ),
          GoRoute(
            path: '/review/create/:orderId',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return CreateReviewScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _tabs = const [
    AppRoutes.home,
    AppRoutes.search,
    AppRoutes.myTransports,
    AppRoutes.notifications,
    AppRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Recherche',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Transports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Notifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
