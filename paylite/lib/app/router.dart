import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/app/routes.dart';
import 'package:paylite/features/auth/state/session_provider.dart';
import 'package:paylite/features/auth/presentation/login_screen.dart';
import 'package:paylite/features/presentation/home_screen.dart';

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
        builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.home, name: 'home',
        builder: (_, __) => const HomeScreen()),
      // GoRoute(path: Routes.scan, name: 'scan',
      //   builder: (_, __) => const ScanScreen()),
      // GoRoute(path: Routes.pay, name: 'pay',
      //   builder: (_, __) => const PayScreen()),
      // GoRoute(path: Routes.payReview, name: 'payReview',
      //   builder: (_, __) => const ReviewScreen()),
      // GoRoute(path: Routes.payPin, name: 'payPin',
      //   builder: (_, __) => const PinScreen()),
      // GoRoute(
      //   path: '${Routes.payStatus}/:id', name: 'payStatus',
      //   builder: (_, state) => StatusScreen(id: state.pathParameters['id']!),
      // ),
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