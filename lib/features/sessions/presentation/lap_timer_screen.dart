import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/presentation/widgets/athlete_timer_button.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:coachpro/features/sessions/providers/timer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LapTimerScreen extends ConsumerStatefulWidget {
  const LapTimerScreen({
    required this.teamId,
    required this.sessionId,
    required this.subSessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;
  final String subSessionId;

  @override
  ConsumerState<LapTimerScreen> createState() => _LapTimerScreenState();
}

class _LapTimerScreenState extends ConsumerState<LapTimerScreen> {
  DateTime? _lastTapAt;
  bool _hasSynced = false;

  SubSessionKey get _subSessionKey => SubSessionKey(
        teamId: widget.teamId,
        sessionId: widget.sessionId,
        subSessionId: widget.subSessionId,
      );

  Future<void> _startTimer() async {
    final subSession = ref.read(subSessionProvider(_subSessionKey)).value;
    if (subSession == null) {
      return;
    }

    if (subSession.timerStartedAt == null) {
      await ref.read(sessionsRepositoryProvider).startLapTimer(
            teamId: widget.teamId,
            sessionId: widget.sessionId,
            subSessionId: widget.subSessionId,
          );
    }
    ref.read(timerProvider.notifier).start();
  }

  Future<void> _stopTimer() async {
    ref.read(timerProvider.notifier).stop();
    final elapsedMs = ref.read(timerProvider.notifier).currentElapsedMs;
    await ref.read(sessionsRepositoryProvider).endSubSession(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          subSessionId: widget.subSessionId,
          finalElapsedMs: elapsedMs,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _resetTimer() async {
    final splits = ref.read(subSessionSplitsProvider(_subSessionKey)).value ?? [];
    if (splits.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset prova'),
          content: const Text(
            'Vuoi azzerare il cronometro e cancellare tutti i parziali di questa prova?',
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
    await ref.read(sessionsRepositoryProvider).resetSubSession(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          subSessionId: widget.subSessionId,
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
          subSessionId: widget.subSessionId,
          athleteId: athleteId,
          elapsedMs: elapsedMs,
        );
  }

  Future<void> _confirmFinishAthlete(String athleteId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fine atleta'),
        content: Text('Segnare $name come completato?'),
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
      await ref.read(sessionsRepositoryProvider).markAthleteFinished(
            teamId: widget.teamId,
            sessionId: widget.sessionId,
            subSessionId: widget.subSessionId,
            athleteId: athleteId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync =
        ref.watch(sessionProvider(_subSessionKey.sessionKey));
    final subSessionAsync = ref.watch(subSessionProvider(_subSessionKey));
    final splitsAsync = ref.watch(subSessionSplitsProvider(_subSessionKey));
    final athletesAsync = ref.watch(athletesProvider(widget.teamId));
    final timer = ref.watch(timerProvider);

    ref.listen(subSessionProvider(_subSessionKey), (previous, next) {
      final subSession = next.value;
      if (subSession == null || _hasSynced) {
        return;
      }
      if (subSession.timerStartedAt != null) {
        _hasSynced = true;
        ref.read(timerProvider.notifier).syncFromSessionStart(
              subSession.timerStartedAt,
              baseElapsedMs: subSession.timerElapsedMs ?? 0,
            );
      } else if (subSession.timerElapsedMs != null) {
        _hasSynced = true;
        ref.read(timerProvider.notifier).setElapsed(subSession.timerElapsedMs!);
      }
    });

    return sessionAsync.when(
      data: (session) => subSessionAsync.when(
        data: (subSession) {
          final splits = splitsAsync.value ?? [];
          final athletes = athletesAsync.value ?? [];
          final canInteract = timer.isRunning && subSession.isActive;

          if (session.presentAthleteIds.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: Text(subSession.name)),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Segna prima le presenze per usare il cronometro lap.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          final activeAthletes = sortAthletesForTimer(
            athletes: athletes,
            presentIds: session.presentAthleteIds,
            finishedIds: subSession.finishedAthleteIds,
            splits: splits,
          );
          final finishedAthletes = finishedAthletesForSession(
            athletes: athletes,
            finishedIds: subSession.finishedAthleteIds,
            splits: splits,
          );

          return Scaffold(
            appBar: AppBar(title: Text(subSession.name)),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: subSession.isActive && !timer.isRunning
                                ? _startTimer
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                          FilledButton.icon(
                            onPressed: timer.isRunning ? _stopTimer : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE65100),
                            ),
                            icon: const Icon(Icons.stop),
                            label: const Text('Termina'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                subSession.isActive ? _resetTimer : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset'),
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
                      if (!timer.isRunning && subSession.isActive)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Premi Start, poi tocca un atleta per registrare un '
                              'parziale. Tieni premuto per segnarlo come completato.',
                            ),
                          ),
                        ),
                      if (activeAthletes.isNotEmpty) ...[
                        const SizedBox(height: 8),
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
      ),
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
