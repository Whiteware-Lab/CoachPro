import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/time_format.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:coachpro/features/sessions/providers/timer_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimpleTimerScreen extends ConsumerStatefulWidget {
  const SimpleTimerScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  @override
  ConsumerState<SimpleTimerScreen> createState() => _SimpleTimerScreenState();
}

class _SimpleTimerScreenState extends ConsumerState<SimpleTimerScreen> {
  bool _hasSynced = false;

  SessionKey get _sessionKey => SessionKey(
        teamId: widget.teamId,
        sessionId: widget.sessionId,
      );

  Future<void> _startTimer(int baseMs) async {
    await ref.read(sessionsRepositoryProvider).startSimpleTimer(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          baseElapsedMs: baseMs,
        );
    ref.read(timerProvider.notifier).start();
  }

  Future<void> _stopTimer() async {
    final elapsedMs = ref.read(timerProvider.notifier).currentElapsedMs;
    ref.read(timerProvider.notifier).stop();
    await ref.read(sessionsRepositoryProvider).stopSimpleTimer(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
          elapsedMs: elapsedMs,
        );
  }

  Future<void> _resetTimer() async {
    ref.read(timerProvider.notifier).reset();
    await ref.read(sessionsRepositoryProvider).resetSimpleTimer(
          teamId: widget.teamId,
          sessionId: widget.sessionId,
        );
    _hasSynced = false;
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final timer = ref.watch(timerProvider);

    ref.listen(sessionProvider(_sessionKey), (previous, next) {
      final session = next.value;
      if (session == null || _hasSynced) {
        return;
      }

      if (session.simpleTimerStartedAt != null) {
        _hasSynced = true;
        ref.read(timerProvider.notifier).syncFromSessionStart(
              session.simpleTimerStartedAt,
              baseElapsedMs: session.simpleTimerElapsedMs ?? 0,
            );
      } else if (session.simpleTimerElapsedMs != null) {
        _hasSynced = true;
        ref.read(timerProvider.notifier).setElapsed(session.simpleTimerElapsedMs!);
      }
    });

    return sessionAsync.when(
      data: (session) => Scaffold(
        appBar: AppBar(title: const Text('Cronometro')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: timer.isRunning
                        ? AppColors.secondaryContainer
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: timer.isRunning
                          ? AppColors.secondary
                          : AppColors.primary,
                      width: 3,
                    ),
                  ),
                  child: Text(
                    formatElapsedMs(timer.elapsedMs),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: timer.isRunning
                          ? null
                          : () => _startTimer(timer.elapsedMs),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        minimumSize: const Size(120, 48),
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: timer.isRunning ? _stopTimer : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
                        minimumSize: const Size(120, 48),
                      ),
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
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
