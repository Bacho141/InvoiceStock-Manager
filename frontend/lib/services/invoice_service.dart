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

    // 1. Créer la facture (statut provisoire)
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
    debugPrint('[SERVICE][InvoiceService] Annulation facture $id');

    // Récupérer les détails de la facture avant annulation pour traiter le stock
    Map<String, dynamic>? invoiceDetails;
    try {
      invoiceDetails = await getInvoiceById(id);
    } catch (e) {
      debugPrint(
        '[SERVICE][InvoiceService] Impossible de récupérer détails facture pour annulation: $e',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final response = await http.delete(
      Uri.parse('${ApiUrls.invoices}/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      // Traiter les mouvements de stock d'annulation
      if (invoiceDetails != null) {
        await _processStockCancellation(invoiceDetails, id);
      }
    } else {
      // Feedback utilisateur centralisé (snackbar)
      if (navigatorKey.currentContext != null) {
        final context = navigatorKey.currentContext!;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur critique : la facture n\'a pas pu être annulée, le stock n\'a pas été modifié.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 6),
          ),
        );
      }
      throw Exception('Erreur annulation facture');
    }
  }

  /// Traite les mouvements de stock suite à l'annulation d'une facture
  Future<void> _processStockCancellation(
    Map<String, dynamic> invoiceData,
    String invoiceId,
  ) async {
    debugPrint(
      '[SERVICE][InvoiceService] Traitement annulation stock pour facture $invoiceId',
    );

    try {
      final stockService = StockService();
      final storeId = invoiceData['storeId'];
      if (storeId == null || storeId == 'default') {
        debugPrint(
          '[SERVICE][InvoiceService] ERREUR: storeId absent ou invalide lors d\'une annulation (reçu: "$storeId")',
        );
        throw Exception(
          'Aucun magasin sélectionné ou storeId invalide pour l\'annulation.',
        );
      }
      final lines = List<Map<String, dynamic>>.from(invoiceData['lines'] ?? []);

      for (final line in lines) {
        final productId = line['productId']?.toString();
        final quantity = (line['quantity'] as num?)?.toInt() ?? 0;

        if (productId != null && quantity > 0) {
          try {
            // Créer un mouvement de stock d'annulation (ajout)
            final success = await stockService.adjustStock(
              storeId,
              productId,
              quantity, // Quantité à remettre en stock
              'Annulation facture $invoiceId - ${line['productName'] ?? 'Produit'}',
            );

            if (success) {
              debugPrint(
                '[SERVICE][InvoiceService] Stock restauré: produit $productId, quantité +$quantity',
              );
            }
          } catch (e) {
            debugPrint(
              '[SERVICE][InvoiceService] Erreur restauration stock pour produit $productId: $e',
            );
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[SERVICE][InvoiceService] Erreur générale annulation stock: $e',
      );
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
