import 'package:flutter/material.dart';

/// Formulaire modal pour créer ou modifier un utilisateur
///
/// Ce widget affiche :
/// - Champ nom d'utilisateur
/// - Sélecteur de rôle
/// - Boutons d'action
class UserFormModal extends StatefulWidget {
  final String? initialUsername;
  final String? initialRole;
  final bool isEditing;
  final Function(String username, String role) onSubmit;
  final VoidCallback onCancel;

  const UserFormModal({
    Key? key,
    this.initialUsername,
    this.initialRole,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends State<UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String _selectedRole = 'caissier';

  final List<String> _roles = ['caissier', 'gestionnaire', 'super-admin'];

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialUsername ?? '';
    _selectedRole = widget.initialRole ?? 'caissier';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(_usernameController.text.trim(), _selectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width > 500
            ? 400
            : MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Icon(
                    widget.isEditing ? Icons.edit : Icons.person_add,
                    color: const Color(0xFF7717E8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? 'Modifier l\'utilisateur'
                          : 'Créer un nouvel utilisateur',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Champ nom d'utilisateur
              Text(
                'Nom d\'utilisateur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'ex: prenom.nom',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF7717E8),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom d\'utilisateur est requis';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Sélecteur de rôle
              Text(
                'Rôle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          Icon(
                            _getRoleIcon(role),
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(_getRoleDisplayName(role)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Message informatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isEditing
                            ? 'Vous pouvez modifier le rôle de cet utilisateur.'
                            : 'Un mot de passe temporaire sera généré automatiquement.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7717E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.isEditing ? 'Modifier' : 'Créer',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'super-admin':
        return Icons.admin_panel_settings;
      case 'gestionnaire':
        return Icons.manage_accounts;
      case 'caissier':
        return Icons.point_of_sale;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'super-admin':
        return 'Super-Admin';
      case 'gestionnaire':
        return 'Gestionnaire';
      case 'caissier':
        return 'Caissier';
      default:
        return role;
    }
  }
}
