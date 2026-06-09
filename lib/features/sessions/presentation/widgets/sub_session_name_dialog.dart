import 'package:flutter/material.dart';

Future<String?> showSubSessionNameDialog(
  BuildContext context, {
  required String title,
  String? initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SubSessionNameDialog(
      title: title,
      initialName: initialName,
    ),
  );
}

class _SubSessionNameDialog extends StatefulWidget {
  const _SubSessionNameDialog({
    required this.title,
    this.initialName,
  });

  final String title;
  final String? initialName;

  @override
  State<_SubSessionNameDialog> createState() => _SubSessionNameDialogState();
}

class _SubSessionNameDialogState extends State<_SubSessionNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome prova',
            hintText: 'Es. 100m, Riscaldamento, Serie 1',
          ),
          textCapitalization: TextCapitalization.sentences,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Inserisci un nome';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Avvia'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }
}
