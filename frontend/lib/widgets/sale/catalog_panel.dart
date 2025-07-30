import 'package:flutter/material.dart';
import '../../controllers/cart_controller.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';

class CatalogPanel extends StatefulWidget {
  final String? storeId;
  CatalogPanel({Key? key, required this.storeId}) : super(key: key);
  @override
  State<CatalogPanel> createState() => _CatalogPanelState();
}

class _CatalogPanelState extends State<CatalogPanel> {
  int? _isAddingIndex;

  final cart = CartController();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? _futureProducts;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant CatalogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _loadProducts();
      setState(() {});
    }
  }

  void _onSearchChanged() {
    setState(() {
      _search = _searchController.text;
      _loadProducts(); // Optionnel: à optimiser si filtrage côté backend
    });
  }

  void _loadProducts() {
    if (widget.storeId == null || widget.storeId!.isEmpty) {
      debugPrint('[CatalogPanel] Aucun storeId fourni, chargement bloqué');
      _futureProducts = Future.value([]);
      return;
    }
    _futureProducts = _productService.getProductsWithStock(widget.storeId!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final items = cart.items;
        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre avec indicateur
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.local_drink, color: Color(0xFF7717E8)),
                          SizedBox(width: 8),
                          Text(
                            'Catalogue Produits',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 3,
                        width: 60,
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
                ),
                const SizedBox(height: 12),
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText:
                        'Rechercher un produit (nom, référence, code-barres)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // TODO: Catégories et recherche
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _CategoryChip(label: 'Boissons'),
                      _CategoryChip(label: 'Snacks'),
                      _CategoryChip(label: 'Autres'),
                      _CategoryChip(label: 'Tous'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Liste des produits
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _futureProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text('Erreur chargement produits'),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Aucun produit disponible.'),
                        );
                      }
                      final products = snapshot.data!;
                      final filtered = _search.isEmpty
                          ? products
                          : products.where((item) {
                              final Product? product = item is Product
                                  ? item
                                  : (item is Map && item['product'] is Product
                                      ? item['product']
                                      : null);
                              final name = (product?.name ?? '').toLowerCase();
                              final reference = (product?.reference ?? '').toLowerCase();
                              final search = _search.toLowerCase();
                              return name.contains(search) || reference.contains(search);
                            }).toList();
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final dynamic item = filtered[index];
                          final Product? product = item is Product
                              ? item
                              : (item is Map && item['product'] is Product
                                  ? item['product']
                                  : null);
                          final int availableQuantity = (item is Map && item['availableQuantity'] != null)
                              ? item['availableQuantity']
                              : 0;
                          final bool isAvailable = (item is Map && item['isAvailable'] != null)
                              ? item['isAvailable']
                              : false;
                          final bool isLowStock = (item is Map && item['isLowStock'] != null)
                              ? item['isLowStock']
                              : false;
                          final alreadyInCart = items.any(
                            (cartItem) => cartItem.product.id == (product?.id ?? ''),
                          );
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(
                                  0xFF7717E8,
                                ).withOpacity(0.08),
                                child: const Icon(
                                  Icons.local_drink,
                                  color: Color(0xFF7717E8),
                                ),
                              ),
                              title: Text(
                                (product != null && product.name.trim().isNotEmpty)
                                    ? '${product.name} (${product.reference})'
                                    : ((product != null && product.reference != null && product.reference!.trim().isNotEmpty)
                                        ? product.reference!
                                        : 'Produit inconnu'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Stock dispo: $availableQuantity',
                                        style: TextStyle(
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      if (isLowStock && isAvailable) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.warning,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const Text(
                                          ' Stock bas',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  alreadyInCart
                                      ? Icons.check_circle
                                      : Icons.add_circle,
                                  color: alreadyInCart
                                      ? Colors.green
                                      : (isAvailable
                                            ? const Color(0xFF43A047)
                                            : Colors.grey),
                                  size: 28,
                                ),
                                onPressed: alreadyInCart || !isAvailable
                                    ? null
                                    : _isAddingIndex == index
                                    ? null
                                    : () async {
                                        print('[CatalogPanel] Bouton ajout panier pressé pour index=$index, produit=${product?.name}');
                                        setState(() {
                                          _isAddingIndex = index;
                                        });
                                        print('[CatalogPanel] Vérification du storeId avant ajout panier...');
                                        final String? storeId = widget.storeId;
                                        if (storeId == null || storeId.isEmpty) {
                                          print('[CatalogPanel][ERREUR] Aucun storeId disponible, ajout annulé');
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Aucun magasin sélectionné. Veuillez sélectionner un magasin.',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          setState(() {
                                            _isAddingIndex = null;
                                          });
                                          return;
                                        }
                                        print('[CatalogPanel] Appel cart.addProduct pour ${product?.name} (id=${product?.id}) dans storeId=$storeId');
                                        final success = await cart.addProduct(
                                          product!,
                                          storeId: storeId,
                                        );
                                        print('[CatalogPanel] Résultat cart.addProduct: $success');
                                        setState(() {
                                          _isAddingIndex = null;
                                        });
                                        print('[CatalogPanel] _isAddingIndex remis à null après ajout panier.');
                                        if (!success && mounted) {
                                          print('[CatalogPanel][STOCK INSUFFISANT] pour produit ${product?.name}');
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Stock insuffisant pour ce produit',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                tooltip: alreadyInCart
                                    ? 'Ajouté'
                                    : isAvailable
                                    ? 'Ajouter au panier'
                                    : 'Stock indisponible',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(label: Text(label), backgroundColor: Colors.grey[100]),
    );
  }
}
