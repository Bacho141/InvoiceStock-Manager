import 'package:flutter/material.dart';

class ProductDetailModal extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailModal({super.key, required this.product});

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

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[WIDGET][ProductDetailModal] Affichage détails produit: \\${product['name'] ?? ''}',
    );
    final stock =
        product['stock'] ??
        product['minStock'] ??
        product['minStockLevel'] ??
        0;
    final minStock = product['minStock'] ?? product['minStockLevel'] ?? 0;
    final stockStatus = _getStockStatus(stock, minStock);
    final createdAt = product['createdAt'];
    DateTime? createdDate;
    if (createdAt is String) {
      createdDate = DateTime.tryParse(createdAt);
    } else if (createdAt is DateTime) {
      createdDate = createdAt;
    }
    final createdAtStr = createdDate != null
        ? '${createdDate.day}/${createdDate.month}/${createdDate.year}'
        : '';

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: product['image'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product['image'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              color: Colors.grey,
                              size: 40,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Référence: \\${product['reference'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                product['isActive'] ?? false
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: (product['isActive'] ?? false)
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product['isActive'] ?? false
                                    ? 'Actif'
                                    : 'Inactif',
                                style: TextStyle(
                                  color: (product['isActive'] ?? false)
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop('edit'),
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop('actions'),
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      tooltip: 'Actions',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Informations Générales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Catégorie',
                        product['category'] ?? '',
                        Icons.category,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Unité',
                        product['unit'] ?? '',
                        Icons.straighten,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Code-barres',
                        product['barcode'] ?? '',
                        Icons.qr_code,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Date création',
                        createdAtStr,
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Prix et Marges',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Prix d\'achat',
                        '${product['purchasePrice'] ?? 0} F',
                        Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Prix de vente',
                        '${product['sellingPrice'] ?? 0} F',
                        Icons.sell,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Marge (%)',
                        '${((product['margin'] ?? 0).toDouble()).toStringAsFixed(0)}%',
                        Icons.trending_up,
                        color: ((product['margin'] ?? 0).toDouble()) > 30
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Marge (F)',
                        '${(product['marginValue'] ?? 0)} F',
                        Icons.attach_money,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Stock',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Stock actuel',
                        '${product['stock'] ?? 0}',
                        Icons.inventory,
                        color: _getStockStatusColor(stockStatus),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Stock minimum',
                        '${product['minStock'] ?? product['minStockLevel'] ?? 0}',
                        Icons.warning,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Stock maximum',
                        '${product['maxStock'] ?? product['maxStockLevel'] ?? 0}',
                        Icons.inventory_2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        'Statut stock',
                        stockStatus,
                        Icons.info,
                        color: _getStockStatusColor(stockStatus),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    product['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color ?? Colors.grey),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
