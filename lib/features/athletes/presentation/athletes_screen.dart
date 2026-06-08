import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/features/athletes/data/athletes_repository.dart';
import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:coachpro/features/athletes/presentation/widgets/athlete_form_dialog.dart';
import 'package:coachpro/features/athletes/providers/athletes_providers.dart';
import 'package:coachpro/features/teams/providers/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AthletesScreen extends ConsumerWidget {
  const AthletesScreen({required this.teamId, super.key});

  final String teamId;

  Future<void> _addAthlete(BuildContext context, WidgetRef ref) async {
    final data = await showAthleteFormDialog(context);
    if (data == null || !context.mounted) {
      return;
    }

    try {
      await ref.read(athletesRepositoryProvider).createAthlete(
            teamId: teamId,
            name: data.name,
            bibNumber: data.bibNumber,
            notes: data.notes,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${data.name} aggiunto alla squadra')),
        );
      }
    } on AthletesException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _editAthlete(
    BuildContext context,
    WidgetRef ref,
    Athlete athlete,
  ) async {
    final data = await showAthleteFormDialog(context, athlete: athlete);
    if (data == null || !context.mounted) {
      return;
    }

    try {
      await ref.read(athletesRepositoryProvider).updateAthlete(
            teamId: teamId,
            athlete: athlete,
            name: data.name,
            bibNumber: data.bibNumber,
            notes: data.notes,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Atleta aggiornato')),
        );
      }
    } on AthletesException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Future<void> _deleteAthlete(
    BuildContext context,
    WidgetRef ref,
    Athlete athlete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rimuovi atleta'),
        content: Text(
          'Vuoi rimuovere ${athlete.name} dalla squadra?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rimuovi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(athletesRepositoryProvider).deleteAthlete(
            teamId: teamId,
            athleteId: athlete.id,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${athlete.name} rimosso')),
        );
      }
    } on AthletesException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamProvider(teamId));
    final athletesAsync = ref.watch(athletesProvider(teamId));

    return teamAsync.when(
      data: (team) => Scaffold(
        appBar: AppBar(
          title: Text('Atleti · ${team.name}'),
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
                      const Icon(Icons.directions_run, size: 72),
                      const SizedBox(height: 16),
                      Text(
                        'Nessun atleta',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aggiungi gli atleti della squadra per usarli nelle sessioni.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: athletes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final athlete = athletes[index];
                return _AthleteCard(
                  athlete: athlete,
                  onEdit: () => _editAthlete(context, ref, athlete),
                  onDelete: () => _deleteAthlete(context, ref, athlete),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Errore: $error')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addAthlete(context, ref),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text('Aggiungi atleta'),
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

class _AthleteCard extends StatelessWidget {
  const _AthleteCard({
    required this.athlete,
    required this.onEdit,
    required this.onDelete,
  });

  final Athlete athlete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            athlete.name.isNotEmpty ? athlete.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          athlete.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildSubtitle(),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Modifica'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Rimuovi', style: TextStyle(color: AppColors.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final parts = <String>[];
    if (athlete.bibNumber != null) {
      parts.add('Pett. ${athlete.bibNumber}');
    }
    if (athlete.notes != null) {
      parts.add(athlete.notes!);
    }
    if (parts.isEmpty) {
      return null;
    }
    return Text(parts.join(' · '));
  }
}
