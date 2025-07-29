import 'package:flutter/material.dart';

/// Ligne du tableau utilisateur pour l'affichage desktop
///
/// Ce widget affiche :
/// - Nom d'utilisateur
/// - Rôle avec icône
/// - Statut avec indicateur visuel
/// - Boutons d'actions
class UserTableRow extends StatelessWidget {
  final String username;
  final String role;
  final bool isActive;
  final bool hasTempPassword;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onRevealPassword;
  final VoidCallback onCopyPassword;

  const UserTableRow({
    Key? key,
    required this.username,
    required this.role,
    required this.isActive,
    required this.hasTempPassword,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onRevealPassword,
    required this.onCopyPassword,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Nom d'utilisateur
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF7717E8).withOpacity(0.1),
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF7717E8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),

            // Rôle
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(_getRoleIcon(role), size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            // Mot de passe
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    hasTempPassword
                        ? '***************'
                        : 'Générer un mot de passe',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 8),
                  // Bouton œil pour révéler/modifier
                  IconButton(
                    icon: Icon(
                      hasTempPassword ? Icons.visibility : Icons.add,
                      size: 16,
                      color: const Color(0xFF7717E8),
                    ),
                    onPressed: onRevealPassword,
                    tooltip: hasTempPassword
                        ? 'Voir/modifier le mot de passe'
                        : 'Générer un mot de passe',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                  // Bouton copie (seulement si mot de passe existe)
                  if (hasTempPassword) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Color(0xFF7717E8),
                      ),
                      onPressed: onCopyPassword,
                      tooltip: 'Copier le mot de passe',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Statut
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  // Bouton Modifier
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF7717E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0xFF7717E8),
                      ),
                      onPressed: onEdit,
                      tooltip: 'Modifier',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bouton Activer/Désactiver
                  Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 16,
                        color: isActive ? Colors.red : Colors.green,
                      ),
                      onPressed: onToggleStatus,
                      tooltip: isActive ? 'Désactiver' : 'Activer',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
