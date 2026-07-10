import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/booking/presentation/book_screen.dart';
import '../../features/booking/presentation/booking_confirmed_screen.dart';
import '../../features/booking/presentation/my_bookings_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/shell_scaffold.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rides/presentation/live_rides_screen.dart';
import '../../features/rides/presentation/ride_details_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/support/presentation/contact_screen.dart';
import '../../features/support/presentation/static_pages.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Routes that require a session; everything else supports guest browsing —
/// same gating as the web app.
const _authRequired = {'/book', '/my-bookings', '/profile'};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (authState.loading) return loc == '/splash' ? null : '/splash';
      if (loc == '/splash') return '/';
      final needsAuth = _authRequired.any((p) => loc.startsWith(p));
      if (needsAuth && !authState.isLoggedIn) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if ((loc == '/login' || loc == '/signup') && authState.isLoggedIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // Bottom-nav shell: Home · Rides · Bookings · Community · Profile
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/live-rides', builder: (_, __) => const LiveRidesScreen()),
          GoRoute(path: '/my-bookings', builder: (_, __) => const MyBookingsScreen()),
          GoRoute(path: '/community', builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full-screen flows
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/ride/:id',
        builder: (_, s) => RideDetailsScreen(idOrCode: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/book/:rideCode',
        builder: (_, s) => BookScreen(rideCode: s.pathParameters['rideCode']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/booking-confirmed',
        builder: (_, s) => BookingConfirmedScreen(extra: s.extra as Map<String, dynamic>?),
      ),
      GoRoute(parentNavigatorKey: _rootKey, path: '/contact', builder: (_, __) => const ContactScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/safety', builder: (_, __) => const SafetyScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/help', builder: (_, __) => const HelpCenterScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(parentNavigatorKey: _rootKey, path: '/refund-policy', builder: (_, __) => const RefundPolicyScreen()),
    ],
  );
});
