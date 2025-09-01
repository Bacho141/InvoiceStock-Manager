// lib/widgets/client/detail/communication_dialog.dart
import 'package:flutter/material.dart';

/// Dialog pour ajouter une communication
class CommunicationDialog extends StatefulWidget {
  const CommunicationDialog({Key? key}) : super(key: key);

  @override
  State<CommunicationDialog> createState() => _CommunicationDialogState();
}

class _CommunicationDialogState extends State<CommunicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'call';

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une communication'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'call',
                  child: Text('Appel téléphonique'),
                ),
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'meeting', child: Text('Rendez-vous')),
                DropdownMenuItem(value: 'letter', child: Text('Courrier')),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Sujet'),
              validator: (value) =>
                  value?.isEmpty == true ? 'Le sujet est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenu'),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty == true ? 'Le contenu est requis' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'type': _selectedType,
                'subject': _subjectController.text,
                'content': _contentController.text,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}