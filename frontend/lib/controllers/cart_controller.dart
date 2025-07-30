import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';
import '../services/invoice_service.dart';

class CartController extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();
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

  Future<bool> addProduct(Product product, {required String storeId, int quantity = 1, double? discount}) async {
    // Vérification disponibilité du stock avant ajout
    final productService = ProductService();
    final result = await productService.checkProductAvailability(storeId, product.id ?? '', quantity);
    if (!(result['isAvailable'] ?? false)) {
      // Stock insuffisant
      return false;
    }
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
    return true;
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

  /// Valide la facture courante côté backend (statut "validée") après création
  Future<Map<String, dynamic>> validateCurrentInvoice(String invoiceId) async {
    try {
      final validatedInvoice = await _invoiceService.validateInvoice(invoiceId);
      debugPrint('[CONTROLLER][CartController] Facture validée: ${validatedInvoice['id']}');
      return validatedInvoice;
    } catch (e) {
      debugPrint('[CONTROLLER][CartController] Erreur validation: $e');
      rethrow;
    }
  }
}

