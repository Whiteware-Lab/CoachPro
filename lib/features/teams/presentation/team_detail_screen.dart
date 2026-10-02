import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/presentation/widgets/sub_session_name_dialog.dart';
import 'package:coachpro/features/sessions/presentation/widgets/session_card.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:coachpro/features/teams/data/teams_repository.dart';
import 'package:coachpro/features/teams/domain/team.dart';
import 'package:coachpro/features/teams/domain/team_invite.dart';
import 'package:coachpro/features/teams/presentation/widgets/invite_coach_dialog.dart';
import 'package:coachpro/features/teams/providers/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeamDetailScreen extends ConsumerWidget {
  const TeamDetailScreen({required this.teamId, super.key});

  final String teamId;

  Future<void> _renameSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final name = await showSubSessionNameDialog(
      context,
      title: 'Rinomina sessione',
      initialName: session.displayTitle,
      fieldLabel: 'Nome sessione',
      hintText: 'Es. Test 400 metri',
      confirmLabel: 'Salva',
    );
    if (name == null || !context.mounted) {
      return;
    }
    await ref.read(sessionsRepositoryProvider).updateSessionName(
          teamId: teamId,
          sessionId: session.id,
          name: name,
        );
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina sessione'),
        content: Text(
          'Vuoi eliminare “${session.displayTitle}” e tutti i dati associati?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(sessionsRepositoryProvider).deleteSession(
          teamId: teamId,
          sessionId: session.id,
        );
  }

  Future<void> _inviteCoach(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final email = await showInviteCoachDialog(context);
    if (email == null || !context.mounted) {
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return;
    }

    try {
      await ref.read(teamsRepositoryProvider).inviteCoach(
            teamId: team.id,
            teamName: team.name,
            email: email,
            invitedBy: user.uid,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invito inviato a $email')),
        );
      }
    } on TeamsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    TeamInvite invite,
  ) async {
    try {
      await ref.read(teamsRepositoryProvider).cancelInvite(
            teamId: invite.teamId,
            email: invite.email,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invito annullato')),
        );
      }
    } on TeamsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _deleteTeam(
    BuildContext context,
    WidgetRef ref,
    Team team,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina squadra'),
        content: Text(
          'Vuoi eliminare "${team.name}"? L\'operazione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(teamsRepositoryProvider).deleteTeam(team.id);
      if (context.mounted) {
        context.go('/teams');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Squadra eliminata')),
        );
      }
    } on TeamsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final invitesAsync = ref.watch(teamInvitesProvider(teamId));
    final athleteCount = ref.watch(athleteCountProvider(teamId));
    final sessionsAsync = ref.watch(sessionsProvider(teamId));
    final user = ref.watch(authStateProvider).value;

    return teamAsync.when(
      data: (team) {
        final isCreator = user != null && team.isCreator(user.uid);
        final pendingInvites = invitesAsync.value
                ?.where((invite) => invite.isPending)
                .toList() ??
            [];

        return Scaffold(
          appBar: AppBar(
            title: Text(team.name),
            actions: [
              if (isCreator)
                IconButton(
                  onPressed: () => _deleteTeam(context, ref, team),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Elimina squadra',
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informazioni',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.groups,
                        label: 'Coach nella squadra',
                        value: '${team.coachIds.length}',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Creata il',
                        value: _formatDate(team.createdAt),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.directions_run,
                        label: 'Atleti attivi',
                        value: '$athleteCount',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.pushNamed(
                    'team-athletes',
                    pathParameters: {'teamId': team.id},
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_run,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestisci atleti',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                athleteCount == 0
                                    ? 'Aggiungi gli atleti della squadra'
                                    : '$athleteCount atleti in rosa',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Sessioni',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => context.pushNamed(
                      'new-session',
                      pathParameters: {'teamId': team.id},
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuova sessione'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nessuna sessione registrata.'),
                            const SizedBox(height: 8),
                            Text(
                              'Tocca "Nuova sessione" per creare il primo allenamento.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final recent = sessions;
                  return Column(
                    children: [
                      ...recent.map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SessionCard(
                            session: session,
                            onTap: () => context.pushNamed(
                              'session-hub',
                              pathParameters: {
                                'teamId': team.id,
                                'sessionId': session.id,
                              },
                            ),
                            onRename: () =>
                                _renameSession(context, ref, session),
                            onDelete: () =>
                                _deleteSession(context, ref, session),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Text('Errore sessioni: $error'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Inviti coach',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _inviteCoach(context, ref, team),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invita'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              invitesAsync.when(
                data: (invites) {
                  if (invites.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nessun invito inviato.'),
                      ),
                    );
                  }

                  return Column(
                    children: invites
                        .map(
                          (invite) => Card(
                            child: ListTile(
                              leading: Icon(
                                invite.isPending
                                    ? Icons.schedule
                                    : Icons.check_circle,
                                color: invite.isPending
                                    ? AppColors.secondary
                                    : AppColors.success,
                              ),
                              title: Text(invite.email),
                              subtitle: Text(
                                invite.isPending
                                    ? 'In attesa'
                                    : 'Accettato',
                              ),
                              trailing: invite.isPending
                                  ? IconButton(
                                      onPressed: () => _cancelInvite(
                                        context,
                                        ref,
                                        invite,
                                      ),
                                      icon: const Icon(Icons.close),
                                      tooltip: 'Annulla invito',
                                    )
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Text('Errore inviti: $error'),
              ),
              if (pendingInvites.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${pendingInvites.length} invito/i in attesa di risposta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Errore: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
