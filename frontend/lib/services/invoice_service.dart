import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utiles/api_urls.dart';
import 'package:flutter/foundation.dart';

class InvoiceService {
  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    debugPrint(
      '[SERVICE][InvoiceService] Tentative de création facture: ${jsonEncode(data)}',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.post(
      Uri.parse(ApiUrls.invoices),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    debugPrint(
      '[SERVICE][InvoiceService] Status: ${response.statusCode}, Body: ${response.body}',
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('[SERVICE][InvoiceService] Facture créée avec succès');
      return jsonDecode(response.body);
    } else {
      debugPrint(
        '[SERVICE][InvoiceService] Erreur création facture: ${response.body}',
      );
      throw Exception('Erreur création facture: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices({
    Map<String, String>? filters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final uri = Uri.parse(ApiUrls.invoices).replace(queryParameters: filters);
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur chargement factures');
    }
  }

  Future<Map<String, dynamic>> getInvoiceById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.get(
      Uri.parse('${ApiUrls.invoices}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur chargement facture');
    }
  }

  Future<Map<String, dynamic>> updateInvoice(
    String id,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.put(
      Uri.parse('${ApiUrls.invoices}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur modification facture');
    }
  }

  Future<void> cancelInvoice(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.delete(
      Uri.parse('${ApiUrls.invoices}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur annulation facture');
    }
  }

  Future<void> setInvoiceOnHold(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.post(
      Uri.parse('${ApiUrls.invoices}/$id/wait'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise en attente facture');
    }
  }
}
