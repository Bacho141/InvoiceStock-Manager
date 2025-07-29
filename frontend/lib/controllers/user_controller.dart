import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserController {
  final UserService _userService = UserService();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Récupérer le token depuis le stockage local
  Future<String?> _getToken() async {
    debugPrint('[CONTROLLER][UserController] Récupération du token');
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Charger la liste des utilisateurs
  Future<void> loadUsers() async {
    debugPrint('[CONTROLLER][UserController] Chargement des utilisateurs');
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final result = await _userService.getUsers(token);

      if (result['statusCode'] == 200) {
        debugPrint(
          '[CONTROLLER][UserController] Réponse reçue: ${result['body']}',
        );
        final List<dynamic> usersData = jsonDecode(result['body']);
        debugPrint('[CONTROLLER][UserController] Données parsées: $usersData');

        _users = usersData.map((data) {
          try {
            return User.fromJson(data as Map<String, dynamic>);
          } catch (e) {
            debugPrint('[CONTROLLER][UserController] Erreur parsing user: $e');
            debugPrint(
              '[CONTROLLER][UserController] Données problématiques: $data',
            );
            rethrow;
          }
        }).toList();

        debugPrint(
          '[CONTROLLER][UserController] ${_users.length} utilisateurs chargés',
        );
      } else {
        final errorData = jsonDecode(result['body']);
        throw Exception(errorData['message'] ?? 'Erreur lors du chargement');
      }
    } catch (e) {
      debugPrint('[CONTROLLER][UserController] Erreur: ${e.toString()}');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Créer un nouvel utilisateur
  Future<bool> createUser(String username, String role) async {
    debugPrint('[CONTROLLER][UserController] Création utilisateur: $username');
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final result = await _userService.createUser(token, username, role);

      if (result['statusCode'] == 201) {
        debugPrint('[CONTROLLER][UserController] Utilisateur créé avec succès');
        // Recharger la liste pour avoir les données à jour
        await loadUsers();
        return true;
      } else {
        final errorData = jsonDecode(result['body']);
        throw Exception(errorData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      debugPrint('[CONTROLLER][UserController] Erreur: ${e.toString()}');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Modifier un utilisateur
  Future<bool> updateUser(String userId, String username, String role) async {
    debugPrint(
      '[CONTROLLER][UserController] Modification utilisateur: $userId',
    );
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final result = await _userService.updateUser(
        token,
        userId,
        username,
        role,
      );

      if (result['statusCode'] == 200) {
        debugPrint(
          '[CONTROLLER][UserController] Utilisateur modifié avec succès',
        );
        // Recharger la liste pour avoir les données à jour
        await loadUsers();
        return true;
      } else {
        final errorData = jsonDecode(result['body']);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la modification',
        );
      }
    } catch (e) {
      debugPrint('[CONTROLLER][UserController] Erreur: ${e.toString()}');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Changer le statut d'un utilisateur
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    debugPrint(
      '[CONTROLLER][UserController] Changement statut: $userId -> $isActive',
    );
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final result = await _userService.toggleUserStatus(
        token,
        userId,
        isActive,
      );

      if (result['statusCode'] == 200) {
        debugPrint('[CONTROLLER][UserController] Statut modifié avec succès');
        // Recharger la liste pour avoir les données à jour
        await loadUsers();
        return true;
      } else {
        final errorData = jsonDecode(result['body']);
        throw Exception(
          errorData['message'] ?? 'Erreur lors du changement de statut',
        );
      }
    } catch (e) {
      debugPrint('[CONTROLLER][UserController] Erreur: ${e.toString()}');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Révéler/modifier le mot de passe d'un utilisateur
  Future<Map<String, dynamic>> revealPassword(
    String userId,
    String adminPassword, {
    String? newPassword,
  }) async {
    debugPrint('[CONTROLLER][UserController] Révélation mot de passe: $userId');
    _setLoading(true);
    _clearError();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final result = await _userService.revealPassword(
        token,
        userId,
        adminPassword,
        newPassword: newPassword,
      );

      if (result['statusCode'] == 200) {
        debugPrint(
          '[CONTROLLER][UserController] Mot de passe révélé avec succès',
        );
        final responseData = jsonDecode(result['body']);
        return {
          'success': true,
          'tempPassword': responseData['tempPassword'],
          'message': responseData['message'],
        };
      } else {
        final errorData = jsonDecode(result['body']);
        throw Exception(errorData['message'] ?? 'Erreur lors de la révélation');
      }
    } catch (e) {
      debugPrint('[CONTROLLER][UserController] Erreur: ${e.toString()}');
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  // Filtrer les utilisateurs
  List<User> filterUsers({
    String search = '',
    String roleFilter = 'Tous',
    String statusFilter = 'Tous',
  }) {
    return _users.where((user) {
      final matchesSearch =
          search.isEmpty ||
          user.username.toLowerCase().contains(search.toLowerCase());
      final matchesRole = roleFilter == 'Tous' || user.role == roleFilter;
      final matchesStatus =
          statusFilter == 'Tous' ||
          (statusFilter == 'Actif' ? user.isActive : !user.isActive);
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  // Méthodes privées pour la gestion d'état
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
  }

  void _clearError() {
    _error = null;
  }
}
