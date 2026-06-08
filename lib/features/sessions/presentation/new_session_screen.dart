import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/auth/providers/auth_providers.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/session_type.dart';
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
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SessionType _type = SessionType.corsa;
  final _selectedAthleteIds = <String>{};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAthlete(String athleteId, bool selected) {
    setState(() {
      if (selected) {
        _selectedAthleteIds.add(athleteId);
      } else {
        _selectedAthleteIds.remove(athleteId);
      }
    });
  }

  void _selectAll(List<Athlete> athletes) {
    setState(() {
      _selectedAthleteIds
        ..clear()
        ..addAll(athletes.map((athlete) => athlete.id));
    });
  }

  Future<void> _createSession() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedAthleteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno un atleta presente')),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = await ref.read(sessionsRepositoryProvider).createSession(
            teamId: widget.teamId,
            name: _nameController.text,
            type: _type,
            presentAthleteIds: _selectedAthleteIds.toList(),
            createdBy: user.uid,
          );
      if (mounted) {
        context.goNamed(
          'session-timer',
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
    final athletesAsync = ref.watch(athletesProvider(widget.teamId));

    return teamAsync.when(
      data: (team) => Scaffold(
        appBar: AppBar(
          title: Text('Nuova sessione · ${team.name}'),
        ),
        body: athletesAsync.when(
          data: (athletes) {
            if (athletes.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_run, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        'Aggiungi almeno un atleta prima di creare una sessione.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.pushNamed(
                          'team-athletes',
                          pathParameters: {'teamId': widget.teamId},
                        ),
                        child: const Text('Gestisci atleti'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome sessione *',
                      hintText: 'Es. Allenamento 6x200',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci un nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                    ),
                    child: Text(_type.label),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Atleti presenti',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _selectAll(athletes),
                        child: const Text('Seleziona tutti'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...athletes.map(
                    (athlete) => Card(
                      child: CheckboxListTile(
                        value: _selectedAthleteIds.contains(athlete.id),
                        onChanged: (value) =>
                            _toggleAthlete(athlete.id, value ?? false),
                        title: Text(athlete.name),
                        subtitle: athlete.bibNumber != null
                            ? Text('Pett. ${athlete.bibNumber}')
                            : null,
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            athlete.name[0].toUpperCase(),
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isSaving ? null : _createSession,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      minimumSize: const Size.fromHeight(52),
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
                        : const Text('Crea e avvia cronometro'),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Errore: $error')),
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
