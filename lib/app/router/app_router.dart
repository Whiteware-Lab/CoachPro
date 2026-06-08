import 'package:coachpro/features/athletes/presentation/athletes_screen.dart';
import 'package:coachpro/features/auth/presentation/login_screen.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/sessions/presentation/new_session_screen.dart';
import 'package:coachpro/features/sessions/presentation/session_detail_screen.dart';
import 'package:coachpro/features/sessions/presentation/timer_screen.dart';
import 'package:coachpro/features/teams/presentation/team_detail_screen.dart';
import 'package:coachpro/features/teams/presentation/teams_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.value != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) {
        return '/login';
      }

      if (isLoggedIn && isOnLogin) {
        return '/teams';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/teams',
        builder: (context, state) => const TeamsScreen(),
        routes: [
          GoRoute(
            name: 'team-detail',
            path: ':teamId',
            builder: (context, state) => TeamDetailScreen(
              teamId: state.pathParameters['teamId']!,
            ),
            routes: [
              GoRoute(
                name: 'team-athletes',
                path: 'athletes',
                builder: (context, state) => AthletesScreen(
                  teamId: state.pathParameters['teamId']!,
                ),
              ),
              GoRoute(
                name: 'new-session',
                path: 'sessions/new',
                builder: (context, state) => NewSessionScreen(
                  teamId: state.pathParameters['teamId']!,
                ),
              ),
              GoRoute(
                name: 'session-timer',
                path: 'sessions/:sessionId/timer',
                builder: (context, state) => TimerScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
              GoRoute(
                name: 'session-detail',
                path: 'sessions/:sessionId',
                builder: (context, state) => SessionDetailScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _subscription = _ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
