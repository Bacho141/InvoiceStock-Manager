import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/auth_controller.dart';
import '../layout/main_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _role;
  String? _username;
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    final username = prefs.getString('username');
    debugPrint('[SCREEN][DashboardScreen] Rôle chargé: $role');
    debugPrint('[SCREEN][DashboardScreen] Username chargé: $username');
    setState(() {
      _role = role;
      _username = username;
    });
  }

  Future<void> _logout() async {
    // Afficher une boîte de dialogue de confirmation
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
          // En cas d'échec, on force quand même la déconnexion locale
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      } catch (e) {
        debugPrint('[SCREEN][DashboardScreen] Erreur logout: ${e.toString()}');
        // En cas d'erreur, on force quand même la déconnexion locale
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    }
  }

  Widget _buildProfileSection() {
    return Row(
      children: [
        // Cercle de profil avec icône
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
        // Nom d'utilisateur
        Text(
          _username ?? 'Utilisateur',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        // Bouton de déconnexion
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onHover: (isHovered) {
            // Effet de hover pour desktop
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contenu du dashboard
    Widget dashboardContent = _role == null
        ? const Center(child: CircularProgressIndicator())
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7717E8).withOpacity(0.05),
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de bienvenue
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar plus grand
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7717E8), Color(0xFF9C27B0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7717E8,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenue, ${_username ?? ''}!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF7717E8,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF7717E8,
                                      ).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _role ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF7717E8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Section des fonctionnalités
                    Text(
                      'Fonctionnalités disponibles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          // Carte Gestion des Utilisateurs (visible pour tous pour le moment)
                          _buildFeatureCard(
                            icon: Icons.manage_accounts,
                            title: 'Gestion Utilisateurs',
                            subtitle: 'Gérer les comptes',
                            color: const Color(0xFFE91E63),
                            onTap: () {
                              debugPrint(
                                '[SCREEN][DashboardScreen] Navigation vers gestion utilisateurs',
                              );
                              Navigator.of(
                                context,
                              ).pushNamed('/user-management');
                            },
                          ),
                          _buildFeatureCard(
                            icon: Icons.inventory,
                            title: 'Gestion Stock',
                            subtitle: 'Gérer les produits',
                            color: const Color(0xFF4CAF50),
                            onTap: () {
                              debugPrint(
                                '[SCREEN][DashboardScreen] Navigation vers gestion stock',
                              );
                              // TODO: Navigation vers gestion stock
                            },
                          ),
                          _buildFeatureCard(
                            icon: Icons.receipt,
                            title: 'Factures',
                            subtitle: 'Créer des factures',
                            color: const Color(0xFF2196F3),
                            onTap: () {
                              debugPrint(
                                '[SCREEN][DashboardScreen] Navigation vers factures',
                              );
                              // TODO: Navigation vers factures
                            },
                          ),
                          _buildFeatureCard(
                            icon: Icons.people,
                            title: 'Clients',
                            subtitle: 'Gérer les clients',
                            color: const Color(0xFFFF9800),
                            onTap: () {
                              debugPrint(
                                '[SCREEN][DashboardScreen] Navigation vers clients',
                              );
                              // TODO: Navigation vers clients
                            },
                          ),
                          _buildFeatureCard(
                            icon: Icons.analytics,
                            title: 'Rapports',
                            subtitle: 'Voir les statistiques',
                            color: const Color(0xFF9C27B0),
                            onTap: () {
                              debugPrint(
                                '[SCREEN][DashboardScreen] Navigation vers rapports',
                              );
                              // TODO: Navigation vers rapports
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

    // Utiliser MainLayout pour navigation fixe
    return MainLayout(
      currentRoute: '/dashboard',
      pageTitle: 'Tableau de Bord',
      child: dashboardContent,
    );
  }
}
