import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/product_service.dart';
import '../services/invoice_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

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
    debugPrint('[CART_CONTROLLER] Début validation pour facture ID: $invoiceId');
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString('selected_store_id');
      debugPrint('[CART_CONTROLLER] Store ID lu depuis prefs: $storeId');

      if (storeId == null || storeId == 'all') {
        debugPrint('[CART_CONTROLLER] ERREUR: storeId est null ou \'all\'. Validation annulée.');
        throw Exception('Erreur interne: storeId non trouvé lors de la validation.');
      }

      debugPrint('[CART_CONTROLLER] Appel de invoiceService.validateInvoice avec invoiceId: $invoiceId et storeId: $storeId');
      final validatedInvoice = await _invoiceService.validateInvoice(invoiceId, storeId);
      debugPrint('[CART_CONTROLLER] Facture validée avec succès: ${validatedInvoice['id']}');
      return validatedInvoice;
    } catch (e) {
      debugPrint('[CART_CONTROLLER] ERREUR lors de la validation: $e');
      rethrow;
    }
  }
}

