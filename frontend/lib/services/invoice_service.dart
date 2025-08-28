import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utiles/api_urls.dart';
import '../utiles/navigator_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'stock_service.dart';

class InvoiceService {
  /// Valide une facture après transaction stock
  Future<Map<String, dynamic>> validateInvoice(
    String id,
    String storeId,
  ) async {
    final url = ApiUrls.invoicesValidate(id, storeId);
    debugPrint('[INVOICE_SERVICE] Appel de la route de validation: POST $url');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    debugPrint(
      '[INVOICE_SERVICE][VALIDATE] Token récupéré pour validation: ${token != null ? token.substring(0, 10) + '...' : 'null'}',
    );
    debugPrint(
      "[INVOICE_SERVICE][VALIDATE] Headers envoyés: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}",
    );

    if (token == null) {
      debugPrint(
        '[INVOICE_SERVICE] ERREUR: Token non trouvé. Validation annulée.',
      );
      throw Exception('Token non trouvé.');
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint(
      '[INVOICE_SERVICE] Réponse de la validation: ${response.statusCode} - ${response.body}',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur validation facture: ${response.body}');
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    debugPrint(
      '[SERVICE][InvoiceService] Tentative de création facture (transactionnelle): ${jsonEncode(data)}',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    debugPrint(
      '[SERVICE][InvoiceService] Token récupéré: ${token != null ? token.substring(0, 10) + '...' : 'null'}',
    );

    // 1. Créer la facture (statut provisoire)
    debugPrint(
      '[SERVICE][InvoiceService] Envoi de la requête POST ${ApiUrls.invoices}',
    );
    debugPrint(
      '[SERVICE][InvoiceService] Headers: \{\'Authorization\': \'Bearer $token\', \'Content-Type\': \'application/json\'\}',
    );
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
      final invoiceResult = jsonDecode(response.body);
      final invoiceId = invoiceResult['data']?['_id'] ?? invoiceResult['_id'];
      debugPrint(
        '[SERVICE][InvoiceService] Facture créée avec succès, ID: $invoiceId',
      );

      // 2. Transaction stock : tout ou rien
      final stockService = StockService();
      // final storeId = data['storeId'];
      final storeId = data['store'];
      print("ALLAH : $storeId");
      if (storeId == null || storeId == 'default') {
        debugPrint(
          '[SERVICE][InvoiceService] ERREUR: storeId absent ou invalide (reçu: "$storeId")',
        );
        throw Exception(
          'Aucun magasin sélectionné ou storeId invalide. Veuillez sélectionner un magasin avant de poursuivre.',
        );
      }
      final lines = List<Map<String, dynamic>>.from(data['lines'] ?? []);
      final userId = data['userId'];
      final sessionId = data['sessionId'];
      final List<Map<String, dynamic>> mouvementsOk = [];
      bool echec = false;
      String? produitEchec;
      String? erreurMouvement;

      for (final line in lines) {
        final productId = line['productId']?.toString();
        final quantity = (line['quantity'] as num?)?.toInt() ?? 0;
        if (productId != null && quantity > 0) {
          try {
            final success = await stockService.recordSaleMovement(
              storeId,
              productId: productId,
              quantity: quantity,
              invoiceId: invoiceId.toString(),
              userId: userId?.toString(),
              notes:
                  'Vente - Facture $invoiceId - ${line['productName'] ?? 'Produit'}',
            );
            if (success) {
              mouvementsOk.add({'productId': productId, 'quantity': quantity});
              debugPrint(
                '[SERVICE][InvoiceService] Mouvement OK: $productId ($quantity)',
              );
            } else {
              echec = true;
              produitEchec = productId;
              erreurMouvement = 'Echec enregistrement mouvement de stock';
              break;
            }
          } catch (e) {
            echec = true;
            produitEchec = productId;
            erreurMouvement = e.toString();
            break;
          }
        }
      }

      if (echec) {
        // Rollback : réajuster le stock pour tous les mouvements déjà faits
        debugPrint(
          '[SERVICE][InvoiceService] Echec transactionnel sur $produitEchec : rollback...',
        );
        for (final m in mouvementsOk) {
          try {
            await stockService.adjustStock(
              storeId,
              m['productId'],
              m['quantity'] * -1, // Remettre la quantité
              'Rollback vente - Facture $invoiceId',
            );
          } catch (e) {
            debugPrint(
              '[SERVICE][InvoiceService] Erreur rollback sur produit ${m['productId']}: $e',
            );
          }
        }
        // Supprimer la facture créée
        try {
          await http.delete(
            Uri.parse('${ApiUrls.invoices}/$invoiceId'),
            headers: {'Authorization': 'Bearer $token'},
          );
          debugPrint(
            '[SERVICE][InvoiceService] Facture $invoiceId supprimée suite à échec transactionnel',
          );
        } catch (e) {
          debugPrint(
            '[SERVICE][InvoiceService] Erreur suppression facture $invoiceId: $e',
          );
        }
        // Feedback utilisateur centralisé (snackbar)
        if (navigatorKey.currentContext != null) {
          final context = navigatorKey.currentContext!;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Erreur critique : la facture a été annulée, aucun produit n\'a été déduit du stock.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 6),
            ),
          );
        }
        throw Exception(
          "Erreur transactionnelle lors de la déduction du stock (produit $produitEchec): $erreurMouvement. Aucun produit n'a été déduit, la facture a été annulée.",
        );
      }

      // 3. Libérer les réservations de la session après validation
      if (sessionId != null) {
        try {
          await stockService.releaseAllSessionReservations(
            storeId,
            sessionId: sessionId.toString(),
          );
          debugPrint(
            '[SERVICE][InvoiceService] Réservations libérées pour session $sessionId',
          );
        } catch (e) {
          debugPrint(
            '[SERVICE][InvoiceService] Erreur libération réservations: $e',
          );
        }
      }

      return invoiceResult;
    } else {
      debugPrint(
        '[SERVICE][InvoiceService] Erreur création facture: ${response.body}',
      );
      throw Exception('Erreur création facture: ${response.body}');
    }
  }

