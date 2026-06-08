import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/domain/session_status.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:coachpro/features/sessions/presentation/widgets/athlete_timer_button.dart';
import 'package:coachpro/features/sessions/providers/timer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  DateTime? _lastTapAt;
  bool _hasSynced = false;

  SessionKey get _sessionKey => SessionKey(
        teamId: widget.teamId,
        sessionId: widget.sessionId,
      );

  Future<void> _startTimer() async {
    final repository = ref.read(sessionsRepositoryProvider);
    final session = ref.read(sessionProvider(_sessionKey)).value;
    if (session == null) {
      return;
    }

    if (session.startedAt == null) {
      await repository.startSession(
        teamId: widget.teamId,
        sessionId: widget.sessionId,
      );
    }
    ref.read(timerProvider.notifier).start();
  }

  Future<void> _stopTimer() async {
    ref.read(timerProvider.notifier).stop();
    await ref.read(sessionsRepositoryProvider).completeSession(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
        );
    if (mounted) {
      context.pushReplacementNamed(
        'session-detail',
        pathParameters: {
          'teamId': widget.teamId,
          'sessionId': widget.sessionId,
        },
      );
    }
  }

  Future<void> _resetTimer() async {
    final splits = ref.read(splitsProvider(_sessionKey)).value ?? [];
    if (splits.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset cronometro'),
          content: const Text(
            'Vuoi azzerare il cronometro e cancellare tutti i parziali registrati?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    }

    ref.read(timerProvider.notifier).reset();
    await ref.read(sessionsRepositoryProvider).resetSession(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
        );
    _hasSynced = false;
  }

  Future<void> _recordSplit(String athleteId) async {
    final now = DateTime.now();
    if (_lastTapAt != null &&
        now.difference(_lastTapAt!).inMilliseconds < 200) {
      return;
    }
    _lastTapAt = now;

    final elapsedMs = ref.read(timerProvider.notifier).currentElapsedMs;
    await ref.read(sessionsRepositoryProvider).recordSplit(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          athleteId: athleteId,
          elapsedMs: elapsedMs,
        );
  }

  Future<void> _markAthleteFinished(String athleteId) async {
    await ref.read(sessionsRepositoryProvider).markAthleteFinished(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          athleteId: athleteId,
        );
  }

  Future<void> _confirmFinishAthlete(String athleteId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fine atleta'),
        content: Text('Segnare $name come completato per questa sessione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _markAthleteFinished(athleteId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final splitsAsync = ref.watch(splitsProvider(_sessionKey));
    final athletesAsync = ref.watch(athletesProvider(widget.teamId));
    final timer = ref.watch(timerProvider);

    ref.listen(sessionProvider(_sessionKey), (previous, next) {
      final session = next.value;
      if (session == null || _hasSynced) {
        return;
      }
      if (session.startedAt != null) {
        _hasSynced = true;
        ref.read(timerProvider.notifier).syncFromSessionStart(
              session.startedAt,
              isCompleted: session.status == SessionStatus.completed,
            );
      }
    });

    return sessionAsync.when(
      data: (session) {
        final splits = splitsAsync.value ?? [];
        final athletes = athletesAsync.value ?? [];
        final isCompleted = session.status == SessionStatus.completed;
        final canInteract = !isCompleted && timer.isRunning;

        final activeAthletes = sortAthletesForTimer(
          athletes: athletes,
          presentIds: session.presentAthleteIds,
          finishedIds: session.finishedAthleteIds,
          splits: splits,
        );
        final finishedAthletes = finishedAthletesForSession(
          athletes: athletes,
          finishedIds: session.finishedAthleteIds,
          splits: splits,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(session.name),
            actions: [
              if (isCompleted)
                IconButton(
                  onPressed: () => context.pushNamed(
                    'session-detail',
                    pathParameters: {
                      'teamId': widget.teamId,
                      'sessionId': widget.sessionId,
                    },
                  ),
                  icon: const Icon(Icons.summarize_outlined),
                  tooltip: 'Riepilogo',
                ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: timer.isRunning
                      ? AppColors.secondaryContainer
                      : AppColors.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: timer.isRunning
                          ? AppColors.secondary
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      formatElapsedMs(timer.elapsedMs),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isCompleted) ...[
                          FilledButton.icon(
                            onPressed: timer.isRunning ? null : _startTimer,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            onPressed: timer.isRunning ? _stopTimer : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                            ),
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
                          ),
                        ] else
                          const Chip(
                            label: Text('Sessione completata'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!timer.isRunning && !isCompleted)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'Premi Start per avviare il cronometro, poi tocca '
                            'un atleta per registrare un parziale. Tieni premuto '
                            'per segnare l\'atleta come completato.',
                          ),
                        ),
                      ),
                    if (activeAthletes.isNotEmpty) ...[
                      Text(
                        'In gara',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: activeAthletes.length,
                        itemBuilder: (context, index) {
                          final athlete = activeAthletes[index];
                          return AthleteTimerButton(
                            athlete: athlete,
                            splits: splits,
                            enabled: canInteract,
                            onTap: () => _recordSplit(athlete.id),
                            onLongPress: () => _confirmFinishAthlete(
                              athlete.id,
                              athlete.name,
                            ),
                          );
                        },
                      ),
                    ],
                    if (finishedAthletes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Completati',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...finishedAthletes.map(
                        (athlete) => FinishedAthleteTile(
                          athlete: athlete,
                          splits: splits,
                        ),
                      ),
                    ],
                  ],
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
