import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utiles/api_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getTokenFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('jwt_token');
}

class StockService {
  /// Récupère la liste des stocks d'un magasin
  Future<List<Map<String, dynamic>>> getStocks(
    String storeId, {
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Chargement des stocks pour store $storeId',
    );
    final uri = Uri.parse(ApiUrls.stocksByStore(storeId)).replace(
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur lors de la récupération des stocks');
    }
  }

  /// Ajuste le stock d'un produit dans un magasin
  Future<bool> adjustStock(
    String storeId,
    String productId,
    int newQuantity,
    String reason,
  ) async {
    debugPrint(
      '[SERVICE][StockService] Ajustement du stock produit $productId magasin $storeId',
    );
    final url = Uri.parse(ApiUrls.adjustStock(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'newQuantity': newQuantity,
        'reason': reason,
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }

  /// Transfère du stock entre deux magasins
  Future<bool> transferStock({
    required String productId,
    required String fromStoreId,
    required String toStoreId,
    required int quantity,
    String? reason,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Transfert de $quantity du produit $productId de $fromStoreId vers $toStoreId',
    );
    final url = Uri.parse(ApiUrls.transferStock);
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'fromStoreId': fromStoreId,
        'toStoreId': toStoreId,
        'quantity': quantity,
        'reason': reason ?? '',
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }

  /// Récupère l'historique des mouvements d'un produit dans un magasin (avec filtres)
  Future<List<Map<String, dynamic>>> getProductMovements(
    String storeId,
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? type,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Historique mouvements produit $productId magasin $storeId',
    );
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate.toIso8601String();
    if (endDate != null) params['endDate'] = endDate.toIso8601String();
    if (userId != null) params['userId'] = userId;
    if (type != null) params['type'] = type;
    final uri = Uri.parse(
      ApiUrls.productMovements(storeId, productId),
    ).replace(queryParameters: params);
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      throw Exception('Erreur lors de la récupération de l\'historique');
    }
  }

  /// Récupère les alertes de stock d'un magasin
  Future<List<Map<String, dynamic>>> getStockAlerts(String storeId) async {
    debugPrint(
      '[SERVICE][StockService] Récupération des alertes pour store $storeId',
    );
    final url = Uri.parse(ApiUrls.stockAlerts(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      throw Exception('Erreur lors de la récupération des alertes');
    }
  }

  /// Récupère les indicateurs clés d'un magasin
  Future<Map<String, dynamic>> getStockIndicators(String storeId) async {
    debugPrint(
      '[SERVICE][StockService] Récupération des indicateurs pour store $storeId',
    );
    final url = Uri.parse(ApiUrls.stockIndicators(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(url, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      throw Exception('Erreur lors de la récupération des indicateurs');
    }
  }

  /// Récupère tous les stocks (tous magasins)
  Future<List<Map<String, dynamic>>> listStocks() async {
    debugPrint('[SERVICE][StockService] Récupération de tous les stocks');
    final uri = Uri.parse(ApiUrls.listStocks);
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final storeId = data['storeId'];
      if (storeId == null || storeId == 'default') {
        debugPrint(
          '[SERVICE][StockService] ERREUR: storeId absent ou invalide (reçu: "$storeId")',
        );
        throw Exception(
          'Aucun magasin sélectionné ou storeId invalide. Veuillez sélectionner un magasin avant de poursuivre.',
        );
      }
      return List<Map<String, dynamic>>.from(
        data['stocks'] ?? data['data'] ?? [],
      );
    } else {
      throw Exception('Erreur lors de la récupération de tous les stocks');
    }
  }

  /// Récupère les indicateurs globaux (tous magasins)
  Future<Map<String, dynamic>> getGlobalIndicators() async {
    debugPrint('[SERVICE][StockService] Récupération des indicateurs globaux');
    final uri = Uri.parse(ApiUrls.listStocks);
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['indicateurs'] ?? {});
    } else {
      throw Exception('Erreur lors de la récupération des indicateurs globaux');
    }
  }

