import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utiles/api_urls.dart';
import 'package:flutter/foundation.dart';

class ClientService {
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> data) async {
    debugPrint(
      '[SERVICE][ClientService] Tentative de création client: ${data['name']} - ${data['phone']}',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.post(
      Uri.parse(ApiUrls.clients),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    debugPrint(
      '[SERVICE][ClientService] Status: ${response.statusCode}, Body: ${response.body}',
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('[SERVICE][ClientService] Client créé avec succès');
      return jsonDecode(response.body);
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur création client: ${response.body}',
      );
      throw Exception('Erreur création client: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse(ApiUrls.clients),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur chargement clients');
    }
  }

  Future<Map<String, dynamic>> getClientById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur chargement client');
    }
  }

  Future<Map<String, dynamic>> updateClient(
    String id,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.put(
      Uri.parse('${ApiUrls.clients}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur modification client');
    }
  }

  Future<void> deleteClient(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.delete(
      Uri.parse('${ApiUrls.clients}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression client');
    }
  }
}