  /// Crée une facture avec vérification préalable du stock
  Future<Map<String, dynamic>> createInvoiceWithStockValidation(
    Map<String, dynamic> data,
  ) async {
    debugPrint(
      '[SERVICE][InvoiceService] Création facture avec validation stock',
    );

    final stockService = StockService();
    final storeId = data['storeId'];
    if (storeId == null || storeId == 'default') {
      debugPrint(
        '[SERVICE][InvoiceService] ERREUR: storeId absent ou invalide (reçu: "$storeId")',
      );
      throw Exception(
        'Aucun magasin sélectionné ou storeId invalide. Veuillez sélectionner un magasin avant de poursuivre.',
      );
    }
    final lines = List<Map<String, dynamic>>.from(data['lines'] ?? []);

    // Vérifier la disponibilité de tous les produits avant création
    for (final line in lines) {
      final productId = line['productId']?.toString();
      final quantity = (line['quantity'] as num?)?.toInt() ?? 0;

      if (productId != null && quantity > 0) {
        try {
          final availability = await stockService.checkStockAvailability(
            storeId,
            productId,
            quantity,
          );

          if (!(availability['available'] ?? false)) {
            throw Exception(
              'Stock insuffisant pour ${line['productName'] ?? 'produit'} (${availability['message'] ?? 'quantité demandée: $quantity'})',
            );
          }
        } catch (e) {
          throw Exception('Erreur vérification stock: $e');
        }
      }
    }

    // Si toutes les vérifications passent, créer la facture
    return await createInvoice(data);
  }

