import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/product.dart';
import '../../../controllers/cart_controller.dart';
import '../../../services/product_service.dart';
import '../../../utiles/api_urls.dart';
import '../../../utiles/store_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddProductModalMobile extends StatefulWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onProductAdded;

  const AddProductModalMobile({
    Key? key,
    required this.facture,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  State<AddProductModalMobile> createState() => _AddProductModalMobileState();
}

class _AddProductModalMobileState extends State<AddProductModalMobile> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  Map<String, int> _selectedProducts = {}; // productId -> quantity
  bool _loading = true;
  bool _adding = false;
  String _error = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _existingProductIds {
    final lines = widget.facture['lines'] as List?;
    if (lines == null) return [];
    return lines
        .map((l) => l is Map && l['product'] != null ? l['product'].toString() : null)
        .whereType<String>()
        .toList();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              (product.ref?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _fetchProducts() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final products = await _productService.getProducts();
      final existingIds = _existingProductIds;
      
      if (mounted) {
        setState(() {
          _products = products.where((p) => !existingIds.contains(p.id)).toList();
          _filteredProducts = List.from(_products);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement des produits';
          _loading = false;
        });
      }
    }
  }

  void _updateQuantity(String productId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts[productId] = quantity;
      }
    });
  }

  Future<void> _addSelectedProducts() async {
  final storeId = await getSelectedStoreId(context: context, showError: true);
  if (storeId == null) {
    debugPrint('[POS][AJOUT][ERREUR] storeId absent ou invalide, action bloquée');
    setState(() {
      _adding = false;
      _error = "Aucun magasin sélectionné. Veuillez sélectionner un magasin.";
    });
    return;
  }
    if (_selectedProducts.isEmpty || _selectedProducts.values.every((q) => q == 0)) {
      return;
    }

    setState(() => _adding = true);

    try {
      for (final entry in _selectedProducts.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        if (quantity > 0) {
          final product = _products.firstWhere((prod) => prod.id == productId);
          await CartController().addProduct(
            product,
            storeId: storeId,
            quantity: quantity,
          );
        }
      }

      final invoiceId = widget.facture['_id'] ?? widget.facture['id'];
      final url = '${ApiUrls.invoices}/$invoiceId/add-lines';

      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'lines': lines}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onProductAdded();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'ajout des produits'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _adding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch 
            ? _buildSearchField()
            : const Text('Ajouter des produits'),
        leading: _showSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchController.clear();
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
        actions: [
          if (!_showSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _showSearch = true);
                Future.delayed(Duration.zero, () {
                  FocusScope.of(context).requestFocus(_searchFocusNode);
                });
              },
            ),
          if (_selectedProducts.isNotEmpty)
            TextButton(
              onPressed: _adding ? null : _addSelectedProducts,
              child: _adding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Ajouter',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec compteur
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedProducts.length} produit${_selectedProducts.length > 1 ? 's' : ''} sélectionné${_selectedProducts.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedProducts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedProducts.clear()),
                    child: const Text('Tout effacer'),
                  ),
              ],
            ),
          ),
          
          // Liste des produits
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(padding),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final quantity = _selectedProducts[product.id] ?? 0;
                          
                          return _buildProductItem(product, quantity);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Rechercher un produit...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16),
      textInputAction: TextInputAction.search,
    );
  }

  Widget _buildProductItem(Product product, int quantity) {
    final theme = Theme.of(context);
    final isSelected = quantity > 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0.5,
      color: isSelected 
          ? theme.primaryColor.withOpacity(0.04)
          : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.primaryColor.withOpacity(0.5), width: 1)
            : BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1: Nom et prix
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du produit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.ref?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Réf: ${product.ref}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Prix unitaire
                Text(
                  '${product.sellingPrice.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Ligne 2: Contrôle de quantité
            Row(
              children: [
                // Bouton -
                _buildQuantityButton(
                  icon: Icons.remove,
                  onPressed: quantity > 0
                      ? () => _updateQuantity(product.id!, quantity - 1)
                      : null,
                ),
                
                // Quantité
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    quantity > 0 ? quantity.toString() : '0',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Bouton +
                _buildQuantityButton(
                  icon: Icons.add,
                  onPressed: () => _updateQuantity(product.id!, quantity + 1),
                ),
                
                const Spacer(),
                
                // Prix total pour ce produit
                Text(
                  '${(product.sellingPrice * (quantity > 0 ? quantity : 0)).toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed != null
          ? Theme.of(context).primaryColor
          : Colors.grey[300],
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchController.text.isEmpty
                  ? 'Aucun produit disponible à l\'ajout'
                  : 'Aucun résultat pour "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _filteredProducts = List.from(_products));
              },
              child: const Text('Réinitialiser la recherche'),
            ),
          ],
        ],
      ),
    );
  }
}
