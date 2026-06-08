import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/domain/session.dart';
import 'package:coachpro/features/sessions/domain/session_status.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  SessionKey get _sessionKey =>
      SessionKey(teamId: teamId, sessionId: sessionId);

  Future<void> _deleteSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina sessione'),
        content: const Text(
          'Vuoi eliminare questa sessione e tutti i tempi registrati?',
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
          sessionId: sessionId,
        );
    if (context.mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessione eliminata')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final splitsAsync = ref.watch(splitsProvider(_sessionKey));
    final athletesAsync = ref.watch(athletesProvider(teamId));

    return sessionAsync.when(
      data: (session) {
        final splits = splitsAsync.value ?? [];
        final athletes = athletesAsync.value ?? [];
        final athleteNames = {
          for (final athlete in athletes) athlete.id: athlete.name,
        };
        final stats = buildAthleteStats(splits)
            .where(
              (stat) => session.presentAthleteIds.contains(stat.athleteId),
            )
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            actions: [
              if (session.status.isActive)
                IconButton(
                  onPressed: () => context.pushNamed(
                    'session-timer',
                    pathParameters: {
                      'teamId': teamId,
                      'sessionId': sessionId,
                    },
                  ),
                  icon: const Icon(Icons.timer_outlined),
                  tooltip: 'Cronometro',
                ),
              IconButton(
                onPressed: () => _deleteSession(context, ref),
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Elimina sessione',
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
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: session.type.label,
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.flag_outlined,
                        label: session.status == SessionStatus.completed
                            ? 'Completata'
                            : 'In corso',
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.groups_outlined,
                        label: '${session.presentAthleteIds.length} presenti',
                      ),
                      if (session.startedAt != null) ...[
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: session.endedAt != null
                              ? 'Durata: ${formatElapsedMs(_sessionDuration(session))}'
                              : 'Avviata',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Classifica',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (stats.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nessun parziale registrato.'),
                  ),
                )
              else
                ...stats.asMap().entries.map(
                  (entry) {
                    final position = entry.key + 1;
                    final stat = entry.value;
                    final name =
                        athleteNames[stat.athleteId] ?? 'Atleta sconosciuto';
                    return Card(
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: position == 1
                              ? AppColors.secondaryContainer
                              : AppColors.primaryContainer,
                          child: Text('$position'),
                        ),
                        title: Text(name),
                        subtitle: Text('${stat.laps.length} giri'),
                        trailing: Text(
                          formatElapsedMs(stat.totalMs),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        children: stat.laps
                            .map(
                              (lap) => ListTile(
                                dense: true,
                                title: Text('Giro ${lap.lapNumber}'),
                                trailing: Text(
                                  formatElapsedMs(lap.elapsedMs),
                                  style: const TextStyle(
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Errore: $error')),
      ),
    );
  }

  int _sessionDuration(Session session) {
    if (session.startedAt == null) {
      return 0;
    }
    final end = session.endedAt ?? DateTime.now();
    return end.difference(session.startedAt!).inMilliseconds;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
