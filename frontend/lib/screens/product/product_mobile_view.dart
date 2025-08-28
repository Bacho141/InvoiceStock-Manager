import 'package:flutter/material.dart';
import '../../widgets/product/product_form_modal.dart';
import '../../widgets/product/product_detail_modal.dart';
import '../../widgets/product/product_actions_modal.dart';
import '../../widgets/product/product_mobile_header.dart';
import '../../widgets/product/product_mobile_filters.dart';
import '../../widgets/product/product_mobile_list.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/store.dart';
import '../../models/stock.dart';
import '../../widgets/stock/stock_adjust_modal.dart';
import 'dart:convert';

class ProductMobileView extends StatefulWidget {
  const ProductMobileView({super.key});

  @override
  State<ProductMobileView> createState() => _ProductMobileViewState();
}

class _ProductMobileViewState extends State<ProductMobileView> {
  final ProductController _productController = ProductController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  String _selectedStatus = 'Tous';
  String _sortBy = 'Prix';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    debugPrint('[VIEW][ProductMobileView] Chargement des produits...');
    await _productController.fetchProducts();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Product? product}) {
    debugPrint('[VIEW][ProductMobileView] Ouverture formulaire produit');
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        product: product?.toJson(),
        onSave: (productData) async {
          debugPrint(
            '[VIEW][ProductMobileView] Sauvegarde produit: ${productData['reference']}',
          );
          if (product != null) {
            // Modification
            await _editProduct(productData);
          } else {
            // Création
            await _addProduct(productData);
          }
          setState(() {});
        },
      ),
    );
  }

  Future<void> _addProduct(Map<String, dynamic> productData) async {
    debugPrint(
      '[VIEW][ProductMobileView] Début ajout produit: ${productData['name']}',
    );
    final product = Product.fromJson(productData);
    try {
      final createdProduct = await _productController.addProduct(product);
      debugPrint(
        '[VIEW][ProductMobileView] Succès ajout produit: id=${createdProduct.id}, name=${createdProduct.name}, reference=${createdProduct.reference}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit ajouté !')));

      // Récupérer le magasin courant depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storesJson = prefs.getString('assigned_stores');
      final selectedStoreId = prefs.getString('selected_store_id');
      Store? currentStore;
      debugPrint('[VIEW][ProductMobileView] selectedStoreId: $selectedStoreId');
      if (storesJson != null && selectedStoreId != null) {
        final storesList = (storesJson.isNotEmpty
            ? List<Map<String, dynamic>>.from(jsonDecode(storesJson))
            : []);
        for (final s in storesList) {
          if ((s['_id'] ?? s['id']).toString() == selectedStoreId) {
            currentStore = Store.fromJson(s);
            break;
          }
        }
      }
      debugPrint(
        '[VIEW][ProductMobileView] currentStore: id=${currentStore?.id}, name=${currentStore?.name}',
      );
      if (currentStore != null && currentStore.id != 'all') {
        // Créer un Stock temporaire pour le modal
        final stock = Stock(
          id: '',
          productId: createdProduct.id ?? '',
          storeId: currentStore.id,
          quantity: 0,
          minQuantity: createdProduct.minStockLevel,
          isActive: true,
          lastUpdated: DateTime.now(),
          description: createdProduct.name,
          storeName: currentStore.name,
        );
        debugPrint(
          '[VIEW][ProductMobileView] Stock pour ajustement: productId=${stock.productId}, storeId=${stock.storeId}, name=${stock.description}',
        );
        showDialog(
          context: context,
          builder: (_) => StockAdjustModal(
            store: currentStore,
            stocks: [stock],
            onSave: () {
              // Optionnel : rafraîchir la liste des stocks si besoin
            },
          ),
        );
      } else if (currentStore != null && currentStore.id == 'all') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Veuillez sélectionner un magasin précis pour initialiser le stock.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        '[VIEW][ProductMobileView] Erreur ajout produit: ${e.toString()}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur ajout produit')));
    }
  }

  Future<void> _editProduct(Map<String, dynamic> productData) async {
    debugPrint(
      '[VIEW][ProductMobileView] Début modification produit: ${productData['id']}',
    );
    final product = Product.fromJson(productData);
    try {
      await _productController.updateProduct(product);
      debugPrint(
        '[VIEW][ProductMobileView] Succès modification produit: ${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit modifié !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductMobileView] Erreur modification produit: ${e.toString()}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur modification produit')),
      );
    }
  }

  void _showProductDetails(Product product) {
    debugPrint(
      '[VIEW][ProductMobileView] Affichage détails produit ${product.reference}',
    );
    debugPrint(
      '[VIEW][ProductMobileView] Données produit: ${product.toJson()}',
    );
    showDialog(
      context: context,
      builder: (context) => ProductDetailModal(product: product.toJson()),
    ).then((result) {
      if (result == 'edit') {
        _showProductForm(product: product);
      } else if (result == 'actions') {
        _showProductActions(product);
      }
    });
  }

  void _showProductActions(Product product) {
    debugPrint(
      '[VIEW][ProductMobileView] Menu actions produit ${product.reference}',
    );
    showDialog(
      context: context,
      builder: (context) => ProductActionsModal(product: product.toJson()),
    ).then((result) {
      if (result == 'edit') {
        _showProductForm(product: product);
      } else if (result == 'details') {
        _showProductDetails(product);
      } else if (result == 'toggle_status') {
        _toggleProductStatus(product);
      } else if (result == 'delete') {
        _deleteProduct(product);
      }
    });
  }

  Future<void> _deleteProduct(Product product) async {
    debugPrint(
      '[VIEW][ProductMobileView] Début suppression produit: ${product.id}',
    );
    try {
      await _productController.deleteProduct(product.id!);
      debugPrint(
        '[VIEW][ProductMobileView] Succès suppression produit: ${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit supprimé !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductMobileView] Erreur suppression produit: ${e.toString()}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur suppression produit')),
      );
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    final updated = product.copyWith(isActive: !product.isActive);
    await _productController.updateProduct(updated);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Statut produit mis à jour !')));
  }

  @override
  Widget build(BuildContext context) {
    // Gestion des états de chargement et d'erreur
    if (_productController.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_productController.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Erreur: ${_productController.error}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final products = _productController.products;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ProductMobileHeader(
          onAddProduct: () => _showProductForm(),
          onToggleFilters: () => setState(() => _showFilters = !_showFilters),
          showFilters: _showFilters,
        ),
      ),
      body: Column(
        children: [
          if (_showFilters)
            ProductMobileFilters(
              searchController: _searchController,
              selectedCategory: _selectedCategory,
              selectedStatus: _selectedStatus,
              sortBy: _sortBy,
              onCategoryChanged: (value) =>
                  setState(() => _selectedCategory = value!),
              onStatusChanged: (value) =>
                  setState(() => _selectedStatus = value!),
              onSortByChanged: (value) => setState(() => _sortBy = value!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _loadProducts();
              },
              child: ProductMobileList(
                products: products.map((p) => p.toJson()).toList(),
                onEditProduct: (productMap) {
                  final product = Product.fromJson(productMap);
                  _showProductForm(product: product);
                },
                onShowDetails: (productMap) {
                  final product = Product.fromJson(productMap);
                  _showProductDetails(product);
                },
                onShowActions: (productMap) {
                  final product = Product.fromJson(productMap);
                  _showProductActions(product);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
