import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final storeId = prefs.getString('selected_store_id') ?? 'all';
      debugPrint('[CONTROLLER][ProductController] Store ID: $storeId');
      final productsWithStock = await _service.getProductsWithStock(storeId);
      debugPrint(
        '[CONTROLLER][ProductController] Products with stock type: ${productsWithStock.runtimeType}',
      );
      debugPrint(
        '[CONTROLLER][ProductController] Products with stock: ${productsWithStock}',
      );

      // Gérer les deux types de réponses
      _products = productsWithStock.map((p) {
        if (p.containsKey('product') && p['product'] is Product) {
          // Cas où le service retourne des objets enrichis avec un objet Product déjà instancié
          debugPrint(
            '[CONTROLLER][ProductController] Format enrichi détecté pour: ${p['product'].name}',
          );
          return p['product'] as Product;
        } else {
          // Cas où le service retourne des données JSON pures (format agrégé)
          debugPrint(
            '[CONTROLLER][ProductController] Format JSON détecté pour: ${p['name'] ?? 'nom manquant'}',
          );
          return Product.fromJson(p);
        }
      }).toList();

      debugPrint(
        '[CONTROLLER][ProductController] Parsed products: ${_products.map((p) => p.toJson()).toList()}',
      );
      debugPrint(
        '[CONTROLLER][ProductController] Produits chargés: ${_products.length}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('[CONTROLLER][ProductController] Erreur chargement: $_error');
    }
    _loading = false;
    notifyListeners();
  }

  Future<Product> addProduct(Product product) async {
    debugPrint(
      '[CONTROLLER][ProductController] Ajout produit: ${product.name}',
    );
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final newProduct = await _service.addProduct(product);
      _products.insert(0, newProduct);
      debugPrint(
        '[CONTROLLER][ProductController] Produit ajouté: ${newProduct.id}',
      );
      return newProduct;
    } catch (e) {
      _error = e.toString();
      debugPrint('[CONTROLLER][ProductController] Erreur ajout: $_error');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    debugPrint(
      '[CONTROLLER][ProductController] Modification produit: ${product.id}',
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
          '[CONTROLLER][ProductController] Produit modifié: ${updated.id}',
        );
      }
    } catch (e) {
      _error = e.toString();
      debugPrint(
        '[CONTROLLER][ProductController] Erreur modification: $_error',
      );
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    debugPrint('[CONTROLLER][ProductController] Suppression produit: $id');
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      debugPrint('[CONTROLLER][ProductController] Produit supprimé: $id');
    } catch (e) {
      _error = e.toString();
      debugPrint('[CONTROLLER][ProductController] Erreur suppression: $_error');
    }
    _loading = false;
    notifyListeners();
  }
}