  /// Récupère toutes les alertes (tous magasins)
  Future<List<Map<String, dynamic>>> listAllAlerts() async {
    debugPrint('[SERVICE][StockService] Récupération de toutes les alertes');
    final uri = Uri.parse(ApiUrls.listStocks + '/alerts');
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    } else {
      throw Exception('Erreur lors de la récupération de toutes les alertes');
    }
  }

  // ========== NOUVELLES MÉTHODES POUR SYNCHRONISATION VENTE-STOCK ==========

  /// Vérifie la disponibilité d'un produit dans un magasin
  // Future<Map<String, dynamic>> checkStockAvailability(
  //   String storeId,
  //   String productId,
  //   int requestedQuantity,
  // ) async {
  //   debugPrint(
  //     '[SERVICE][StockService] Vérification disponibilité produit $productId dans magasin $storeId (quantité: $requestedQuantity)',
  //   );
  //   final uri = Uri.parse(
  //     ApiUrls.checkStockAvailability(storeId, productId),
  //   ).replace(queryParameters: {'quantity': requestedQuantity.toString()});
  //   final token = await getTokenFromPrefs();
  //   final headers = {
  //     'Content-Type': 'application/json',
  //     if (token != null) 'Authorization': 'Bearer $token',
  //   };
  //   final response = await http.get(uri, headers: headers);
  //   debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');

  //   if (response.statusCode == 200) {
  //   print("Resultat stock_service : ${response.body}");
  //     final data = jsonDecode(response.body);
  //     debugPrint(
  //       '[DEBUG][StockService][checkStockAvailability] HTTP 200 Response: storeId=$storeId, productId=$productId, requestedQuantity=$requestedQuantity, data=${data['data']}',
  //     );
  //     return Map<String, dynamic>.from(data['data'] ?? {});
  //   } else {
  //     debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
  //     throw Exception('Erreur lors de la vérification de disponibilité');
  //   }
  // }

  Future<Map<String, dynamic>> checkStockAvailability(
  String storeId,
  String productId,
  int requestedQuantity,
) async {
  final uri = Uri.parse(ApiUrls.checkStockAvailability(storeId, productId))
      .replace(queryParameters: {
    'quantity': requestedQuantity.toString(),
  });
  final token = await getTokenFromPrefs();
  final headers = {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) {
    throw Exception('Erreur vérification disponibilité: ${response.body}');
  }

  final decoded = jsonDecode(response.body) as Map<String, dynamic>;

  // Si l'API enveloppe les données dans { data: { ... } }, on l'utilise,
  // sinon on retourne directement le map racine.
  final payload = decoded.containsKey('data')
      ? (decoded['data'] as Map<String, dynamic>)
      : decoded;
  debugPrint('[StockService] payload: $payload');

  return Map<String, dynamic>.from(payload);
}


  /// Réserve temporairement du stock pour un panier
  Future<bool> reserveStock(
    String storeId,
    String productId,
    int quantity, {
    String? sessionId,
    Duration? duration,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Réservation de $quantity du produit $productId dans magasin $storeId',
    );
    final url = Uri.parse(ApiUrls.reserveStock(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'sessionId': sessionId == null || sessionId == 'default'
            ? (throw Exception(
                'Session ID absent ou invalide pour la réservation/libération.',
              ))
            : sessionId,
        'durationMinutes': duration?.inMinutes ?? 30, // 30 min par défaut
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }

  /// Libère une réservation de stock
  Future<bool> releaseReservation(
    String storeId,
    String productId,
    int quantity, {
    String? sessionId,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Libération de $quantity du produit $productId dans magasin $storeId',
    );
    final url = Uri.parse(ApiUrls.releaseReservation(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'sessionId': sessionId == null || sessionId == 'default'
            ? (throw Exception(
                'Session ID absent ou invalide pour la réservation/libération.',
              ))
            : sessionId,
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }

  /// Enregistre un mouvement de stock suite à une vente
  Future<bool> recordSaleMovement(
    String storeId, {
    required String productId,
    required int quantity,
    required String invoiceId,
    String? userId,
    String? notes,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Enregistrement mouvement de vente: produit $productId, quantité $quantity, facture $invoiceId',
    );
    final url = Uri.parse(ApiUrls.recordSaleMovement(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'type': 'sale', // Type de mouvement : vente
        'invoiceId': invoiceId,
        'userId': userId,
        'notes': notes ?? 'Vente - Facture $invoiceId',
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }

  /// Récupère les informations de stock d'un produit spécifique dans un magasin
  Future<Map<String, dynamic>> getProductStock(
    String storeId,
    String productId,
  ) async {
    debugPrint(
      '[SERVICE][StockService] Récupération stock produit $productId dans magasin $storeId',
    );
    final uri = Uri.parse(ApiUrls.getProductStock(storeId, productId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.get(uri, headers: headers);
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else if (response.statusCode == 404) {
      // Aucun stock trouvé pour ce produit/magasin : retourne un stock vide
      debugPrint('[SERVICE][StockService] Stock non trouvé (404), retourne 0');
      return {
        'quantity': 0,
        'reserved': 0,
        'available': 0,
        'lastMovement': null,
      };
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      throw Exception('Erreur lors de la récupération du stock du produit');
    }
  }

  /// Libère toutes les réservations d'une session (abandon de panier)
  Future<bool> releaseAllSessionReservations(
    String storeId, {
    String? sessionId,
  }) async {
    debugPrint(
      '[SERVICE][StockService] Libération de toutes les réservations de la session $sessionId dans magasin $storeId',
    );
    final url = Uri.parse(ApiUrls.releaseReservation(storeId));
    final token = await getTokenFromPrefs();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'sessionId': sessionId == null || sessionId == 'default'
            ? (throw Exception(
                'Session ID absent ou invalide pour la réservation/libération.',
              ))
            : sessionId,
        'releaseAll': true,
      }),
    );
    debugPrint('[SERVICE][StockService] Status: ${response.statusCode}');
    if (response.statusCode == 200) {
      return true;
    } else {
      debugPrint('[SERVICE][StockService] Erreur: ${response.body}');
      return false;
    }
  }
}
