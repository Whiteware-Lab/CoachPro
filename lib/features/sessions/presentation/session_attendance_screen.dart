import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionAttendanceScreen extends ConsumerStatefulWidget {
  const SessionAttendanceScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  @override
  ConsumerState<SessionAttendanceScreen> createState() =>
      _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState
    extends ConsumerState<SessionAttendanceScreen> {
  late Set<String> _selectedIds;
  bool _initialized = false;
  bool _isSaving = false;

  SessionKey get _sessionKey => SessionKey(
        teamId: widget.teamId,
        sessionId: widget.sessionId,
      );

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(sessionsRepositoryProvider).updatePresentAthletes(
            teamId: widget.teamId,
            sessionId: widget.sessionId,
            presentAthleteIds: _selectedIds.toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presenze aggiornate')),
        );
        Navigator.of(context).pop();
      }
    } on SessionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider(_sessionKey));
    final athletesAsync = ref.watch(athletesProvider(widget.teamId));

    return sessionAsync.when(
      data: (session) {
        if (!_initialized) {
          _selectedIds = session.presentAthleteIds.toSet();
          _initialized = true;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Presenze atleti')),
          body: athletesAsync.when(
            data: (athletes) {
              if (athletes.isEmpty) {
                return const Center(
                  child: Text('Aggiungi atleti alla squadra prima.'),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedIds.length} presenti',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => setState(
                            () => _selectedIds
                              ..clear()
                              ..addAll(athletes.map((a) => a.id)),
                          ),
                          child: const Text('Tutti'),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedIds.clear()),
                          child: const Text('Nessuno'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: athletes.length,
                      itemBuilder: (context, index) {
                        final athlete = athletes[index];
                        final isPresent = _selectedIds.contains(athlete.id);
                        return Card(
                          child: CheckboxListTile(
                            value: isPresent,
                            onChanged: (value) {
                              setState(() {
                                if (value ?? false) {
                                  _selectedIds.add(athlete.id);
                                } else {
                                  _selectedIds.remove(athlete.id);
                                }
                              });
                            },
                            title: Text(athlete.name),
                            subtitle: athlete.bibNumber != null
                                ? Text('Pett. ${athlete.bibNumber}')
                                : null,
                            secondary: CircleAvatar(
                              backgroundColor: isPresent
                                  ? AppColors.secondaryContainer
                                  : AppColors.primaryContainer,
                              child: Text(
                                athlete.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: isPresent
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Salva presenze'),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Errore: $error')),
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
