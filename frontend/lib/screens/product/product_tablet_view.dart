import 'package:flutter/material.dart';
import '../../widgets/product/product_form_modal.dart';
import '../../widgets/product/product_detail_modal.dart';
import '../../widgets/product/product_actions_modal.dart';
import '../../widgets/product/product_header.dart';
import '../../widgets/product/product_filters.dart';
import '../../widgets/product/product_table.dart';
import '../../controllers/product_controller.dart';
import '../../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/store.dart';
import '../../models/stock.dart';
import '../../widgets/stock/stock_adjust_modal.dart';
import 'dart:convert';
// import 'package:lottie/lottie.dart'; // Décommente si tu utilises Lottie

class ProductTabletView extends StatefulWidget {
  const ProductTabletView({super.key});

  @override
  State<ProductTabletView> createState() => _ProductTabletViewState();
}

class _ProductTabletViewState extends State<ProductTabletView> {
  final ProductController _productController = ProductController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  String _selectedStatus = 'Tous';
  String _selectedMargin = 'Toutes';
  String _sortBy = 'Prix';
  bool _sortDescending = true;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    debugPrint('[VIEW][ProductTabletView] Chargement des produits...');
    await _productController.fetchProducts();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Product? product}) {
    debugPrint('[VIEW][ProductTabletView] Ouverture formulaire produit');
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        product: product?.toJson(),
        onSave: (productData) async {
          debugPrint(
            '[VIEW][ProductTabletView] Sauvegarde produit: ${productData['reference']}',
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

  void _showProductDetails(Product product) {
    debugPrint(
      '[VIEW][ProductTabletView] Affichage détails produit ${product.reference}',
    );
    debugPrint(
      '[VIEW][ProductTabletView] Données produit: ${product.toJson()}',
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
      '[VIEW][ProductTabletView] Menu actions produit ${product.reference}',
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

  Future<void> _addProduct(Map<String, dynamic> productData) async {
    debugPrint(
      '[VIEW][ProductTabletView] Début ajout produit: ${productData['name']}',
    );
    final product = Product.fromJson(productData);
    try {
      final createdProduct = await _productController.addProduct(product);
      debugPrint(
        '[VIEW][ProductTabletView] Succès ajout produit: id=${createdProduct.id}, name=${createdProduct.name}, reference=${createdProduct.reference}',
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
      debugPrint('[VIEW][ProductTabletView] selectedStoreId: $selectedStoreId');
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
        '[VIEW][ProductTabletView] currentStore: id=${currentStore?.id}, name=${currentStore?.name}',
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
          '[VIEW][ProductTabletView] Stock pour ajustement: productId=${stock.productId}, storeId=${stock.storeId}, name=${stock.description}',
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
        '[VIEW][ProductTabletView] Erreur ajout produit: ${e.toString()}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur ajout produit')));
    }
  }

  Future<void> _editProduct(Map<String, dynamic> productData) async {
    debugPrint(
      '[VIEW][ProductTabletView] Début modification produit: ${productData['id']}',
    );
    final product = Product.fromJson(productData);
    try {
      await _productController.updateProduct(product);
      debugPrint(
        '[VIEW][ProductTabletView] Succès modification produit: ${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit modifié !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductTabletView] Erreur modification produit: ${e.toString()}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur modification produit')),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    debugPrint(
      '[VIEW][ProductTabletView] Début suppression produit: ${product.id}',
    );
    try {
      await _productController.deleteProduct(product.id!);
      debugPrint(
        '[VIEW][ProductTabletView] Succès suppression produit: ${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit supprimé !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductTabletView] Erreur suppression produit: ${e.toString()}',
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
    if (_productController.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_productController.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erreur: ${_productController.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    final products = _productController.products;
    final width = MediaQuery.of(context).size.width;
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductHeader(onAddProduct: () => _showProductForm()),
              ProductFilters(
                searchController: _searchController,
                selectedCategory: _selectedCategory,
                selectedStatus: _selectedStatus,
                selectedMargin: _selectedMargin,
                sortBy: _sortBy,
                sortDescending: _sortDescending,
                showFilters: _showFilters,
                onCategoryChanged: (value) =>
                    setState(() => _selectedCategory = value!),
                onStatusChanged: (value) =>
                    setState(() => _selectedStatus = value!),
                onMarginChanged: (value) =>
                    setState(() => _selectedMargin = value!),
                onSortByChanged: (value) => setState(() => _sortBy = value!),
                onSortDescendingChanged: (value) =>
                    setState(() => _sortDescending = value),
                onShowFiltersChanged: (value) =>
                    setState(() => _showFilters = value),
              ),
              const SizedBox(height: 16),
              // Animation Lottie plus petite ou masquée
              // SizedBox(
              //   height: 120,
              //   child: Lottie.asset('assets/Lottie/Warehouse.json'),
              // ),
              // const SizedBox(height: 16),
              // Tableau plus compact
              ProductTable(
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
            ],
          ),
        ),
      ),
    );
  }
}
