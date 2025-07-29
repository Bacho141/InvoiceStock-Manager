import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../controllers/cart_controller.dart';
import '../../utiles/api_urls.dart';
import '../../utiles/store_helper.dart';

class AddProductModal extends StatefulWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onProductAdded;
  final String? storeId;

  const AddProductModal({
    Key? key,
    required this.facture,
    required this.onProductAdded,
    required this.storeId,
  }) : super(key: key);

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, int> _selected = {}; // productId -> quantité
  bool _loading = true;
  bool _adding = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearch);
  }

  List<String> get _existingProductIds {
    final lines = widget.facture['lines'] as List?;
    if (lines == null) return [];
    return lines
        .map(
          (l) =>
              l is Map && l['product'] != null ? l['product'].toString() : null,
        )
        .whereType<String>()
        .toList();
  }

  void _onSearch() {
    debugPrint('[POS][AJOUT] Recherche: ${_searchController.text}');
    setState(() {
      final existingIds = _existingProductIds;
      _filtered = _searchController.text.isEmpty
          ? _products.where((p) => !existingIds.contains(p["_id"])).toList()
          : _products
                .where(
                  (p) =>
                      !existingIds.contains(p["_id"]) &&
                      ((p["name"] ?? '').toString().toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ) ||
                          (p["ref"] ?? '').toString().toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )),
                )
                .toList();
    });
  }

  Future<void> _fetchProducts() async {
    debugPrint('[POS][AJOUT] Début chargement produits...');
    setState(() {
      _loading = true;
      _error = '';
    });
    final storeId = widget.storeId;
    if (storeId == null || storeId.isEmpty) {
      setState(() {
        _error = "Aucun magasin sélectionné. Veuillez sélectionner un magasin.";
        _loading = false;
      });
      return;
    }
    try {
      debugPrint('[POS][AJOUT] Chargement produits avec stock pour storeId: $storeId');
      final products = await _productService.getProductsWithStock(storeId);
      debugPrint('[POS][AJOUT] Produits chargés: ${products.length}');
      final existingIds = _existingProductIds;
      setState(() {
        _products = products;
        _filtered = products.where((p) => !existingIds.contains(p["_id"])).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('[POS][AJOUT][ERREUR] $e');
      setState(() {
        _error = 'Erreur chargement produits';
        _loading = false;
      });
    }
  }

  Future<void> _addProducts() async {
  final storeId = await getSelectedStoreId(context: context, showError: true);
  if (storeId == null) {
    debugPrint('[POS][AJOUT][ERREUR] storeId absent ou invalide, action bloquée');
    setState(() {
      _adding = false;
      _error = "Aucun magasin sélectionné. Veuillez sélectionner un magasin.";
    });
    return;
  }
    if (_selected.isEmpty || _selected.values.every((q) => q == 0)) {
      debugPrint('[POS][AJOUT] Aucun produit sélectionné');
      return;
    }
    setState(() {
      _adding = true;
    });
    debugPrint('[POS][AJOUT] Ajout produits sélectionnés: \n$_selected');
    try {
      // Ajout au panier via CartController en typant Product
      for (final entry in _selected.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        if (quantity > 0) {
          final p = _products.firstWhere((prod) => prod['_id'] == productId);
          final product = Product(
            id: p['_id'],
            name: p['name'] ?? '',
            reference: p['ref'] ?? '',
            description: p['description'],
            category: p['category'],
            unit: p['unit'],
            purchasePrice: (p['purchasePrice'] ?? 0).toDouble(),
            sellingPrice: (p['sellingPrice'] ?? 0).toDouble(),
            minStockLevel: p['minStockLevel'] ?? 0,
            maxStockLevel: p['maxStockLevel'] ?? 0,
            barcode: p['barcode'],
            image: p['image'],
            isActive: p['isActive'] ?? true,
            createdBy: p['createdBy'],
            createdAt: p['createdAt'] != null ? DateTime.tryParse(p['createdAt']) : null,
            updatedAt: p['updatedAt'] != null ? DateTime.tryParse(p['updatedAt']) : null,
          );
          await CartController().addProduct(
            product,
            storeId: storeId,
            quantity: quantity,
          );
        }
      }
      debugPrint('[POS][AJOUT] Tous les produits ajoutés au panier.');

    // Construction de la liste des lignes à envoyer
    final List<Map<String, dynamic>> lines = _selected.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final product = _filtered.firstWhere((p) => p['id'] == entry.key, orElse: () => null);
          if (product == null) return null;
          return {
            'product': product['id'],
            'quantity': entry.value,
            // Ajouter d'autres champs si besoin (prix, remise, etc.)
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    final invoiceId = widget.facture['_id'] ?? widget.facture['id'];
    final url = '${ApiUrls.invoices}/$invoiceId/add-lines';
    debugPrint('[POS][AJOUT] URL PATCH: $url');

    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lines': lines}),
    );
      debugPrint(
        '[POS][AJOUT] Réponse backend: \n${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200) {
        debugPrint('[POS][AJOUT] Ajout réussi, fermeture modale');
        widget.onProductAdded();
      } else {
        debugPrint('[POS][AJOUT][ERREUR] Echec ajout: ${response.body}');
        setState(() {
          _error = 'Erreur ajout produit: ${response.body}';
        });
      }
    } catch (e) {
      debugPrint('[POS][AJOUT][ERREUR] Exception: $e');
      setState(() {
        _error = 'Erreur ajout produit';
      });
    } finally {
      setState(() {
        _adding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Ajouter des produits',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF7717E8),
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 1.2, height: 1, color: Color(0xFFF3F0FA)),
        const SizedBox(height: 10),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Rechercher un produit',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 12,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_error.isNotEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(_error, style: TextStyle(color: Colors.red)),
            ),
          ),
        if (!_loading && _error.isEmpty)
          SizedBox(
            height: 320,
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = _filtered[i];
                final qte = _selected[p['id'] ?? ''] ?? 0;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF7717E8,
                            ).withOpacity(0.10),
                            child: const Icon(
                              Icons.local_drink,
                              color: Color(0xFF7717E8),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p["name"] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Réf:  0{p["ref"] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.redAccent,
                                onPressed: qte > 0
                                    ? () => setState(
                                        () => _selected[p["_id"] ?? ''] = qte - 1,
                                      )
                                    : null,
                              ),
                              Container(
                                width: 28,
                                alignment: Alignment.center,
                                child: Text(
                                  '$qte',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF7717E8),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: Color(0xFF7717E8),
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () => setState(
                                  () => _selected[p["_id"] ?? ''] = qte + 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _adding ? null : () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: _adding || _selected.values.every((q) => q == 0)
                  ? null
                  : _addProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7717E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _adding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
