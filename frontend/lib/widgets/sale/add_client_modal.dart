import 'package:flutter/material.dart';

class AddClientModal extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;

  const AddClientModal({
    Key? key,
    required this.onCancel,
    required this.onSave,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          maxWidth: 400,
          minHeight: 0,
          maxHeight: 420,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.person_add, color: Color(0xFF7717E8)),
                    SizedBox(width: 8),
                    Text(
                      'Ajouter un nouveau client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nom requis' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Téléphone requis' : null,
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Enregistrer le client',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
