import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/teams/data/teams_repository.dart';
import 'package:coachpro/features/teams/domain/team.dart';
import 'package:coachpro/features/teams/domain/team_invite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamsRepositoryProvider = Provider<TeamsRepository>(
  (ref) => TeamsRepository(),
);

final teamsProvider = StreamProvider<List<Team>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.watch(teamsRepositoryProvider).watchTeams(user.uid);
});

final teamProvider = StreamProvider.family<Team, String>((ref, teamId) {
  return ref.watch(teamsRepositoryProvider).watchTeam(teamId);
});

final pendingInvitesProvider = StreamProvider<List<TeamInvite>>((ref) {
  final user = ref.watch(authStateProvider).value;
  final email = user?.email;
  if (email == null) {
    return const Stream.empty();
  }
  return ref.watch(teamsRepositoryProvider).watchPendingInvites(email);
});

final teamInvitesProvider =
    StreamProvider.family<List<TeamInvite>, String>((ref, teamId) {
  return ref.watch(teamsRepositoryProvider).watchTeamInvites(teamId);
});
