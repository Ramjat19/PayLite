import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/app/routes.dart';
import 'package:paylite/features/auth/state/session_provider.dart';
import 'package:paylite/features/auth/presentation/login_screen.dart';
import 'package:paylite/features/presentation/home_screen.dart';
import 'package:paylite/features/scan/presentation/scan_screen.dart';
import 'package:paylite/features/scan/presentation/pay_screen.dart';
import 'package:paylite/features/scan/presentation/review_screen.dart';
import 'package:paylite/features/scan/presentation/pin_screen.dart';
import 'package:paylite/features/scan/presentation/status_screen.dart';
import 'package:paylite/features/presentation/history_screen.dart';
import 'package:paylite/features/collect/presentation/requests_screen.dart';
import 'package:paylite/features/split/presentation/split_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    initialLocation: session ? Routes.home : Routes.login,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider);
      final goingToLogin = state.matchedLocation == Routes.login;

      // Not logged in → force to /login
      if (!loggedIn && !goingToLogin) return Routes.login;

      // Logged in but trying to hit /login → send to /home
      if (loggedIn && goingToLogin) return Routes.home;

      return null; // no redirect
    },
    routes: [
      GoRoute(path: Routes.login, name: 'login',
        builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.home, name: 'home',
        builder: (_, _) => const HomeScreen()),
      GoRoute(path: Routes.scan, name: 'scan',
        builder: (_, _) => const ScanScreen()),
      GoRoute(path: Routes.pay, name: 'pay',
        builder: (_, _) => const PayScreen()),
      GoRoute(path: Routes.payReview, name: 'payReview',
        builder: (_, _) => const ReviewScreen()),
      GoRoute(path: Routes.payPin, name: 'payPin',
        builder: (_, _) => const PinScreen()),
      GoRoute(
        path: '${Routes.payStatus}/:id', name: 'payStatus',
        builder: (_, state) => StatusScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.history, name: 'history',
        builder: (_, _) => const HistoryScreen()),
      GoRoute(path: Routes.requests, name: 'requests',
        builder: (_, _) => const RequestsScreen()),
      GoRoute(path: Routes.split, name: 'split',
        builder: (_, _) => const SplitScreen()),
      // GoRoute(path: Routes.requests, name: 'requests',
      //   builder: (_, __) => const RequestsScreen()),
      // GoRoute(path: Routes.split, name: 'split',
      //   builder: (_, __) => const SplitScreen()),
      // GoRoute(path: Routes.history, name: 'history',
      //   builder: (_, __) => const HistoryScreen()),
      // GoRoute(
      //   path: '${Routes.historyDetail}/:id', name: 'historyDetail',
      //   builder: (_, state) => HistoryDetailScreen(id: state.pathParameters['id']!),
      // ),
    ],
  );
});   