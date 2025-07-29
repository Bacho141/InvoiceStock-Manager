import 'package:flutter/material.dart';

/// Carte utilisateur pour l'affichage mobile
///
/// Ce widget affiche :
/// - Nom d'utilisateur
/// - Rôle avec icône
/// - Statut avec indicateur visuel
/// - Menu d'actions contextuel
class UserCard extends StatelessWidget {
  final String username;
  final String role;
  final bool isActive;
  final bool hasTempPassword;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onRevealPassword;
  final VoidCallback onCopyPassword;
  final String statusText;

  const UserCard({
    Key? key,
    required this.username,
    required this.role,
    required this.isActive,
    required this.hasTempPassword,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onRevealPassword,
    required this.onCopyPassword,
    required this.statusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20), // Augmenté la hauteur
        child: Column(
          children: [
            // Première ligne : Username + Statut + Menu
            Row(
              children: [
                // Avatar avec initiale
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF7717E8).withOpacity(0.1),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Color(0xFF7717E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Nom d'utilisateur
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),

                // Statut (déplacé en haut à droite)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Menu d'actions
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive ? 'Désactiver' : 'Activer',
                            style: TextStyle(
                              color: isActive ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Deuxième ligne : Rôle
            Row(
              children: [
                Icon(_getRoleIcon(role), size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _getRoleDisplayName(role),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Troisième ligne : Mot de passe avec boutons
            Row(
              children: [
                Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasTempPassword
                        ? '***************'
                        : 'Générer un mot de passe',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton œil pour révéler/modifier
                IconButton(
                  icon: Icon(
                    hasTempPassword ? Icons.visibility : Icons.add,
                    size: 18,
                    color: const Color(0xFF7717E8),
                  ),
                  onPressed: onRevealPassword,
                  tooltip: hasTempPassword
                      ? 'Voir/modifier le mot de passe'
                      : 'Générer un mot de passe',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                // Bouton copie (seulement si mot de passe existe)
                if (hasTempPassword) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 18,
                      color: Color(0xFF7717E8),
                    ),
                    onPressed: onCopyPassword,
                    tooltip: 'Copier le mot de passe',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
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
