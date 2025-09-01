import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utiles/api_urls.dart';
import '../models/client.dart';
import 'package:flutter/material.dart';
import '../models/client.dart'
    as model; // Import avec alias pour éviter les conflits

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

  // ============ Nouvelles méthodes Analytics (Sprint 2) ============

  /// Récupère les métriques du dashboard clients
  Future<Map<String, dynamic>> getDashboardMetrics() async {
    debugPrint('[SERVICE][ClientService] Récupération métriques dashboard');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/analytics/dashboard'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[SERVICE][ClientService] Métriques récupérées avec succès');
      return data['data'] ?? {};
    } else {
      debugPrint('[SERVICE][ClientService] Erreur métriques: ${response.body}');
      throw Exception('Erreur chargement métriques: ${response.body}');
    }
  }

  /// Récupère le top des clients par chiffre d'affaires
  Future<List<Client>> getTopClients({int limit = 10}) async {
    debugPrint(
      '[SERVICE][ClientService] Récupération top clients (limit: $limit)',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/analytics/top-clients?limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final clientsData = List<Map<String, dynamic>>.from(data['data'] ?? []);
      debugPrint(
        '[SERVICE][ClientService] ${clientsData.length} top clients récupérés',
      );
      return clientsData
          .map((clientData) => Client.fromJson(clientData))
          .toList();
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur top clients: ${response.body}',
      );
      throw Exception('Erreur chargement top clients: ${response.body}');
    }
  }

  /// Récupère l'analyse des créances par ancienneté
  Future<Map<String, dynamic>> getCreancesAnalysis() async {
    debugPrint('[SERVICE][ClientService] Récupération analyse créances');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/analytics/creances'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint(
        '[SERVICE][ClientService] Analyse créances récupérée avec succès',
      );
      return data['data'] ?? {};
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur analyse créances: ${response.body}',
      );
      throw Exception('Erreur chargement analyse créances: ${response.body}');
    }
  }

  /// Récupère les statistiques d'un client spécifique
  Future<Map<String, dynamic>> getClientStats(String clientId) async {
    debugPrint('[SERVICE][ClientService] Récupération stats client: $clientId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/$clientId/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint(
        '[SERVICE][ClientService] Stats client récupérées avec succès',
      );
      return data['data'] ?? {};
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur stats client: ${response.body}',
      );
      throw Exception('Erreur chargement stats client: ${response.body}');
    }
  }

  /// Récupère l'évolution financière d'un client
  Future<List<Map<String, dynamic>>> getClientEvolution(
    String clientId, {
    int months = 12,
  }) async {
    debugPrint(
      '[SERVICE][ClientService] Récupération évolution client: $clientId ($months mois)',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/$clientId/evolution?months=$months'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final evolutionData = List<Map<String, dynamic>>.from(data['data'] ?? []);
      debugPrint(
        '[SERVICE][ClientService] Évolution client récupérée avec succès',
      );
      return evolutionData;
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur évolution client: ${response.body}',
      );
      throw Exception('Erreur chargement évolution client: ${response.body}');
    }
  }

  // ============ Méthodes Créances (Sprint 2) ============

  /// Récupère les clients en retard de paiement
  Future<List<model.Client>> getOverdueClients({int days = 30}) async {
    debugPrint(
      '[SERVICE][ClientService] Récupération clients en retard (${days}j)',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('${ApiUrls.clients}/analytics/overdue?days=$days'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final clientsData = List<Map<String, dynamic>>.from(data['data'] ?? []);
      debugPrint(
        '[SERVICE][ClientService] ${clientsData.length} clients en retard récupérés',
      );
      return clientsData
          .map((clientData) => Client.fromJson(clientData))
          .toList();
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur clients en retard: ${response.body}',
      );
      throw Exception('Erreur chargement clients en retard: ${response.body}');
    }
  }

  /// Récupère les factures en retard de paiement
  Future<List<model.OverdueInvoice>> getOverdueInvoices({int days = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${ApiUrls.clients}/overdue-invoices?days=$days'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        return invoicesData
            .map((invoice) => model.OverdueInvoice.fromJson(invoice))
            .toList();
      } else {
        throw Exception(
          'Échec du chargement des factures en retard: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur dans getOverdueInvoices: $e');
      rethrow;
    }
  }

  /// Récupère les factures en retard de paiement pour un client spécifique
  Future<List<model.OverdueInvoice>> getClientOverdueInvoices(
    String clientId, {
    int days = 30,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final response = await http.get(
        Uri.parse('${ApiUrls.clients}/$clientId/overdue-invoices?days=$days'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        return invoicesData
            .map((invoice) => model.OverdueInvoice.fromJson(invoice))
            .toList();
      } else {
        throw Exception(
          'Échec du chargement des factures en retard du client: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur dans getClientOverdueInvoices: $e');
      rethrow;
    }
  }

  /// Ajoute une communication à l'historique d'un client
  Future<void> addCommunication(
    String clientId,
    Map<String, dynamic> communication,
  ) async {
    debugPrint(
      '[SERVICE][ClientService] Ajout communication client: $clientId',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('${ApiUrls.clients}/$clientId/communication'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(communication),
    );

    if (response.statusCode == 200) {
      debugPrint('[SERVICE][ClientService] Communication ajoutée avec succès');
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur ajout communication: ${response.body}',
      );
      throw Exception('Erreur ajout communication: ${response.body}');
    }
  }

  /// Met à jour le score de crédit d'un client
  Future<Map<String, dynamic>> updateClientScore(String clientId) async {
    debugPrint('[SERVICE][ClientService] Mise à jour score client: $clientId');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final response = await http.put(
      Uri.parse('${ApiUrls.clients}/$clientId/score'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('[SERVICE][ClientService] Score mis à jour avec succès');
      return data;
    } else {
      debugPrint(
        '[SERVICE][ClientService] Erreur mise à jour score: ${response.body}',
      );
      throw Exception('Erreur mise à jour score: ${response.body}');
    }
  }
}
