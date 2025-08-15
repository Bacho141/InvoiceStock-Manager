import 'package:flutter/material.dart';
import '../../../models/store.dart';
import '../../../controllers/cart_controller.dart';
import '../../../models/product.dart';
import '../../../services/product_service.dart';

class AddProductsMobile extends StatefulWidget {
  final VoidCallback onNext;
  final Store? currentStore;

  const AddProductsMobile({Key? key, required this.onNext, this.currentStore})
      : super(key: key);
  @override
  State<AddProductsMobile> createState() => _AddProductsMobileState();
}

class _AddProductsMobileState extends State<AddProductsMobile> {
  int? _isAddingIndex;

  final cart = CartController();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _futureProducts;
  String _search = '';
  final List<String> _categories = ['Tous', 'Boissons', 'Snacks', 'Autres'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant AddProductsMobile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStore?.id != widget.currentStore?.id) {
      _loadProducts();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _search = _searchController.text;
      _loadProducts();
    });
  }

  void _loadProducts() {
    if (widget.currentStore?.id == null || widget.currentStore!.id.isEmpty) {
      setState(() {
        _futureProducts = Future.value([]);
      });
      return;
    } else if (widget.currentStore!.id == 'all') {
      _futureProducts = _productService.getProductsWithAggregatedStock();
    } else {
      _futureProducts = _productService.getProductsWithStock(widget.currentStore!.id!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Material(
          elevation: 3,
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 18,
              bottom: 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF7717E8),
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Catalogue Produits',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 2),
                      height: 3,
                      width: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7717E8),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7717E8).withOpacity(0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: AnimatedBuilder(
          animation: cart,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Rechercher un produit...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Catégories (non fonctionnel ici)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final selected =
                          cat == 'Tous'; // TODO: brancher la sélection réelle
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF7717E8),
                          ),
                        ),
                        selected: selected,
                        selectedColor: const Color(0xFF7717E8),
                        backgroundColor: Colors.grey[100],
                        onSelected: (_) {},
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Liste des produits
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Erreur chargement produits: ${snapshot.error}'),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Aucun produit disponible.'),
                        );
                      }
                      final productsWithStock = snapshot.data!;
                      final filtered = _search.isEmpty
                          ? productsWithStock
                          : productsWithStock
                                .where(
                                  (item) {
                                    final Product product = item['product'];
                                    final name = product.name.toLowerCase();
                                    final ref = product.ref.toLowerCase();
                                    final searchLower = _search.toLowerCase();
                                    return name.contains(searchLower) || ref.contains(searchLower);
                                  },
                                )
                                .toList();
                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final Product product;
                          if (widget.currentStore?.id == 'all') {
                            product = Product.fromJson(item);
                          } else {
                            product = item['product'];
                          }
                          final int availableQuantity = item['availableQuantity'];
                          final bool isAvailable = item['isAvailable'];
                          final alreadyInCart = cart.items.any(
                            (cartItem) => cartItem.product.id == product.id,
                          );
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            color: alreadyInCart
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF7717E8,
                                  ).withOpacity(0.10),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: Color(0xFF7717E8),
                                  ),
                                ),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${product.sellingPrice.toStringAsFixed(0)} F (Stock: $availableQuantity)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    alreadyInCart
                                        ? Icons.check_circle
                                        : Icons.add_circle,
                                    color: alreadyInCart
                                        ? Colors.green
                                        : (isAvailable && widget.currentStore?.id != 'all' ? const Color(0xFF43A047) : Colors.grey),
                                    size: 28,
                                  ),
                                  onPressed: alreadyInCart || !isAvailable || widget.currentStore?.id == 'all'
                                      ? null
                                      : _isAddingIndex == index
                                          ? null
                                          : () async {
                                              setState(() {
                                                _isAddingIndex = index;
                                              });
                                              final String? storeId = widget.currentStore?.id;
                                              if (storeId == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Veuillez sélectionner un magasin.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                                return;
                                              }
                                              final success = await cart.addProduct(product, storeId: storeId);
                                              setState(() {
                                                _isAddingIndex = null;
                                              });
                                              if (!success && mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Stock insuffisant pour ce produit',
                                                      style: const TextStyle(color: Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                  tooltip: alreadyInCart
                                      ? 'Ajouté'
                                      : (isAvailable ? 'Ajouter au panier' : 'Stock indisponible'),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onNext,
        backgroundColor: const Color(0xFF7717E8),
        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
        label: Text(
          'Voir le panier (${cart.items.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 3,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
