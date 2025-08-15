import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../utiles/api_urls.dart';
import 'stock_service.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    debugPrint('[ProductService][getProducts] URL: ${ApiUrls.products}');
    debugPrint(
      '[ProductService][getProducts] Token: ${token != null ? token.substring(0, 8) + '...' : 'null'}',
    );
    final response = await http.get(
      Uri.parse(ApiUrls.products),
      headers: {'Authorization': 'Bearer $token'},
    );
    debugPrint('[ProductService][getProducts] Status: ${response.statusCode}');
    debugPrint('[ProductService][getProducts] Body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List productsJson = data['data'] ?? [];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      try {
        final data = jsonDecode(response.body);
        debugPrint(
          '[ProductService][getProducts][ERROR] Message: ${data['message'] ?? ''}',
        );
      } catch (_) {}
      throw Exception('Erreur chargement produits');
    }
  }

  /// Récupère tous les produits avec leur stock agrégé sur tous les magasins accessibles.
  Future<List<Map<String, dynamic>>> getProductsWithAggregatedStock() async {
    debugPrint('[ProductService][getProductsWithAggregatedStock] Chargement produits avec stock agrégé');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final url = '${ApiUrls.products}/all-with-stock';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        debugPrint('[ProductService][getProductsWithAggregatedStock] Raw response: ${response.body}');
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        debugPrint('[ProductService][getProductsWithAggregatedStock] Erreur: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur chargement produits avec stock agrégé: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ProductService][getProductsWithAggregatedStock] Erreur: $e');
      throw Exception('Erreur chargement produits avec stock agrégé: $e');
    }
  }

  /// Récupère les produits enrichis avec les données de stock pour un magasin spécifique
  Future<List<Map<String, dynamic>>> getProductsWithStock(String storeId) async {
    debugPrint('[ProductService][getProductsWithStock] Chargement produits avec stock pour magasin $storeId');
    
    if (storeId == 'all') {
      return getProductsWithAggregatedStock();
    }

    try {
      // Récupérer les produits
      final products = await getProducts();
      final stockService = StockService();
      final enrichedProducts = <Map<String, dynamic>>[];
      
      // Enrichir chaque produit avec ses données de stock
      for (final product in products) {
        try {
          final stockData = await stockService.getProductStock(storeId, product.id ?? '');
          
          enrichedProducts.add({
            'product': product,
            'stockQuantity': stockData['quantity'] ?? 0,
            'reservedQuantity': stockData['reserved'] ?? 0,
            'availableQuantity': (stockData['quantity'] ?? 0) - (stockData['reserved'] ?? 0),
            'isAvailable': ((stockData['quantity'] ?? 0) - (stockData['reserved'] ?? 0)) > 0,
            'isLowStock': (stockData['quantity'] ?? 0) <= (stockData['minThreshold'] ?? 5),
            'lastMovement': stockData['lastMovement'],
          });
        } catch (e) {
          // Si erreur récupération stock, considérer comme non disponible
          debugPrint('[ProductService][getProductsWithStock] Erreur stock pour produit ${product.id}: $e');
          enrichedProducts.add({
            'product': product,
            'stockQuantity': 0,
            'reservedQuantity': 0,
            'availableQuantity': 0,
            'isAvailable': false,
            'isLowStock': true,
            'lastMovement': null,
          });
        }
      }
      
      debugPrint('[ProductService][getProductsWithStock] ${enrichedProducts.length} produits enrichis');
      return enrichedProducts;
    } catch (e) {
      debugPrint('[ProductService][getProductsWithStock] Erreur: $e');
      throw Exception('Erreur chargement produits avec stock: $e');
    }
  }

  /// Vérifie la disponibilité d'un produit avant ajout au panier
  Future<Map<String, dynamic>> checkProductAvailability(
    String storeId,
    String productId,
    int requestedQuantity,
  ) async {
    debugPrint(
      '[ProductService][checkProductAvailability] Vérification produit $productId, quantité $requestedQuantity',
    );
    
    try {
      final stockService = StockService();
      final availability = await stockService.checkStockAvailability(
        storeId,
        productId,
        requestedQuantity,
      );
      debugPrint('[DEBUG][ProductService][checkProductAvailability] Response: '
          'storeId=$storeId, productId=$productId, requestedQuantity=$requestedQuantity, availability=$availability');
      return {
        'isAvailable': availability['available'] ?? false,
        'availableQuantity': availability['availableQuantity'] ?? 0,
        'requestedQuantity': requestedQuantity,
        'message': availability['message'] ?? '',
      };
    } catch (e) {
      debugPrint('[ProductService][checkProductAvailability] Erreur: $e');
      return {
        'isAvailable': false,
        'availableQuantity': 0,
        'requestedQuantity': requestedQuantity,
        'message': 'Erreur vérification disponibilité',
      };
    }
  }

  Future<Product> addProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.post(
      Uri.parse(ApiUrls.products),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['data']);
    } else {
      throw Exception('Erreur création produit');
    }
  }

  Future<Product> updateProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.put(
      Uri.parse('${ApiUrls.products}/${product.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Product.fromJson(data['data']);
    } else {
      throw Exception('Erreur modification produit');
    }
  }

  Future<void> deleteProduct(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.delete(
      Uri.parse('${ApiUrls.products}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur suppression produit');
    }
  }
}
