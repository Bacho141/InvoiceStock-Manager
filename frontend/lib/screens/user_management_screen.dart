import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/user_card.dart';
import '../widgets/user_table_row.dart';
import '../widgets/user_form_modal.dart';
import '../widgets/password_reveal_modal.dart';
import '../layout/main_layout.dart';
import '../controllers/user_controller.dart';
import '../models/user.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserController _userController = UserController();

  String search = '';
  String roleFilter = 'Tous';
  String statusFilter = 'Tous';
  bool isEditing = false;
  User? editingUser;

  // Filtres disponibles
  final List<String> roles = [
    'Tous',
    'caissier',
    'gestionnaire',
    'super-admin',
  ];
  final List<String> status = ['Tous', 'Actif', 'Inactif'];

  List<User> get filteredUsers {
    return _userController.filterUsers(
      search: search,
      roleFilter: roleFilter,
      statusFilter: statusFilter,
    );
  }

  void _openCreateUser() {
    setState(() {
      isEditing = false;
      editingUser = null;
    });
    _showUserFormModal();
  }

  void _openEditUser(User user) {
    setState(() {
      isEditing = true;
      editingUser = user;
    });
    _showUserFormModal();
  }

  void _showUserFormModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UserFormModal(
          isEditing: isEditing,
          initialUsername: editingUser?.username,
          initialRole: editingUser?.role,
          onSubmit: (username, role) async {
            await _submitUser(username, role);
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _submitUser(String username, String role) async {
    bool success;
      if (isEditing && editingUser != null) {
        // Modification
      success = await _userController.updateUser(
        editingUser!.id,
        username,
        role,
      );
    } else {
      // Création - le mot de passe sera généré automatiquement
      success = await _userController.createUser(username, role);
    }

    if (success) {
      setState(() {
        editingUser = null;
      });
      _showSuccessMessage(
        isEditing
            ? 'Utilisateur modifié avec succès'
            : 'Utilisateur créé avec succès',
      );
    } else {
      _showErrorMessage(_userController.error ?? 'Erreur lors de l\'opération');
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    bool success = await _userController.toggleUserStatus(
      user.id,
      !user.isActive,
    );
    if (success) {
      _showSuccessMessage('Statut modifié avec succès');
    } else {
      _showErrorMessage(
        _userController.error ?? 'Erreur lors du changement de statut',
      );
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showPasswordRevealModal(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PasswordRevealModal(
          username: user.username,
          onConfirm: (adminPassword, {String? newPassword}) async {
            final result = await _userController.revealPassword(
              user.id,
              adminPassword,
              newPassword: newPassword,
            );
            return result;
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _copyPasswordDirectly(User user) async {
    // Ouvrir un mini-modal pour demander le mot de passe admin
    final adminPassword = await _showAdminPasswordDialog();
    if (adminPassword == null) return;

    try {
      final result = await _userController.revealPassword(
        user.id,
        adminPassword,
      );
      if (result['success']) {
        // Copier le mot de passe dans le presse-papiers
        final tempPassword = result['tempPassword'];
        await Clipboard.setData(ClipboardData(text: tempPassword));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mot de passe copié: $tempPassword'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _showAdminPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entrez votre mot de passe administrateur :'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mot de passe admin',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await _userController.loadUsers();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    // Contenu de l'écran de gestion des utilisateurs
    Widget userManagementContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton de création (desktop)
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openCreateUser,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Créer un utilisateur',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7717E8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filtres et recherche - Responsive
          if (isDesktop) ...[
            // Version desktop - horizontale
            Row(
              children: [
                // Recherche
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rechercher un utilisateur...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => search = value),
                  ),
                ),
                const SizedBox(width: 12),
                // Filtre rôle
                DropdownButton<String>(
                  value: roleFilter,
                  items: roles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text('Rôle : ${_getRoleDisplayName(r)}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => roleFilter = v!),
                ),
                const SizedBox(width: 12),
                // Filtre statut
                DropdownButton<String>(
                  value: statusFilter,
                  items: status
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text('Statut : $s'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => statusFilter = v!),
                ),
              ],
            ),
          ] else ...[
            // Version mobile - verticale
            // Recherche en haut
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un utilisateur...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => search = value),
            ),
            const SizedBox(height: 12),
            // Filtres en dessous
            Row(
              children: [
                // Filtre rôle
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => roleFilter = v!),
                  ),
                ),
                const SizedBox(width: 8),
                // Filtre statut
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: status
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => statusFilter = v!),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          // Gestion du loading et des erreurs
          if (_userController.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7717E8)),
                ),
              ),
            )
          else if (_userController.error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userController.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            )
          else
          // Tableau desktop ou liste mobile
          Expanded(
            child: isDesktop ? _buildDesktopTable() : _buildMobileList(),
          ),
        ],
      ),
    );

    // Utiliser MainLayout pour navigation fixe
    return MainLayout(
      currentRoute: '/user-management',
      pageTitle: 'Gestion des Utilisateurs',
      child: Stack(
        children: [
          userManagementContent,
          // FloatingActionButton pour mobile
          if (!isDesktop)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: _openCreateUser,
                backgroundColor: const Color(0xFF7717E8),
                child: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Créer un utilisateur',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // En-tête du tableau
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Nom d\'utilisateur ▲',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Rôle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Mot de passe',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lignes utilisateurs
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return UserTableRow(
                  username: user.username,
                  role: user.role,
                  isActive: user.isActive,
                  hasTempPassword: user.hasTempPassword,
                  onEdit: () => _openEditUser(user),
                  onToggleStatus: () => _toggleUserStatus(user),
                  onRevealPassword: () => _showPasswordRevealModal(user),
                  onCopyPassword: () => _copyPasswordDirectly(user),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return UserCard(
          username: user.username,
          role: user.role,
          isActive: user.isActive,
          hasTempPassword: user.hasTempPassword,
          statusText: user.isActive ? 'Actif' : 'Inactif',
          onEdit: () => _openEditUser(user),
          onToggleStatus: () => _toggleUserStatus(user),
          onRevealPassword: () => _showPasswordRevealModal(user),
          onCopyPassword: () => _copyPasswordDirectly(user),
        );
      },
    );
  }
}
