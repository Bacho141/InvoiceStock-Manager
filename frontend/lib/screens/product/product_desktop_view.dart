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

class ProductDesktopView extends StatefulWidget {
  const ProductDesktopView({super.key});

  @override
  State<ProductDesktopView> createState() => _ProductDesktopViewState();
}

class _ProductDesktopViewState extends State<ProductDesktopView> {
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

  void _loadProducts() async {
    await _productController.fetchProducts();
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Product? product}) {
    debugPrint('[VIEW][ProductDesktopView] Ouverture formulaire produit');
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        product: product?.toJson(),
        onSave: (productData) async {
          debugPrint(
            '[VIEW][ProductDesktopView] Sauvegarde produit: \\${productData['reference']}',
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
      '[VIEW][ProductDesktopView] Affichage détails produit \\${product.reference}',
    );
    debugPrint(
      '[VIEW][ProductDesktopView] Données produit: \\${product.toJson()}',
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
      '[VIEW][ProductDesktopView] Menu actions produit \\${product.reference}',
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
      '[VIEW][ProductDesktopView] Début ajout produit: \\${productData['name']}',
    );
    final product = Product.fromJson(productData);
    try {
      final createdProduct = await _productController.addProduct(product);
      debugPrint(
        '[VIEW][ProductDesktopView] Succès ajout produit: id=\\${createdProduct.id}, name=\\${createdProduct.name}, reference=\\${createdProduct.reference}',
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
      debugPrint(
        '[VIEW][ProductDesktopView] selectedStoreId: \\${selectedStoreId}',
      );
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
        '[VIEW][ProductDesktopView] currentStore: id=\\${currentStore?.id}, name=\\${currentStore?.name}',
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
          '[VIEW][ProductDesktopView] Stock pour ajustement: productId=\\${stock.productId}, storeId=\\${stock.storeId}, name=\\${stock.description}',
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
        '[VIEW][ProductDesktopView] Erreur ajout produit: \\${e.toString()}',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur ajout produit')));
    }
  }

  Future<void> _editProduct(Map<String, dynamic> productData) async {
    debugPrint(
      '[VIEW][ProductDesktopView] Début modification produit: \\${productData['id']}',
    );
    final product = Product.fromJson(productData);
    try {
      await _productController.updateProduct(product);
      debugPrint(
        '[VIEW][ProductDesktopView] Succès modification produit: \\${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit modifié !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductDesktopView] Erreur modification produit: \\${e.toString()}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur modification produit')),
      );
    }
  }

  Future<void> _deleteProduct(Product product) async {
    debugPrint(
      '[VIEW][ProductDesktopView] Début suppression produit: \\${product.id}',
    );
    try {
      await _productController.deleteProduct(product.id!);
      debugPrint(
        '[VIEW][ProductDesktopView] Succès suppression produit: \\${product.id}',
      );
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit supprimé !')));
    } catch (e) {
      debugPrint(
        '[VIEW][ProductDesktopView] Erreur suppression produit: \\${e.toString()}',
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
      return Center(child: Text('Erreur: \\${_productController.error}'));
    }
    final products = _productController.products;
    return Column(
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
          onStatusChanged: (value) => setState(() => _selectedStatus = value!),
          onMarginChanged: (value) => setState(() => _selectedMargin = value!),
          onSortByChanged: (value) => setState(() => _sortBy = value!),
          onSortDescendingChanged: (value) =>
              setState(() => _sortDescending = value),
          onShowFiltersChanged: (value) => setState(() => _showFilters = value),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: ProductTable(
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
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 270,
                        child: /* Remplace par ton chemin d'animation Lottie */
                            // Lottie.asset('assets/Lottie/Warehouse.json'),
                            Placeholder(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Bienvenue dans le catalogue produits !",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
