import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/store_service.dart'; // NOUVEAU
// NOUVEAU
// NOUVEAU
import 'dart:convert';

class AuthController {
  final AuthService _authService = AuthService();
  final StoreService _storeService = StoreService(); // NOUVEAU

  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('[CONTROLLER][AuthController] Appel login pour $username');
    final result = await _authService.login(username, password);
    final statusCode = result['statusCode'];
    final body = result['body'];
    debugPrint(
      '[CONTROLLER][AuthController] Status: ${statusCode}, Body: ${body}',
    );
    if (statusCode == 200) {
      final data = jsonDecode(body);
      final token = data['token'];
      final userData = data['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('user_role', userData['role']);
      await prefs.setString('username', userData['username']);
      // Ajout stockage ID utilisateur
      await prefs.setString('user_id', userData['id'] ?? userData['_id']);

      // Stocker les magasins assignés
      if (userData['assignedStores'] != null) {
        final storesJson = jsonEncode(userData['assignedStores']);
        await prefs.setString('assigned_stores', storesJson);
        debugPrint(
          '[CONTROLLER][AuthController] Magasins assignés stockés: ${userData['assignedStores'].length}',
        );
      }

      debugPrint(
        '[CONTROLLER][AuthController] Token et rôle stockés pour ${userData['username']} (${userData['role']})',
      );
      return {
        'success': true,
        'role': userData['role'],
        'username': userData['username'],
        'assignedStores': userData['assignedStores'] ?? [], // NOUVEAU
      };
    } else {
      final data = jsonDecode(body);
      debugPrint(
        '[CONTROLLER][AuthController] Échec login: ${data['message']}',
      );
      return {
        'success': false,
        'message': data['message'] ?? 'Identifiants invalides',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    debugPrint('[CONTROLLER][AuthController] Appel logout');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token != null) {
        // Appel au serveur pour invalider la session
        final result = await _authService.logout(token);
        debugPrint(
          '[CONTROLLER][AuthController] Logout serveur: ${result['statusCode']}',
        );
      }

      // Nettoyage des données locales
      await prefs.clear();
      debugPrint('[CONTROLLER][AuthController] Données locales nettoyées');

      return {'success': true, 'message': 'Déconnexion réussie'};
    } catch (e) {
      debugPrint('[CONTROLLER][AuthController] Erreur logout: ${e.toString()}');
      // Même en cas d'erreur, on nettoie les données locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return {'success': true, 'message': 'Déconnexion locale effectuée'};
    }
  }

  Future<Map<String, dynamic>> verifySession() async {
    debugPrint('[CONTROLLER][AuthController] Vérification de session');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        return {'valid': false, 'message': 'Aucun token trouvé'};
      }

      final result = await _authService.verifySession(token);
      final statusCode = result['statusCode'];
      final body = result['body'];

      if (statusCode == 200) {
        final data = jsonDecode(body);
        return {
          'valid': true,
          'user': data['user'],
          'sessionInfo': data['sessionInfo'],
        };
      } else {
        final data = jsonDecode(body);
        return {
          'valid': false,
          'message': data['message'] ?? 'Session invalide',
        };
      }
    } catch (e) {
      debugPrint(
        '[CONTROLLER][AuthController] Erreur vérification: ${e.toString()}',
      );
      return {'valid': false, 'message': 'Erreur de vérification'};
    }
  }
}
