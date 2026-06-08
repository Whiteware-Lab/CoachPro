import 'package:coachpro/features/athletes/domain/athlete.dart';
import 'package:flutter/material.dart';

class AthleteFormData {
  const AthleteFormData({
    required this.name,
    this.bibNumber,
    this.notes,
  });

  final String name;
  final String? bibNumber;
  final String? notes;
}

Future<AthleteFormData?> showAthleteFormDialog(
  BuildContext context, {
  Athlete? athlete,
}) {
  return showDialog<AthleteFormData>(
    context: context,
    builder: (context) => _AthleteFormDialog(athlete: athlete),
  );
}

class _AthleteFormDialog extends StatefulWidget {
  const _AthleteFormDialog({this.athlete});

  final Athlete? athlete;

  @override
  State<_AthleteFormDialog> createState() => _AthleteFormDialogState();
}

class _AthleteFormDialogState extends State<_AthleteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bibController;
  late final TextEditingController _notesController;

  bool get _isEditing => widget.athlete != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.athlete?.name ?? '');
    _bibController =
        TextEditingController(text: widget.athlete?.bibNumber ?? '');
    _notesController = TextEditingController(text: widget.athlete?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bibController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Modifica atleta' : 'Nuovo atleta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome *',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci il nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bibController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Pettorale',
                hintText: 'Opzionale',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Opzionale',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                AthleteFormData(
                  name: _nameController.text.trim(),
                  bibNumber: _bibController.text.trim(),
                  notes: _notesController.text.trim(),
                ),
              );
            }
          },
          child: Text(_isEditing ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }
}
