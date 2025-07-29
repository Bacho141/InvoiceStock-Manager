import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store.dart';
import '../utiles/api_urls.dart';

class StoreService {
  Future<List<Store>> getStores() async {
    debugPrint('[SERVICE][StoreService] Récupération des magasins');
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse(ApiUrls.stores),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[SERVICE][StoreService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stores = (data['data'] as List)
            .map((store) => Store.fromJson(store))
            .toList();
        debugPrint(
          '[SERVICE][StoreService] ${stores.length} magasins récupérés',
        );
        return stores;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[SERVICE][StoreService] Erreur: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la récupération des magasins',
        );
      }
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur: ${e.toString()}');
      rethrow;
    }
  }

  Future<Store> getStoreById(String storeId) async {
    debugPrint('[SERVICE][StoreService] Récupération magasin: $storeId');
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiUrls.stores}/$storeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[SERVICE][StoreService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final store = Store.fromJson(data['data']);
        debugPrint('[SERVICE][StoreService] Magasin récupéré: ${store.name}');
        return store;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[SERVICE][StoreService] Erreur: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la récupération du magasin',
        );
      }
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur: ${e.toString()}');
      rethrow;
    }
  }

  Future<Store> createStore(Map<String, dynamic> storeData) async {
    debugPrint(
      '[SERVICE][StoreService] Création magasin: ${storeData['name']}',
    );
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiUrls.stores),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(storeData),
      );

      debugPrint('[SERVICE][StoreService] Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final store = Store.fromJson(data['data']);
        debugPrint('[SERVICE][StoreService] Magasin créé: ${store.name}');
        return store;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[SERVICE][StoreService] Erreur: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la création du magasin',
        );
      }
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur: ${e.toString()}');
      rethrow;
    }
  }

  Future<Store> updateStore(
    String storeId,
    Map<String, dynamic> storeData,
  ) async {
    debugPrint('[SERVICE][StoreService] Mise à jour magasin: $storeId');
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${ApiUrls.stores}/$storeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(storeData),
      );

      debugPrint('[SERVICE][StoreService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final store = Store.fromJson(data['data']);
        debugPrint('[SERVICE][StoreService] Magasin mis à jour: ${store.name}');
        return store;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[SERVICE][StoreService] Erreur: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la mise à jour du magasin',
        );
      }
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur: ${e.toString()}');
      rethrow;
    }
  }

  Future<bool> toggleStoreStatus(String storeId) async {
    debugPrint('[SERVICE][StoreService] Changement statut magasin: $storeId');
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('${ApiUrls.stores}/$storeId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('[SERVICE][StoreService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('[SERVICE][StoreService] Statut magasin changé avec succès');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('[SERVICE][StoreService] Erreur: ${errorData['message']}');
        throw Exception(
          errorData['message'] ?? 'Erreur lors du changement de statut',
        );
      }
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur: ${e.toString()}');
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('jwt_token');
    } catch (e) {
      debugPrint('[SERVICE][StoreService] Erreur récupération token: $e');
      return null;
    }
  }
}
