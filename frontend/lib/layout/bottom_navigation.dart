import 'package:flutter/material.dart';

/// Barre de navigation du bas pour la version mobile
///
/// Ce widget gère :
/// - Navigation entre les différentes sections
/// - Affichage selon le rôle utilisateur
/// - Indicateurs visuels de la page active
/// - Animations de transition
class BottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  }) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF7717E8),
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: _buildNavigationItems(),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ];

    // Ajouter les éléments selon le rôle
    switch (widget.userRole) {
      case 'super-admin':
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Utilisateurs',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Rapports',
          ),
        ]);
        break;
      case 'gestionnaire':
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Stock',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Factures',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Rapports',
          ),
        ]);
        break;
      case 'caissier':
        items.addAll([
          const BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Caisse',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Factures',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clients',
          ),
        ]);
        break;
    }

    return items;
  }
}
