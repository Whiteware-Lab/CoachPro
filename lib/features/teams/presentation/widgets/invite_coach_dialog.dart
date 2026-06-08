import 'package:flutter/material.dart';

Future<String?> showInviteCoachDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _InviteCoachDialog(),
  );
}

class _InviteCoachDialog extends StatefulWidget {
  const _InviteCoachDialog();

  @override
  State<_InviteCoachDialog> createState() => _InviteCoachDialogState();
}

class _InviteCoachDialogState extends State<_InviteCoachDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invita coach'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email del coach',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci un\'email';
            }
            if (!value.contains('@')) {
              return 'Email non valida';
            }
            return null;
          },
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
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: const Text('Invia invito'),
        ),
      ],
    );
  }
}
