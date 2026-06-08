import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/presentation/widgets/session_tool_card.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SessionHubScreen extends ConsumerWidget {
  const SessionHubScreen({
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
          'Vuoi eliminare questa sessione e tutti i dati associati?',
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
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final splitsAsync = ref.watch(splitsProvider(_sessionKey));
    final notesAsync = ref.watch(sessionNotesProvider(_sessionKey));

    return sessionAsync.when(
      data: (session) {
        final splitCount = splitsAsync.value?.length ?? 0;
        final noteCount = notesAsync.value?.length ?? 0;
        final presentCount = session.presentAthleteIds.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(session.displayTitle),
            actions: [
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
                color: session.kind == SessionKind.gara
                    ? AppColors.secondaryContainer
                    : AppColors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        session.kind == SessionKind.gara
                            ? Icons.emoji_events
                            : Icons.fitness_center,
                        color: session.kind == SessionKind.gara
                            ? AppColors.secondary
                            : AppColors.primary,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.kind.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(session.displayTitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Strumenti',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  SessionToolCard(
                    icon: Icons.timer,
                    title: 'Cronometro lap',
                    subtitle: splitCount > 0
                        ? '$splitCount parziali registrati'
                        : 'Parziali per atleta',
                    color: AppColors.secondary,
                    onTap: () => context.pushNamed(
                      'session-lap-timer',
                      pathParameters: {
                        'teamId': teamId,
                        'sessionId': sessionId,
                      },
                    ),
                  ),
                  SessionToolCard(
                    icon: Icons.av_timer,
                    title: 'Cronometro',
                    subtitle: session.simpleTimerElapsedMs != null
                        ? 'Ultimo tempo salvato'
                        : 'Start / stop semplice',
                    color: AppColors.primary,
                    onTap: () => context.pushNamed(
                      'session-simple-timer',
                      pathParameters: {
                        'teamId': teamId,
                        'sessionId': sessionId,
                      },
                    ),
                  ),
                  SessionToolCard(
                    icon: Icons.how_to_reg,
                    title: 'Presenze',
                    subtitle: presentCount > 0
                        ? '$presentCount atleti presenti'
                        : 'Segna chi è presente',
                    color: AppColors.success,
                    onTap: () => context.pushNamed(
                      'session-attendance',
                      pathParameters: {
                        'teamId': teamId,
                        'sessionId': sessionId,
                      },
                    ),
                  ),
                  SessionToolCard(
                    icon: Icons.note_alt_outlined,
                    title: 'Note',
                    subtitle: noteCount > 0
                        ? '$noteCount note'
                        : 'Aggiungi note con titolo',
                    color: AppColors.primary,
                    onTap: () => context.pushNamed(
                      'session-notes',
                      pathParameters: {
                        'teamId': teamId,
                        'sessionId': sessionId,
                      },
                    ),
                  ),
                ],
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
