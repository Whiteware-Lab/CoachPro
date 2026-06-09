import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/domain/sub_session_type.dart';
import 'package:coachpro/features/sessions/presentation/widgets/session_tool_card.dart';
import 'package:coachpro/features/sessions/presentation/widgets/sub_session_name_dialog.dart';
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

  Future<void> _startSubSession(
    BuildContext context,
    WidgetRef ref,
    SubSessionType type,
  ) async {
    final name = await showSubSessionNameDialog(
      context,
      title: type == SubSessionType.lap
          ? 'Nuova prova lap'
          : 'Nuova prova cronometro',
    );
    if (name == null || !context.mounted) {
      return;
    }

    try {
      final subSession =
          await ref.read(sessionsRepositoryProvider).createSubSession(
                teamId: teamId,
                sessionId: sessionId,
                name: name,
                type: type,
              );
      if (!context.mounted) {
        return;
      }

      final route = type == SubSessionType.lap
          ? 'session-lap-timer'
          : 'session-simple-timer';
      context.pushNamed(
        route,
        pathParameters: {
          'teamId': teamId,
          'sessionId': sessionId,
          'subSessionId': subSession.id,
        },
      );
    } on SessionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  void _openSubSession(
    BuildContext context,
    SubSessionType type,
    String subSessionId, {
    required bool isActive,
  }) {
    if (isActive) {
      final route = type == SubSessionType.lap
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
      return;
    }

    context.pushNamed(
      'sub-session-detail',
      pathParameters: {
        'teamId': teamId,
        'sessionId': sessionId,
        'subSessionId': subSessionId,
      },
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final subSessionsAsync = ref.watch(subSessionsProvider(_sessionKey));
    final notesAsync = ref.watch(sessionNotesProvider(_sessionKey));

    return sessionAsync.when(
      data: (session) {
        final subSessions = subSessionsAsync.value ?? [];
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
                    subtitle: 'Parziali multipli',
                    color: AppColors.secondary,
                    onTap: () => _startSubSession(
                      context,
                      ref,
                      SubSessionType.lap,
                    ),
                  ),
                  SessionToolCard(
                    icon: Icons.av_timer,
                    title: 'Cronometro',
                    subtitle: 'Un tap per atleta',
                    color: AppColors.primary,
                    onTap: () => _startSubSession(
                      context,
                      ref,
                      SubSessionType.simple,
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
              const SizedBox(height: 24),
              Text(
                'Storico prove',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (subSessionsAsync.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (subSessions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Nessuna prova registrata. Avvia un cronometro per iniziare.',
                    ),
                  ),
                )
              else
                ...subSessions.map(
                  (subSession) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        subSession.type == SubSessionType.lap
                            ? Icons.timer
                            : Icons.av_timer,
                        color: subSession.isActive
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                      title: Text(subSession.name),
                      subtitle: Text(
                        '${subSession.type.label} · ${_formatTime(subSession.createdAt)}'
                        '${subSession.isActive ? ' · In corso' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openSubSession(
                        context,
                        subSession.type,
                        subSession.id,
                        isActive: subSession.isActive,
                      ),
                    ),
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
