import 'package:flutter/material.dart';

/// Barre de navigation du haut pour la version desktop
///
/// Ce widget gère :
/// - Logo et titre de l'application
/// - Menu de navigation horizontal
/// - Profil utilisateur et déconnexion
/// - Notifications et alertes
class TopNavigation extends StatelessWidget {
  final String username;
  final String userRole;
  final VoidCallback onLogout;
  final int currentIndex;
  final Function(int) onNavigationTap;

  const TopNavigation({
    Key? key,
    required this.username,
    required this.userRole,
    required this.onLogout,
    required this.currentIndex,
    required this.onNavigationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo et titre
          _buildLogo(),
          const SizedBox(width: 40),

          // Navigation menu
          Expanded(child: _buildNavigationMenu()),

          // Profil utilisateur
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7717E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.store_mall_directory,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'InvoiceStock',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7717E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu() {
    List<Widget> menuItems = [_buildMenuItem('Dashboard', 0, Icons.dashboard)];

    // Ajouter les éléments selon le rôle
    switch (userRole) {
      case 'super-admin':
        menuItems.addAll([
          _buildMenuItem('Utilisateurs', 1, Icons.people),
          _buildMenuItem('Stock', 2, Icons.inventory),
          _buildMenuItem('Rapports', 3, Icons.analytics),
        ]);
        break;
      case 'gestionnaire':
        menuItems.addAll([
          _buildMenuItem('Stock', 1, Icons.inventory),
          _buildMenuItem('Factures', 2, Icons.receipt),
          _buildMenuItem('Rapports', 3, Icons.analytics),
        ]);
        break;
      case 'caissier':
        menuItems.addAll([
          _buildMenuItem('Caisse', 1, Icons.point_of_sale),
          _buildMenuItem('Factures', 2, Icons.receipt),
          _buildMenuItem('Clients', 3, Icons.people),
        ]);
        break;
    }

    return Row(children: menuItems);
  }

  Widget _buildMenuItem(String label, int index, IconData icon) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => onNavigationTap(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7717E8).withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF7717E8) : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF7717E8)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Afficher les notifications
            },
          ),

          const SizedBox(width: 16),

          // Profil utilisateur
          PopupMenuButton<String>(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF7717E8),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: const Text('Mon profil')),
              PopupMenuItem(value: 'settings', child: const Text('Paramètres')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: const Text('Se déconnecter'),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                onLogout();
              }
              // TODO: Gérer les autres options
            },
          ),
        ],
      ),
    );
  }
}
