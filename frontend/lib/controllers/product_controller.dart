import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductController extends ChangeNotifier {
  final ProductService _service = ProductService();

  List<Product> _products = [];
  bool _loading = false;
  String? _error;

  List<Product> get products => _products;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchProducts() async {
    debugPrint('[CONTROLLER][ProductController] Chargement des produits');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _service.getProducts();
      debugPrint(
        '[CONTROLLER][ProductController] Produits chargés: \\${_products.length}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint(
        '[CONTROLLER][ProductController] Erreur chargement: \\$_error',
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<Product> addProduct(Product product) async {
    debugPrint(
      '[CONTROLLER][ProductController] Ajout produit: \\${product.name}',
    );
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final newProduct = await _service.addProduct(product);
      _products.insert(0, newProduct);
      debugPrint(
        '[CONTROLLER][ProductController] Produit ajouté: \\${newProduct.id}',
      );
      return newProduct;
    } catch (e) {
      _error = e.toString();
      debugPrint('[CONTROLLER][ProductController] Erreur ajout: \\$_error');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    debugPrint(
      '[CONTROLLER][ProductController] Modification produit: \\${product.id}',
    );
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateProduct(product);
      final idx = _products.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        _products[idx] = updated;
        debugPrint(
          '[CONTROLLER][ProductController] Produit modifié: \\${updated.id}',
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint(
        '[CONTROLLER][ProductController] Erreur modification: \\$_error',
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    debugPrint('[CONTROLLER][ProductController] Suppression produit: \\${id}');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      debugPrint('[CONTROLLER][ProductController] Produit supprimé: \\${id}');
    } catch (e) {
      _error = e.toString();
      debugPrint(
        '[CONTROLLER][ProductController] Erreur suppression: \\$_error',
      );
    }
    _loading = false;
    notifyListeners();
  }
}
