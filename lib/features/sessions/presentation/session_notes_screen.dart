import 'package:coachpro/app/theme/app_colors.dart';
import 'package:coachpro/core/utils/date_format.dart';
import 'package:coachpro/features/sessions/data/sessions_repository.dart';
import 'package:coachpro/features/sessions/domain/session_note.dart';
import 'package:coachpro/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionNotesScreen extends ConsumerWidget {
  const SessionNotesScreen({
    required this.teamId,
    required this.sessionId,
    super.key,
  });

  final String teamId;
  final String sessionId;

  SessionKey get _sessionKey =>
      SessionKey(teamId: teamId, sessionId: sessionId);

  Future<void> _showNoteDialog(
    BuildContext context,
    WidgetRef ref, {
    SessionNote? note,
  }) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final contentController = TextEditingController(text: note?.content ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note == null ? 'Nuova nota' : 'Modifica nota'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Titolo *'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci un titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Contenuto'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) {
      titleController.dispose();
      contentController.dispose();
      return;
    }

    try {
      final repository = ref.read(sessionsRepositoryProvider);
      if (note == null) {
        await repository.addNote(
          teamId: teamId,
          sessionId: sessionId,
          title: titleController.text,
          content: contentController.text,
        );
      } else {
        await repository.updateNote(
          teamId: teamId,
          sessionId: sessionId,
          noteId: note.id,
          title: titleController.text,
          content: contentController.text,
        );
      }
    } on SessionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      titleController.dispose();
      contentController.dispose();
    }
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    SessionNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina nota'),
        content: Text('Eliminare "${note.title}"?'),
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

    if (confirmed != true) {
      return;
    }

    await ref.read(sessionsRepositoryProvider).deleteNote(
          teamId: teamId,
          sessionId: sessionId,
          noteId: note.id,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(sessionNotesProvider(_sessionKey));

    return Scaffold(
      appBar: AppBar(title: const Text('Note')),
      body: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Nessuna nota. Aggiungi osservazioni, programmi o appunti.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                child: ListTile(
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note.content.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(note.content),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        formatSessionDate(note.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  isThreeLine: note.content.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showNoteDialog(context, ref, note: note);
                        case 'delete':
                          _deleteNote(context, ref, note);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifica')),
                      PopupMenuItem(value: 'delete', child: Text('Elimina')),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Errore: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteDialog(context, ref),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuova nota'),
      ),
    );
  }
}
