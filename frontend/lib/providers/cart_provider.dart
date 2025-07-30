import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/stock_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  Cart _cart = Cart();

  Cart get cart => _cart;

  /// Ajoute un produit au panier après vérification et réservation du stock
  /// Retourne true si succès, false si stock insuffisant ou réservation échouée
  Future<bool> addItem(
    Product product, {
    required String storeId,
    required String sessionId,
    int quantity = 1,
    double? discount,
  }) async {
    // Vérification et réservation du stock avant ajout
    final stockService = StockService();
    final isAvailable = await stockService.checkStockAvailability(
      storeId,
      product.id,
      quantity,
    ) == true;
    if (!isAvailable) {
      // Stock insuffisant
      return false;
    }
    final reserved = await stockService.reserveStock(
      storeId,
      product.id,
      quantity,
      sessionId: sessionId,
      duration: Duration(minutes: 30), // réservation temporaire
    ) == true;
    if (!reserved) {
      // Échec réservation
      return false;
    }
    final existingItemIndex = _cart.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingItemIndex >= 0) {
      // Le produit existe déjà, on met à jour la quantité
      _cart.items[existingItemIndex].quantity += quantity;
      if (discount != null) {
        _cart.items[existingItemIndex].discount = discount;
      }
    } else {
      // Nouveau produit
      _cart.items.add(
        CartItem(
          product: product,
          quantity: quantity,
          discount: discount,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  // Supprimer un produit du panier
  void removeItem(String productId) {
    _cart.items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Mettre à jour la quantité d'un produit
  void updateQuantity(String productId, int newQuantity) {
    final itemIndex = _cart.items.indexWhere((item) => item.product.id == productId);
    if (itemIndex >= 0) {
      _cart.items[itemIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  // Mettre à jour la remise d'un produit
  void updateDiscount(String productId, double discount) {
    final itemIndex = _cart.items.indexWhere((item) => item.product.id == productId);
    if (itemIndex >= 0) {
      _cart.items[itemIndex].discount = discount;
      notifyListeners();
    }
  }

  // Définir le client
  void setClient(User? client) {
    _cart.client = client;
    notifyListeners();
  }

  // Vider le panier
  Future<void> clear() async {
    // Libération automatique des réservations de stock à la suppression du panier
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString('selected_store_id');
if (storeId == null || storeId == 'default') {
  debugPrint('[PROVIDER][CartProvider] ERREUR: storeId absent ou invalide lors du clear() (reçu: "$storeId")');
  throw Exception('Aucun magasin sélectionné ou storeId invalide lors de la libération des réservations.');
}
      final sessionId = prefs.getString('session_id');
      if (storeId != null && sessionId != null) {
        final stockService = StockService();
        await stockService.releaseAllSessionReservations(storeId, sessionId: sessionId);
        debugPrint('[PROVIDER][CartProvider] Réservations libérées lors du clear()');
      }
    } catch (e) {
      debugPrint('[PROVIDER][CartProvider] Erreur libération réservations lors du clear(): $e');
    }
    _cart.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    // Hook de cycle de vie : libération automatique à la destruction du provider
    clear();
    super.dispose();
  }

  // Calculer le total
  double get total => _cart.total;
  
  // Calculer le sous-total
  double get subtotal => _cart.subtotal;
  
  // Calculer le total des remises
  double get totalDiscount => _cart.totalDiscount;
  
  // Nombre d'articles dans le panier
  int get itemCount => _cart.items.fold(0, (sum, item) => sum + item.quantity);
}