  Future<Map<String, dynamic>> getInvoices({
    Map<String, String>? filters,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final uri = Uri.parse(ApiUrls.invoices).replace(queryParameters: filters);

    debugPrint('[SERVICE][InvoiceService] Fetching invoices from: $uri');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // The backend now returns an object with 'data', 'total', etc.
      return data as Map<String, dynamic>;
    } else {
      debugPrint(
        '[SERVICE][InvoiceService] Error fetching invoices: ${response.body}',
      );
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

    // DEBUG: Print the raw response body to inspect the data from the server.
    if (kDebugMode) {
      print(
        '[InvoiceService.getInvoiceById] Response for ID $id: ${response.statusCode}',
      );
      print('[InvoiceService.getInvoiceById] Body: ${response.body}');
    }

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

  Future<Map<String, dynamic>> addPayment(
    String id,
    double amount,
    String method,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final paymentData = {
      'payment': {'amount': amount, 'method': method},
    };

    final response = await http.put(
      Uri.parse('${ApiUrls.invoices}/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de l\'ajout du paiement');
    }
  }

  /// Annule une facture avec motif et gestion automatique du stock
  Future<Map<String, dynamic>> cancelInvoice(String id, String reason) async {
    debugPrint(
      '[SERVICE][InvoiceService] Annulation facture $id avec motif: $reason',
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      debugPrint('[SERVICE][InvoiceService] ERREUR: Token manquant');
      throw Exception('Token d\'authentification manquant');
    }

    // Récupérer l'ID utilisateur depuis les préférences ou le token
    final userJson = prefs.getString('user_data');
    String? userId;
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        userId = userData['_id'] ?? userData['id'];
        debugPrint('[SERVICE][InvoiceService] User ID récupéré: $userId');
      } catch (e) {
        debugPrint('[SERVICE][InvoiceService] Erreur décodage user_data: $e');
      }
    } else {
      debugPrint(
        '[SERVICE][InvoiceService] ATTENTION: user_data non trouvé dans les préférences',
      );
    }

    final requestBody = {'reason': reason, 'userId': userId};
    debugPrint(
      '[SERVICE][InvoiceService] Corps de la requête: ${jsonEncode(requestBody)}',
    );
    debugPrint('[SERVICE][InvoiceService] URL: ${ApiUrls.invoices}/$id');

    try {
      final response = await http.delete(
        Uri.parse('${ApiUrls.invoices}/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint(
        '[SERVICE][InvoiceService] Réponse annulation: ${response.statusCode}',
      );
      debugPrint(
        '[SERVICE][InvoiceService] Corps de la réponse: ${response.body}',
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[SERVICE][InvoiceService] Facture annulée avec succès');
        return result;
      } else {
        // Amélioration du détail d'erreur
        String errorMessage = 'Erreur annulation facture';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
          debugPrint(
            '[SERVICE][InvoiceService] Détail erreur backend: ${errorData.toString()}',
          );
        } catch (e) {
          debugPrint(
            '[SERVICE][InvoiceService] Impossible de décoder l\'erreur: ${response.body}',
          );
          errorMessage = 'Erreur HTTP ${response.statusCode}: ${response.body}';
        }

        debugPrint(
          '[SERVICE][InvoiceService] Erreur annulation: $errorMessage',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('[SERVICE][InvoiceService] Exception lors de la requête: $e');
      if (e is Exception) {
        rethrow; // Relancer l'exception existante
      } else {
        throw Exception('Erreur de connexion: $e');
      }
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

  /// Génère et télécharge le PDF d'une facture avec son historique de paiement
  Future<String> downloadInvoicePDF(String invoiceId) async {
    debugPrint(
      '[SERVICE][InvoiceService] Téléchargement PDF pour facture $invoiceId',
    );
    print(
      '[DEBUG][downloadInvoicePDF] Début de downloadInvoicePDF avec invoiceId: $invoiceId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print(
        '[DEBUG][downloadInvoicePDF] Token récupéré: ${token != null ? 'PRÉSENT (${token.length} chars)' : 'NULL'}',
      );

      if (token == null) {
        print('[DEBUG][downloadInvoicePDF] ERREUR: Token manquant');
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous reconnecter.',
        );
      }

      // CORRECTION: Le backend envoie maintenant un PDF binaire, pas du JSON
      // On retourne directement l'URL avec le token pour l'ouvrir dans le navigateur
      final pdfUrl = '${ApiUrls.invoicePDF(invoiceId)}?token=$token';
      print('[DEBUG][downloadInvoicePDF] URL PDF construite: $pdfUrl');
      debugPrint('[SERVICE][InvoiceService] PDF URL générée: $pdfUrl');

      return pdfUrl;
    } catch (e) {
      print('[DEBUG][downloadInvoicePDF] EXCEPTION: $e');
      debugPrint('[SERVICE][InvoiceService] Exception génération PDF: $e');
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  /// Génère l'URL de téléchargement PDF avec paramètre download
  Future<String> downloadInvoicePDFForced(String invoiceId) async {
    debugPrint(
      '[SERVICE][InvoiceService] Téléchargement forcé PDF pour facture $invoiceId',
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null) {
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous reconnecter.',
        );
      }

      // Construire l'URL avec paramètre download=true
      final pdfUrl =
          '${ApiUrls.invoicePDF(invoiceId)}?token=$token&download=true';
      print('[DEBUG][downloadInvoicePDFForced] URL de téléchargement: $pdfUrl');

      return pdfUrl;
    } catch (e) {
      debugPrint(
        '[SERVICE][InvoiceService] Exception génération URL download: $e',
      );
      throw Exception(
        'Erreur lors de la génération de l\'URL de téléchargement: $e',
      );
    }
  }

  /// Télécharge plusieurs factures sous forme d'archive ZIP
  Future<String> downloadInvoicesZIP(List<String> invoiceIds) async {
    debugPrint(
      '[SERVICE][InvoiceService] Téléchargement ZIP pour ${invoiceIds.length} factures',
    );
    debugPrint('[SERVICE][InvoiceService] IDs: ${invoiceIds.join(", ")}');

    if (invoiceIds.isEmpty) {
      throw Exception('Aucune facture sélectionnée pour le téléchargement');
    }

    if (invoiceIds.length > 50) {
      throw Exception('Trop de factures sélectionnées (maximum 50)');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification non trouvé');
    }

    // Construire l'URL pour le téléchargement ZIP
    final url = '${ApiUrls.baseUrl}/invoices/download/zip';
    debugPrint('[SERVICE][InvoiceService] URL ZIP: $url');

    // Pour le téléchargement direct, on construit une URL avec les paramètres
    final queryParams = {
      'token': token,
      'ids': invoiceIds.join(','),
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final downloadUrl = uri.toString();

    debugPrint(
      '[SERVICE][InvoiceService] URL de téléchargement ZIP: $downloadUrl',
    );
    return downloadUrl;
  }
}
