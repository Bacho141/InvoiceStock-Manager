import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final Cart _cart = Cart();

  Cart get cart => _cart;

  // --- State for payment ---
  double _amountPaid = 0;
  String _paymentMethod = 'especes';

  double get amountPaid => _amountPaid;
  String get paymentMethod => _paymentMethod;
  double get dueAmount => total - _amountPaid;

  void setAmountPaid(double amount) {
    _amountPaid = amount;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }
  // --- End of state for payment ---

  void addProduct(Product product, {int quantity = 1, double? discount}) {
    final index = _cart.items.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index >= 0) {
      _cart.items[index].quantity += quantity;
    } else {
      _cart.items.add(
        CartItem(product: product, quantity: quantity, discount: discount),
      );
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _cart.items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _cart.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      _cart.items[index].quantity = quantity;
      notifyListeners();
    }
  }

  void setDiscount(String productId, double discount) {
    final index = _cart.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (index >= 0) {
      _cart.items[index].discount = discount;
      notifyListeners();
    }
  }

  void setClient(User? client) {
    _cart.client = client;
    notifyListeners();
  }

  void clear() {
    _cart.clear();
    // Reset payment info as well
    _amountPaid = 0;
    _paymentMethod = 'especes';
    notifyListeners();
  }

  double get subtotal => _cart.subtotal;
  double get totalDiscount => _cart.totalDiscount;
  double get total => _cart.total;
  User? get client => _cart.client;
  List<CartItem> get items => List.unmodifiable(_cart.items);
}
