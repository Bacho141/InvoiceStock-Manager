import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';

class CartProvider extends ChangeNotifier {
  Cart _cart = Cart();

  Cart get cart => _cart;

  // Ajouter un produit au panier
  void addItem(Product product, {int quantity = 1, double? discount}) {
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
  void clear() {
    _cart.clear();
    notifyListeners();
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
