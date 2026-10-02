import 'package:coachpro/features/athletes/presentation/athletes_screen.dart';
import 'package:coachpro/features/auth/presentation/login_screen.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/sessions/presentation/lap_timer_screen.dart';
import 'package:coachpro/features/sessions/presentation/battery_editor_screen.dart';
import 'package:coachpro/features/sessions/presentation/new_session_screen.dart';
import 'package:coachpro/features/sessions/presentation/session_attendance_screen.dart';
import 'package:coachpro/features/sessions/presentation/session_batteries_screen.dart';
import 'package:coachpro/features/sessions/presentation/session_hub_screen.dart';
import 'package:coachpro/features/sessions/presentation/session_notes_screen.dart';
import 'package:coachpro/features/sessions/presentation/simple_timer_screen.dart';
import 'package:coachpro/features/sessions/presentation/sub_session_detail_screen.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/teams', builder: (context, state) => const TeamsScreen()),
      GoRoute(
        name: 'team-detail',
        path: '/teams/:teamId',
        builder: (context, state) =>
            TeamDetailScreen(teamId: state.pathParameters['teamId']!),
        routes: [
          GoRoute(
            name: 'team-athletes',
            path: 'athletes',
            builder: (context, state) =>
                AthletesScreen(teamId: state.pathParameters['teamId']!),
          ),
          GoRoute(
            name: 'new-session',
            path: 'sessions/new',
            builder: (context, state) =>
                NewSessionScreen(teamId: state.pathParameters['teamId']!),
          ),
          GoRoute(
            name: 'session-hub',
            path: 'sessions/:sessionId',
            builder: (context, state) => SessionHubScreen(
              teamId: state.pathParameters['teamId']!,
              sessionId: state.pathParameters['sessionId']!,
            ),
            routes: [
              GoRoute(
                name: 'session-batteries',
                path: 'batteries',
                builder: (context, state) => SessionBatteriesScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
              GoRoute(
                name: 'battery-new',
                path: 'batteries/new',
                builder: (context, state) => BatteryEditorScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
              GoRoute(
                name: 'battery-edit',
                path: 'batteries/:batteryId/edit',
                builder: (context, state) => BatteryEditorScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                  batteryId: state.pathParameters['batteryId']!,
                ),
              ),
              GoRoute(
                name: 'sub-session-detail',
                path: 'sub-sessions/:subSessionId',
                builder: (context, state) => SubSessionDetailScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                  subSessionId: state.pathParameters['subSessionId']!,
                ),
              ),
              GoRoute(
                name: 'session-lap-timer',
                path: 'sub-sessions/:subSessionId/lap-timer',
                builder: (context, state) => LapTimerScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                  subSessionId: state.pathParameters['subSessionId']!,
                ),
              ),
              GoRoute(
                name: 'session-simple-timer',
                path: 'sub-sessions/:subSessionId/simple-timer',
                builder: (context, state) => SimpleTimerScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                  subSessionId: state.pathParameters['subSessionId']!,
                ),
              ),
              GoRoute(
                name: 'session-attendance',
                path: 'attendance',
                builder: (context, state) => SessionAttendanceScreen(
                  teamId: state.pathParameters['teamId']!,
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
              GoRoute(
                name: 'session-notes',
                path: 'notes',
                builder: (context, state) => SessionNotesScreen(
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
