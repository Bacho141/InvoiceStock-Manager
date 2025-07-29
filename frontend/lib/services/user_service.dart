import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utiles/api_urls.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // Récupérer la liste des utilisateurs
  Future<Map<String, dynamic>> getUsers(String token) async {
    debugPrint(
      '[SERVICE][UserService] Récupération de la liste des utilisateurs',
    );
    try {
      final response = await http.get(
        Uri.parse(ApiUrls.users),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('[SERVICE][UserService] Status: ${response.statusCode}');
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][UserService] Erreur lors de la récupération: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Créer un nouvel utilisateur
  Future<Map<String, dynamic>> createUser(
    String token,
    String username,
    String role,
  ) async {
    debugPrint('[SERVICE][UserService] Création utilisateur: $username');
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.users),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': username, 'role': role}),
      );
      debugPrint('[SERVICE][UserService] Status: ${response.statusCode}');
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][UserService] Erreur lors de la création: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Modifier un utilisateur
  Future<Map<String, dynamic>> updateUser(
    String token,
    String userId,
    String username,
    String role,
  ) async {
    debugPrint('[SERVICE][UserService] Modification utilisateur: $userId');
    try {
      final response = await http.put(
        Uri.parse('${ApiUrls.users}/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'username': username, 'role': role}),
      );
      debugPrint('[SERVICE][UserService] Status: ${response.statusCode}');
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][UserService] Erreur lors de la modification: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Activer/désactiver un utilisateur
  Future<Map<String, dynamic>> toggleUserStatus(
    String token,
    String userId,
    bool isActive,
  ) async {
    debugPrint(
      '[SERVICE][UserService] Changement statut utilisateur: $userId -> $isActive',
    );
    try {
      final response = await http.patch(
        Uri.parse('${ApiUrls.users}/$userId/activate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'isActive': isActive}),
      );
      debugPrint('[SERVICE][UserService] Status: ${response.statusCode}');
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][UserService] Erreur lors du changement de statut: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Révéler/modifier le mot de passe d'un utilisateur
  Future<Map<String, dynamic>> revealPassword(
    String token,
    String userId,
    String adminPassword, {
    String? newPassword,
  }) async {
    debugPrint(
      '[SERVICE][UserService] Révélation mot de passe utilisateur: $userId',
    );
    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.users}/$userId/reveal-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'adminPassword': adminPassword,
          if (newPassword != null) 'newPassword': newPassword,
        }),
      );
      debugPrint('[SERVICE][UserService] Status: ${response.statusCode}');
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][UserService] Erreur lors de la révélation: ${e.toString()}',
      );
      rethrow;
    }
  }
}
