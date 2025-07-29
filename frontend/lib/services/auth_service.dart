import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utiles/api_urls.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    debugPrint('[SERVICE][AuthService] Tentative de login pour $username');
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      debugPrint(
        '[SERVICE][AuthService] Status: ${response.statusCode}, Body: ${response.body}',
      );
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][AuthService] Erreur lors du login: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> logout(String token) async {
    debugPrint('[SERVICE][AuthService] Tentative de déconnexion');
    try {
      final response = await http.post(
        Uri.parse(ApiUrls.logout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint(
        '[SERVICE][AuthService] Status: ${response.statusCode}, Body: ${response.body}',
      );
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][AuthService] Erreur lors de la déconnexion: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifySession(String token) async {
    debugPrint('[SERVICE][AuthService] Vérification de session');
    try {
      final response = await http.get(
        Uri.parse(ApiUrls.verifySession),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint(
        '[SERVICE][AuthService] Status: ${response.statusCode}, Body: ${response.body}',
      );
      return {'statusCode': response.statusCode, 'body': response.body};
    } catch (e) {
      debugPrint(
        '[SERVICE][AuthService] Erreur lors de la vérification: ${e.toString()}',
      );
      rethrow;
    }
  }
}
