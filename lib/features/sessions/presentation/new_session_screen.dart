import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/date_format.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/session_kind.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:coachpro/features/teams/providers/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({required this.teamId, super.key});

  final String teamId;

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  SessionKind _kind = SessionKind.allenamento;
  DateTime _sessionDate = dateOnly(DateTime.now());
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _sessionDate = dateOnly(picked));
    }
  }

  Future<void> _createSession() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = await ref.read(sessionsRepositoryProvider).createSession(
            teamId: widget.teamId,
            kind: _kind,
            sessionDate: _sessionDate,
            createdBy: user.uid,
          );
      if (mounted) {
        context.goNamed(
          'session-hub',
          pathParameters: {
            'teamId': widget.teamId,
            'sessionId': session.id,
          },
        );
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
    final teamAsync = ref.watch(teamProvider(widget.teamId));

    return teamAsync.when(
      data: (team) => Scaffold(
        appBar: AppBar(
          title: Text('Nuova sessione · ${team.name}'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tipo sessione',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<SessionKind>(
              segments: SessionKind.values
                  .map(
                    (kind) => ButtonSegment(
                      value: kind,
                      label: Text(kind.label),
                      icon: Icon(
                        kind == SessionKind.gara
                            ? Icons.emoji_events_outlined
                            : Icons.fitness_center_outlined,
                      ),
                    ),
                  )
                  .toList(),
              selected: {_kind},
              onSelectionChanged: (selection) {
                setState(() => _kind = selection.first);
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                title: const Text('Data'),
                subtitle: Text(formatSessionDate(_sessionDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
              onPressed: _isSaving ? null : _createSession,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(0, 52),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Crea sessione'),
              ),
            ),
          ],
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
