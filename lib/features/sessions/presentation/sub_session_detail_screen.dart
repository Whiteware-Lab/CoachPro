import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/domain/split.dart';
import 'package:coachpro/features/sessions/domain/sub_session_type.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SubSessionDetailScreen extends ConsumerWidget {
  const SubSessionDetailScreen({
    required this.teamId,
    required this.sessionId,
    required this.subSessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;
  final String subSessionId;

  SubSessionKey get _key => SubSessionKey(
        teamId: teamId,
        sessionId: sessionId,
        subSessionId: subSessionId,
      );

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subSessionAsync = ref.watch(subSessionProvider(_key));
    final splitsAsync = ref.watch(subSessionSplitsProvider(_key));
    final athletesAsync = ref.watch(athletesProvider(teamId));

    return subSessionAsync.when(
      data: (subSession) {
        final splits = splitsAsync.value ?? [];
        final athletes = athletesAsync.value ?? [];
        final stats = buildAthleteStats(splits);
        final athleteNames = {
          for (final athlete in athletes) athlete.id: athlete.name,
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(subSession.name),
            actions: [
              if (subSession.isActive)
                IconButton(
                  onPressed: () {
                    final route = subSession.type == SubSessionType.lap
                        ? 'session-lap-timer'
                        : 'session-simple-timer';
                    context.pushNamed(
                      route,
                      pathParameters: {
                        'teamId': teamId,
                        'sessionId': sessionId,
                        'subSessionId': subSessionId,
                      },
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Continua',
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
                      Row(
                        children: [
                          Icon(
                            subSession.type == SubSessionType.lap
                                ? Icons.timer
                                : Icons.av_timer,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            subSession.type.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          if (subSession.isActive)
                            const Chip(
                              label: Text('In corso'),
                              backgroundColor: AppColors.secondaryContainer,
                            )
                          else
                            const Chip(
                              label: Text('Completata'),
                              backgroundColor: AppColors.surfaceVariant,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Avviata alle ${_formatTime(subSession.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (subSession.endedAt != null)
                        Text(
                          'Terminata alle ${_formatTime(subSession.endedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (subSession.timerElapsedMs != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tempo cronometro: '
                          '${formatElapsedMs(subSession.timerElapsedMs!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Risultati atleti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (stats.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Nessun tempo registrato.'),
                  ),
                )
              else
                ...stats.map(
                  (stat) => _AthleteStatsCard(
                    athleteName:
                        athleteNames[stat.athleteId] ?? 'Atleta sconosciuto',
                    stats: stat,
                    showLapLabel: subSession.type == SubSessionType.lap,
                  ),
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
}

class _AthleteStatsCard extends StatelessWidget {
  const _AthleteStatsCard({
    required this.athleteName,
    required this.stats,
    required this.showLapLabel,
  });

  final String athleteName;
  final AthleteSessionStats stats;
  final bool showLapLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    athleteName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  formatElapsedMs(stats.totalMs),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (stats.laps.length > 1 || showLapLabel) ...[
              const SizedBox(height: 8),
              ...stats.laps.map(
                (lap) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        showLapLabel ? 'Giro ${lap.lapNumber}' : 'Tempo',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        formatElapsedMs(lap.elapsedMs),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
