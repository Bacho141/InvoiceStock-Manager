import 'package:flutter/material.dart';

class ProductMobileList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onEditProduct;
  final Function(Map<String, dynamic>) onShowDetails;
  final Function(Map<String, dynamic>) onShowActions;

  const ProductMobileList({
    super.key,
    required this.products,
    required this.onEditProduct,
    required this.onShowDetails,
    required this.onShowActions,
  });

  String _getStockStatus(int stock, int minStock) {
    if (stock == 0) return 'Rupture';
    if (stock <= minStock) return 'Bas';
    return 'Normal';
  }

  Color _getStockStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'Bas':
        return Colors.orange;
      case 'Rupture':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStockStatusIcon(String status) {
    switch (status) {
      case 'Normal':
        return Icons.check_circle;
      case 'Bas':
        return Icons.warning;
      case 'Rupture':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final stockStatus = _getStockStatus(
          product['stock'],
          product['minStock'],
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['image'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              _getProductEmoji(product['category']),
                              style: const TextStyle(fontSize: 24),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => onEditProduct(product),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                tooltip: 'Modifier',
                              ),
                            ],
                          ),
                          Text(
                            'Réf: ${product['reference']}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      product['isActive'] ? Icons.check_circle : Icons.cancel,
                      color: product['isActive'] ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        product['isActive'] ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: product['isActive']
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Icon(
                      _getStockStatusIcon(stockStatus),
                      color: _getStockStatusColor(stockStatus),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stockStatus,
                      style: TextStyle(
                        color: _getStockStatusColor(stockStatus),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prix: ${product['sellingPrice']} F',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Marge: ${product['margin'].toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: product['margin'] > 30
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stock: ${product['stock']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Achat: ${product['purchasePrice']} F',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProductEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'boissons':
        return '🍶';
      case 'snacks':
        return '🍪';
      case 'divers':
        return '📦';
      default:
        return '📦';
    }
  }
}
