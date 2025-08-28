import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../utiles/api_urls.dart';

class PaymentService {
  /// Ajouter un paiement à une facture
  Future<Payment> addPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    String? reference,
    String? notes,
  }) async {
    debugPrint('[PaymentService] Ajout paiement pour facture $invoiceId');
    debugPrint('[PaymentService] Montant: $amount, Méthode: ${method.label}');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    final paymentData = {
      'amount': amount,
      'method': method.value,
      'reference': reference,
      'notes': notes,
      'status': 'confirmed', // Par défaut confirmé
    };

    debugPrint('[PaymentService] Données à envoyer: $paymentData');

    try {
      final response = await http.post(
        Uri.parse('${ApiUrls.invoices}/$invoiceId/payments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

      debugPrint('[PaymentService] Réponse: ${response.statusCode}');
      debugPrint('[PaymentService] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Extraire le paiement de la réponse
        if (responseData['data'] != null &&
            responseData['data']['payment'] != null) {
          return Payment.fromJson(responseData['data']['payment']);
        } else if (responseData['payment'] != null) {
          return Payment.fromJson(responseData['payment']);
        } else {
          // Fallback: créer un objet Payment avec les données envoyées
          return Payment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            createdAt: DateTime.now(),
            amount: amount,
            method: method,
            reference: reference,
            notes: notes,
            status: PaymentStatus.confirmed,
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de l\'ajout du paiement',
        );
      }
    } catch (e) {
      debugPrint('[PaymentService] Erreur: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des paiements d'une facture
  Future<List<Payment>> getPaymentHistory(String invoiceId) async {
    debugPrint(
      '[PaymentService] Récupération historique paiements pour facture $invoiceId',
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiUrls.invoices}/$invoiceId/payments'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('[PaymentService] Réponse historique: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final paymentsJson =
            responseData['data'] ?? responseData['payments'] ?? [];

        return (paymentsJson as List)
            .map((paymentJson) => Payment.fromJson(paymentJson))
            .toList()
            .sortByDateDesc();
      } else {
        debugPrint('[PaymentService] Erreur récupération: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[PaymentService] Erreur: $e');
      return [];
    }
  }

  /// Annuler un paiement
  Future<bool> cancelPayment({
    required String invoiceId,
    required String paymentId,
    String? reason,
  }) async {
    debugPrint('[PaymentService] Annulation paiement $paymentId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiUrls.invoices}/$invoiceId/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason}),
      );

      debugPrint('[PaymentService] Réponse annulation: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      debugPrint('[PaymentService] Erreur annulation: $e');
      rethrow;
    }
  }

  /// Confirmer un paiement en attente
  Future<Payment> confirmPayment({
    required String invoiceId,
    required String paymentId,
    String? receiptNumber,
  }) async {
    debugPrint('[PaymentService] Confirmation paiement $paymentId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.put(
        Uri.parse('${ApiUrls.invoices}/$invoiceId/payments/$paymentId/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'receiptNumber': receiptNumber,
          'confirmedAt': DateTime.now().toIso8601String(),
        }),
      );

      debugPrint(
        '[PaymentService] Réponse confirmation: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Payment.fromJson(
          responseData['data'] ?? responseData['payment'],
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Erreur lors de la confirmation',
        );
      }
    } catch (e) {
      debugPrint('[PaymentService] Erreur confirmation: $e');
      rethrow;
    }
  }

  /// Générer un reçu de paiement
  Future<String> generatePaymentReceipt({
    required String invoiceId,
    required String paymentId,
  }) async {
    debugPrint('[PaymentService] Génération reçu pour paiement $paymentId');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiUrls.invoices}/$invoiceId/payments/$paymentId/receipt'),
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('[PaymentService] Réponse reçu: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['receiptUrl'] ?? responseData['data']['url'];
      } else {
        throw Exception('Erreur lors de la génération du reçu');
      }
    } catch (e) {
      debugPrint('[PaymentService] Erreur génération reçu: $e');
      rethrow;
    }
  }
}
