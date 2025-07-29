import 'package:flutter/material.dart';
import '../../widgets/product/product_form_modal.dart';
import '../../widgets/product/product_detail_modal.dart';
import '../../widgets/product/product_actions_modal.dart';
import '../../widgets/product/product_mobile_header.dart';
import '../../widgets/product/product_mobile_filters.dart';
import '../../widgets/product/product_mobile_list.dart';

class ProductMobileView extends StatefulWidget {
  const ProductMobileView({super.key});

  @override
  State<ProductMobileView> createState() => _ProductMobileViewState();
}

class _ProductMobileViewState extends State<ProductMobileView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  String _selectedStatus = 'Tous';
  String _sortBy = 'Prix';
  bool _showFilters = false;

  // Données simulées pour le développement
  final List<Map<String, dynamic>> _products = [
    {
      'id': '1',
      'reference': 'COCA01',
      'name': 'Coca-Cola 33cl',
      'description': 'Coca-Cola 33cl',
      'category': 'Boissons',
      'purchasePrice': 400,
      'sellingPrice': 500,
      'margin': 25.0,
      'marginValue': 100,
      'stock': 45,
      'minStock': 10,
      'maxStock': 100,
      'unit': 'Pièce',
      'barcode': '1234567890123',
      'isActive': true,
      'image': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': '2',
      'reference': 'EAU01',
      'name': 'Eau Minérale 1.5L',
      'description': 'Eau Minérale 1.5L',
      'category': 'Boissons',
      'purchasePrice': 200,
      'sellingPrice': 300,
      'margin': 50.0,
      'marginValue': 100,
      'stock': 80,
      'minStock': 10,
      'maxStock': 100,
      'unit': 'Pièce',
      'barcode': '1234567890124',
      'isActive': true,
      'image': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': '3',
      'reference': 'BIS01',
      'name': 'Biscuit Chocolat',
      'description': 'Biscuit Chocolat',
      'category': 'Snacks',
      'purchasePrice': 600,
      'sellingPrice': 750,
      'margin': 25.0,
      'marginValue': 150,
      'stock': 0,
      'minStock': 10,
      'maxStock': 100,
      'unit': 'Paquet',
      'barcode': '1234567890125',
      'isActive': true,
      'image': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '4',
      'reference': 'ANCIEN',
      'name': 'Produit Ancien',
      'description': 'Produit Ancien',
      'category': 'Divers',
      'purchasePrice': 80,
      'sellingPrice': 100,
      'margin': 25.0,
      'marginValue': 20,
      'stock': 5,
      'minStock': 10,
      'maxStock': 100,
      'unit': 'Pièce',
      'barcode': '1234567890126',
      'isActive': false,
      'image': null,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    debugPrint('[VIEW][ProductMobileView] Ouverture formulaire produit');
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        product: product,
        onSave: (productData) {
          debugPrint(
            '[VIEW][ProductMobileView] Sauvegarde produit: ${productData['reference']}',
          );
          setState(() {
            if (product != null) {
              // Modification
              final index = _products.indexWhere(
                (p) => p['id'] == product['id'],
              );
              if (index != -1) {
                _products[index] = productData;
              }
            } else {
              // Création
              productData['id'] = DateTime.now().millisecondsSinceEpoch
                  .toString();
              _products.add(productData);
            }
          });
        },
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> product) {
    debugPrint(
      '[VIEW][ProductMobileView] Affichage détails produit ${product['reference']}',
    );
    showDialog(
      context: context,
      builder: (context) => ProductDetailModal(product: product),
    ).then((result) {
      if (result == 'edit') {
        _showProductForm(product: product);
      } else if (result == 'actions') {
        _showProductActions(product);
      }
    });
  }

  void _showProductActions(Map<String, dynamic> product) {
    debugPrint(
      '[VIEW][ProductMobileView] Menu actions produit ${product['reference']}',
    );
    showDialog(
      context: context,
      builder: (context) => ProductActionsModal(product: product),
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

  void _deleteProduct(Map<String, dynamic> product) {
    debugPrint(
      '[VIEW][ProductMobileView] Suppression produit ${product['reference']}',
    );
    setState(() {
      _products.removeWhere((p) => p['id'] == product['id']);
    });
  }

  void _toggleProductStatus(Map<String, dynamic> product) {
    debugPrint(
      '[VIEW][ProductMobileView] Changement statut produit ${product['reference']}',
    );
    setState(() {
      product['isActive'] = !product['isActive'];
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: ProductMobileList(
              products: _products,
              onEditProduct: (product) => _showProductForm(product: product),
              onShowDetails: (product) => _showProductDetails(product),
              onShowActions: (product) => _showProductActions(product),
            ),
          ),
        ],
      ),
    );
  }
}
