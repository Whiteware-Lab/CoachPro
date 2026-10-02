import 'package:flutter/material.dart';

Future<String?> showSubSessionNameDialog(
  BuildContext context, {
  required String title,
  String? initialName,
  String fieldLabel = 'Nome prova',
  String hintText = 'Es. 100m, Riscaldamento, Serie 1',
  String confirmLabel = 'Avvia',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _SubSessionNameDialog(
      title: title,
      initialName: initialName,
      fieldLabel: fieldLabel,
      hintText: hintText,
      confirmLabel: confirmLabel,
    ),
  );
}

class _SubSessionNameDialog extends StatefulWidget {
  const _SubSessionNameDialog({
    required this.title,
    this.initialName,
    required this.fieldLabel,
    required this.hintText,
    required this.confirmLabel,
  });

  final String title;
  final String? initialName;
  final String fieldLabel;
  final String hintText;
  final String confirmLabel;

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
          decoration: InputDecoration(
            labelText: widget.fieldLabel,
            hintText: widget.hintText,
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
          child: Text(widget.confirmLabel),
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
