import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_models.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/category/presentation/screens/category_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/home/presentation/screens/product_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/tracking/presentation/screens/order_tracking_screen.dart';
import '../../features/orders/presentation/screens/order_history_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/saved_addresses_screen.dart';
import '../../features/profile/presentation/screens/payments_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/map/presentation/screens/map_screen.dart';
import '../../features/out_of_service/presentation/screens/out_of_service_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../services/auth_service.dart';

// ─── Route Names ─────────────────────────────────────────────────────────────
abstract class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const otp = '/otp';
  static const home = '/home';
  static const categories = '/categories';
  static const cart = '/cart';
  static const productDetail = '/product/:id';
  static const checkout = '/checkout';
  static const orderTracking = '/tracking/:orderId';
  static const orderHistory = '/orders';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const map = '/map';
  static const outOfService = '/out-of-service';
  static const editProfile = '/edit-profile';
  static const savedAddresses = '/saved-addresses';
  static const addAddress = '/add-address';
  static const payments = '/payments';
  static const settings = '/settings';
}

// ─── Router Provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListener = GoRouterRefreshStream(
    ref.watch(authServiceProvider).authStateChanges,
  );

  ref.onDispose(() => refreshListener.dispose());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListener,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash drives its own navigation — never interfere
      if (loc == AppRoutes.splash) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.otp ||
          loc == AppRoutes.onboarding ||
          loc == '/login-callback';

      // Logged-in user on auth screen → check location result and route
      if (isLoggedIn && isAuthRoute) {
        final locStatus = ref.read(locationProvider).status;
        if (locStatus == LocationStatus.outOfRange) {
          return AppRoutes.outOfService;
        }
        // inRange, denied, error, loading, initial → all go home
        // (checkout validates address separately)
        return AppRoutes.home;
      }

      // Not logged in on protected screen → login
      if (!isLoggedIn && !isAuthRoute && loc != AppRoutes.outOfService) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login-callback',
        builder: (ctx, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (ctx, state) =>
            _fadeTransition(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          OtpScreen(phone: state.extra as String? ?? ''),
        ),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (ctx, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.categories,
            name: 'categories',
            builder: (ctx, state) => const CategoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.cart,
            name: 'cart',
            builder: (ctx, state) => const CartScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (ctx, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        name: 'productDetail',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          ProductDetailScreen(
            productId: state.pathParameters['id'] ?? '',
            product: state.extra as ProductModel?,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        name: 'checkout',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: AppRoutes.orderTracking,
        name: 'orderTracking',
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          OrderTrackingScreen(orderId: state.pathParameters['orderId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.orderHistory,
        name: 'orderHistory',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const OrderHistoryScreen()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.savedAddresses,
        name: 'savedAddresses',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const SavedAddressesScreen()),
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const PaymentsScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (ctx, state) =>
            _slideTransition(state, const MapScreen()),
      ),
      GoRoute(
        path: AppRoutes.outOfService,
        name: 'outOfService',
        pageBuilder: (ctx, state) =>
            _fadeTransition(state, const OutOfServiceScreen()),
      ),
    ],
  );
});

// ─── Transitions ─────────────────────────────────────────────────────────────
CustomTransitionPage _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

CustomTransitionPage _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 400),
  );
}
