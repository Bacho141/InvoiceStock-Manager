import 'package:flutter/foundation.dart';
import '../services/stock_service.dart';
import '../models/stock.dart';
import '../models/stock_movement.dart';
import '../models/stock_alert.dart';

class StockController {
  final StockService _stockService = StockService();

  // États internes typés
  List<Stock> stocks = [];
  List<StockMovement> movements = [];
  List<StockAlert> alerts = [];
  bool isLoading = false;
  bool isLoadingStocks = false;
  bool isLoadingIndicators = false;
  bool isLoadingAlerts = false;
  String? error;
  String? alertError;
  Map<String, dynamic> indicators = {};

  /// Charge la liste des stocks pour un magasin
  Future<void> loadStocks(
    String? storeId, {
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    debugPrint('[CONTROLLER][StockController] Chargement des stocks...');
    isLoadingStocks = true;
    error = null;
    try {
      List<Map<String, dynamic>> raw;
      if (storeId == null || storeId == 'all') {
        raw = await _stockService.listStocks();
      } else {
        raw = await _stockService.getStocks(
          storeId,
          search: search,
          page: page,
          limit: limit,
        );
      }
      stocks = raw.map((e) => Stock.fromJson(e)).toList();
      debugPrint(
        '[CONTROLLER][StockController] Stocks chargés (${stocks.length})',
      );
    } catch (e) {
      error = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur: $error');
    } finally {
      isLoadingStocks = false;
    }
  }

  /// Ajuste le stock d'un produit
  Future<bool> adjustStock(
    String storeId,
    String productId,
    int newQuantity,
    String reason,
  ) async {
    debugPrint('[CONTROLLER][StockController] Ajustement stock $productId');
    isLoading = true;
    error = null;
    try {
      final result = await _stockService.adjustStock(
        storeId,
        productId,
        newQuantity,
        reason,
      );
      debugPrint('[CONTROLLER][StockController] Ajustement: $result');
      return result;
    } catch (e) {
      error = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur: $error');
      return false;
    } finally {
      isLoading = false;
    }
  }

  /// Transfère du stock entre magasins
  Future<bool> transferStock({
    required String productId,
    required String fromStoreId,
    required String toStoreId,
    required int quantity,
    String? reason,
  }) async {
    debugPrint('[CONTROLLER][StockController] Transfert stock $productId');
    isLoading = true;
    error = null;
    try {
      final result = await _stockService.transferStock(
        productId: productId,
        fromStoreId: fromStoreId,
        toStoreId: toStoreId,
        quantity: quantity,
        reason: reason,
      );
      debugPrint('[CONTROLLER][StockController] Transfert: $result');
      return result;
    } catch (e) {
      error = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur: $error');
      return false;
    } finally {
      isLoading = false;
    }
  }

  /// Charge l'historique des mouvements d'un produit
  Future<void> loadProductMovements(
    String storeId,
    String productId, {
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? type,
  }) async {
    debugPrint('[CONTROLLER][StockController] Historique produit $productId');
    isLoading = true;
    error = null;
    try {
      final raw = await _stockService.getProductMovements(
        storeId,
        productId,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        type: type,
      );
      movements = raw.map((e) => StockMovement.fromJson(e)).toList();
      debugPrint(
        '[CONTROLLER][StockController] Mouvements chargés (${movements.length})',
      );
    } catch (e) {
      error = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur: $error');
    } finally {
      isLoading = false;
    }
  }

  /// Charge les alertes de stock d'un magasin
  Future<void> loadStockAlerts(String? storeId) async {
    debugPrint('[CONTROLLER][StockController] Chargement alertes...');
    isLoadingAlerts = true;
    alertError = null;
    try {
      List<Map<String, dynamic>> raw;
      if (storeId == null || storeId == 'all') {
        raw = await _stockService.listAllAlerts();
      } else {
        raw = await _stockService.getStockAlerts(storeId);
      }
      alerts = raw.map((e) => StockAlert.fromJson(e)).toList();
      debugPrint(
        '[CONTROLLER][StockController] Alertes chargées (${alerts.length})',
      );
    } catch (e) {
      alertError = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur alertes: $alertError');
    } finally {
      isLoadingAlerts = false;
    }
  }

  /// Charge les indicateurs dynamiques d'un magasin
  Future<void> loadIndicators(String? storeId) async {
    debugPrint('[CONTROLLER][StockController] Chargement des indicateurs...');
    isLoadingIndicators = true;
    error = null;
    try {
      if (storeId == null || storeId == 'all') {
        indicators = await _stockService.getGlobalIndicators();
      } else {
        indicators = await _stockService.getStockIndicators(storeId);
      }
      debugPrint(
        '[CONTROLLER][StockController] Indicateurs chargés: ${indicators.toString()}',
      );
    } catch (e) {
      error = e.toString();
      debugPrint('[CONTROLLER][StockController] Erreur: $error');
    } finally {
      isLoadingIndicators = false;
    }
  }
}
