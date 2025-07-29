import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // NOUVEAU
import '../controllers/auth_controller.dart';
import '../widgets/store_selector.dart'; // NOUVEAU
import '../models/store.dart'; // NOUVEAU
import '../screens/stock/stocks_screen.dart'; // NOUVEAU

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final String pageTitle;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
    required this.pageTitle,
  }) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String? _role;
  String? _username;
  Store? _currentStore; // NOUVEAU
  int _buildCount = 0;
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les infos utilisateur quand les dépendances changent
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final username = prefs.getString('username');
    debugPrint('[LAYOUT][MainLayout] Rôle chargé: "$role"');
    debugPrint('[LAYOUT][MainLayout] Username chargé: "$username"');
    debugPrint('[LAYOUT][MainLayout] Longueur du rôle:  {role?.length}');
    debugPrint('[LAYOUT][MainLayout] Code ASCII du rôle:  {role?.codeUnits}');

    // Charger le magasin actuel
    final storesJson = prefs.getString('assigned_stores');
    final selectedStoreId = prefs.getString('selected_store_id');
    if (storesJson != null) {
      try {
        debugPrint('[LAYOUT][MainLayout] storesJson: $storesJson');
        final storesList = jsonDecode(storesJson) as List;
        debugPrint('[LAYOUT][MainLayout] storesList: $storesList');
        debugPrint(
          '[LAYOUT][MainLayout] storesList.length: ${storesList.length}',
        );
        Store? selectedStore;
        if (storesList.isNotEmpty) {
          // Chercher le magasin sélectionné
          if (selectedStoreId != null) {
            for (final s in storesList) {
              if ((s['_id'] ?? s['id']).toString() == selectedStoreId) {
                selectedStore = Store.fromJson(s);
                break;
              }
            }
          }
          // Si pas trouvé, prendre le premier
          selectedStore ??= Store.fromJson(storesList.first);
          _currentStore = selectedStore;
          debugPrint(
            '[LAYOUT][MainLayout] Magasin actuel: ${selectedStore.name}',
          );
        }
      } catch (e, stackTrace) {
        debugPrint('[LAYOUT][MainLayout] Erreur chargement magasin: $e');
        debugPrint('[LAYOUT][MainLayout] Stack trace: $stackTrace');
        debugPrint('[LAYOUT][MainLayout] storesJson: $storesJson');
        _currentStore = null;
      }
    } else {
      debugPrint(
        '[LAYOUT][MainLayout] Aucun magasin trouvé dans SharedPreferences',
      );
    }

    setState(() {
      _role = role;
      _username = username;
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final result = await _authController.logout();
        if (result['success'] == true) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    }
  }

  // Méthode pour gérer le changement de magasin
  void _onStoreChanged(Store newStore) async {
    setState(() {
      _currentStore = newStore;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_store_id', newStore.id);
    debugPrint('[LAYOUT][MainLayout] Magasin changé vers: ${newStore.name}');
    // TODO: Recharger les données du dashboard avec le nouveau magasin
  }

  List<NavigationItem> _getNavigationItems() {
    debugPrint(
      '[LAYOUT][MainLayout] Génération navigation pour rôle: "$_role"',
    );
    debugPrint('[LAYOUT][MainLayout] Type de _role: ${_role.runtimeType}');
    debugPrint(
      '[LAYOUT][MainLayout] _role == "super-admin": ${_role == "super-admin"}',
    );
    debugPrint(
      '[LAYOUT][MainLayout] _role == "caissier": ${_role == "caissier"}',
    );
    debugPrint(
      '[LAYOUT][MainLayout] _role == "gestionnaire": ${_role == "gestionnaire"}',
    );

    final isDesktop = MediaQuery.of(context).size.width > 700;

    List<NavigationItem> items = [
      NavigationItem(
        icon: Icons.dashboard,
        label: 'Tableau de Bord',
        route: '/dashboard',
      ),
      NavigationItem(
        icon: Icons.add_shopping_cart,
        label: 'Vente',
        route: '/new-sale',
      ),
    ];

    // Ajouter les éléments selon le rôle
    if (_role == 'caissier') {
      debugPrint('[LAYOUT][MainLayout] Ajout options Caissier');
      items.addAll([
        NavigationItem(
          icon: Icons.receipt,
          label: 'Factures',
          route: '/invoices',
        ),
      ]);
    }

    if (_role == 'gestionnaire') {
      debugPrint('[LAYOUT][MainLayout] Ajout options Gestionnaire');
      items.addAll([
        NavigationItem(
          icon: Icons.receipt,
          label: 'Factures',
          route: '/invoices',
        ),
        NavigationItem(
          icon: Icons.inventory,
          label: 'Produits',
          route: '/products',
        ),
      ]);
    }

    if (_role == 'super-admin') {
      debugPrint('[LAYOUT][MainLayout] Ajout options Super-Admin');
      if (isDesktop) {
        // Desktop : Tous les éléments dans la sidebar
        items.addAll([
          NavigationItem(
            icon: Icons.analytics,
            label: 'Rapports',
            route: '/reports',
          ),
          NavigationItem(
            icon: Icons.receipt,
            label: 'Factures',
            route: '/invoices',
          ),
          NavigationItem(
            icon: Icons.inventory,
            label: 'Produits',
            route: '/products',
          ),
          NavigationItem(
            icon: Icons.inventory_2,
            label: 'Stocks',
            route: '/stocks',
          ),
          NavigationItem(
            icon: Icons.manage_accounts,
            label: 'Utilisateurs',
            route: '/user-management',
          ),
          NavigationItem(
            icon: Icons.settings,
            label: 'Paramètres',
            route: '/settings',
          ),
        ]);
      } else {
        // Mobile : Seulement les 3 premiers + Menu
        items.addAll([
          NavigationItem(
            icon: Icons.analytics,
            label: 'Rapports',
            route: '/reports',
          ),
          NavigationItem(
            icon: Icons.more_vert,
            label: 'Menu',
            route: '/drawer',
          ),
        ]);
      }
    }

    items.addAll([
      NavigationItem(icon: Icons.person, label: 'Clients', route: '/clients'),
    ]);

    debugPrint(
      '[LAYOUT][MainLayout] Nombre total d\'éléments: ${items.length}',
    );
    return items;
  }

  void _showDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF7717E8).withOpacity(0.75),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Header avec logo
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory,
                      color: Color(0xFF7717E8),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Titre
                  const Text(
                    'Menu Principal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Bouton fermer
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            // Options du menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildDrawerMenuItem(
                    icon: Icons.receipt,
                    label: 'Factures',
                    route: '/invoices',
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.inventory,
                    label: 'Produits',
                    route: '/products',
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.inventory_2,
                    label: 'Stocks',
                    route: '/stocks',
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.manage_accounts,
                    label: 'Utilisateurs',
                    route: '/user-management',
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.settings,
                    label: 'Paramètres',
                    route: '/settings',
                  ),
                  _buildDrawerMenuItem(
                    icon: Icons.person,
                    label: 'Clients',
                    route: '/clients',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushReplacementNamed(route);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCurrentPageTitle() {
    final route = ModalRoute.of(context)?.settings.name;
    switch (route) {
      case '/dashboard':
        return 'Tableau de Bord';
      case '/new-sale':
        return 'Nouvelle Vente';
      case '/invoices':
        return 'Factures';
      case '/products':
        return 'Produits';
      case '/stocks':
        return 'Stocks';
      case '/reports':
        return 'Rapports';
      case '/user-management':
        return 'Gestion des Utilisateurs';
      case '/settings':
        return 'Paramètres';
      default:
        return 'InvoiceStock Manager';
    }
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7717E8), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          _username ?? 'Utilisateur',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    debugPrint(
      '[LAYOUT][MainLayout][build] buildCount: $_buildCount, currentStore: ${_currentStore?.id} - ${_currentStore?.name}',
    );
    final navigationItems = _getNavigationItems();
    final isDesktop = MediaQuery.of(context).size.width > 700;

    if (isDesktop) {
      // Layout Desktop : Sidebar au-dessus + AppBar personnalisé + Contenu
      return Scaffold(
        body: Stack(
          children: [
            // Zone de contenu principal décalée (en arrière-plan)
            Positioned(
              left: 200,
              top: 60, // Commence après l'AppBar personnalisé
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Sélecteur de magasin (si multi-magasins)
                    StoreSelector(
                      currentStore: _currentStore,
                      onStoreChanged: _onStoreChanged,
                    ),
                    const SizedBox(height: 16),
                    // Contenu de la page
                    Expanded(
                      child: widget.currentRoute == '/stocks'
                          ? StocksScreen(
                              key: ValueKey(_currentStore?.id),
                              currentStore: _currentStore,
                            )
                          : widget.child,
                    ),
                  ],
                ),
              ),
            ),
            // AppBar personnalisé (en arrière-plan de la SideBar)
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF7717E8),
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
                    // Espace pour la SideBar
                    const SizedBox(width: 200),
                    // Titre de la page
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Text(
                        _getCurrentPageTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Profil utilisateur
                    _buildProfileSection(),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            // Sidebar complète au-dessus de tout (z-index le plus élevé)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF7717E8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo en haut de la sidebar (au-dessus de l'AppBar)
                    Container(
                      height: 60, // Hauteur de l'AppBar
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Logo
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory,
                              color: Color(0xFF7717E8),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Titre
                          Expanded(
                            child: Text(
                              'InvoiceStock',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = navigationItems[index];
                          final isActive = widget.currentRoute == item.route;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  if (!isActive) {
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed(item.route);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        item.icon,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: isActive
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Layout Mobile : AppBar + Contenu + BottomBar
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.pageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          backgroundColor: const Color(0xFF7717E8),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            // Profil utilisateur
            _buildProfileSection(),
            const SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // Sélecteur de magasin (si multi-magasins)
            StoreSelector(
              currentStore: _currentStore,
              onStoreChanged: _onStoreChanged,
            ),
            // Contenu de la page
            Expanded(
              child: widget.currentRoute == '/stocks'
                  ? StocksScreen(
                      key: ValueKey(_currentStore?.id),
                      currentStore: _currentStore,
                    )
                  : widget.child,
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7717E8),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = widget.currentRoute == item.route;

                  return GestureDetector(
                    onTap: () {
                      if (item.route == '/drawer') {
                        _showDrawer();
                      } else if (widget.currentRoute != item.route) {
                        Navigator.of(context).pushReplacementNamed(item.route);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
