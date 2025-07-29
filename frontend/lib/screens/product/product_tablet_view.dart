import 'package:flutter/material.dart';
import '../../widgets/product/product_form_modal.dart';
import '../../widgets/product/product_detail_modal.dart';
import '../../widgets/product/product_actions_modal.dart';
import '../../widgets/product/product_header.dart';
import '../../widgets/product/product_filters.dart';
import '../../widgets/product/product_table.dart';
// import 'package:lottie/lottie.dart'; // Décommente si tu utilises Lottie

class ProductTabletView extends StatefulWidget {
  const ProductTabletView({super.key});

  @override
  State<ProductTabletView> createState() => _ProductTabletViewState();
}

class _ProductTabletViewState extends State<ProductTabletView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  String _selectedStatus = 'Tous';
  String _selectedMargin = 'Toutes';
  String _sortBy = 'Prix';
  bool _sortDescending = true;
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
    // ... Ajoute d'autres produits si besoin ...
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        product: product,
        onSave: (productData) {
          setState(() {
            if (product != null) {
              final index = _products.indexWhere(
                (p) => p['id'] == product['id'],
              );
              if (index != -1) {
                _products[index] = productData;
              }
            } else {
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
    showDialog(
      context: context,
      builder: (context) => ProductActionsModal(product: product),
    ).then((result) {
      if (result == 'edit') {
        _showProductForm(product: product);
      } else if (result == 'details') {
        _showProductDetails(product);
      } else if (result == 'toggle_status') {
        setState(() => product['isActive'] = !product['isActive']);
      } else if (result == 'delete') {
        setState(() => _products.removeWhere((p) => p['id'] == product['id']));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
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
              products: _products,
              onEditProduct: (product) => _showProductForm(product: product),
              onShowDetails: (product) => _showProductDetails(product),
              onShowActions: (product) => _showProductActions(product),
            ),
          ],
        ),
      ),
    );
  }
}
