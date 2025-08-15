import 'package:flutter/material.dart';

class ProductTable extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onEditProduct;
  final Function(Map<String, dynamic>) onShowDetails;
  final Function(Map<String, dynamic>) onShowActions;

  const ProductTable({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('Image')),
              DataColumn(
                label: Row(
                  children: [
                    Text('Référence'),
                    Icon(Icons.keyboard_arrow_up, size: 16),
                  ],
                ),
              ),
              DataColumn(label: Text('Nom du Produit')),
              DataColumn(label: Text('Catégorie')),
              DataColumn(label: Text('Prix Achat')),
              DataColumn(label: Text('Prix Vente')),
              DataColumn(label: Text('Marge')),
              DataColumn(label: Text('Qté')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Actions')),
            ],
            rows: products.map((product) {
              debugPrint('[VIEW][ProductTable] Product data: $product');
              final stock = product['stock'] ?? 0;
              final minStock = product['minStock'] ?? 0;
              final marginValue = product['marginValue'] ?? 0;
              final margin = (product['margin'] ?? 0).toDouble();
              final stockStatus = _getStockStatus(stock, minStock);
              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      width: 40,
                      height: 40,
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
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  DataCell(Text(product['reference'] ?? '')),
                  DataCell(Text(product['name'] ?? 'Produit inconnu')),
                  DataCell(Text(product['category'] ?? '')),
                  DataCell(Text('${product['purchasePrice'] ?? 0} F')),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${product['sellingPrice'] ?? 0} F'),
                        Text(
                          '($marginValue F)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      '${margin.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: margin > 30 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Text('$stock'),
                        const SizedBox(width: 4),
                        Icon(
                          _getStockStatusIcon(stockStatus),
                          color: _getStockStatusColor(stockStatus),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Icon(
                          (product['isActive'] ?? false)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: (product['isActive'] ?? false)
                              ? Colors.green
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (product['isActive'] ?? false) ? 'Actif' : 'Inactif',
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        // IconButton(
                        //   onPressed: () => onEditProduct(product),
                        //   icon: const Icon(Icons.edit, color: Colors.blue),
                        //   tooltip: 'Modifier',
                        // ),
                        IconButton(
                          onPressed: () => onShowActions(product),
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          tooltip: 'Actions',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
