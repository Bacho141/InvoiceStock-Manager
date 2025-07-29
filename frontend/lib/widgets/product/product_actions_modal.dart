import 'package:flutter/material.dart';

class ProductActionsModal extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductActionsModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[WIDGET][ProductActionsModal] Affichage actions pour: \\${product['name'] ?? ''}',
    );
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
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
                      : const Icon(Icons.image, color: Colors.grey, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Référence: ${product['reference'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Actions disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              context,
              'Modifier le produit',
              Icons.edit,
              Colors.blue,
              () {
                debugPrint(
                  '[WIDGET][ProductActionsModal] Action: Modifier produit \\${product['name'] ?? ''}',
                );
                Navigator.of(context).pop('edit');
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Voir les détails',
              Icons.info,
              Colors.green,
              () {
                debugPrint(
                  '[WIDGET][ProductActionsModal] Action: Détails produit \\${product['name'] ?? ''}',
                );
                Navigator.of(context).pop('details');
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              product['isActive'] ?? false
                  ? 'Désactiver le produit'
                  : 'Activer le produit',
              (product['isActive'] ?? false) ? Icons.block : Icons.check_circle,
              (product['isActive'] ?? false) ? Colors.orange : Colors.green,
              () {
                debugPrint(
                  '[WIDGET][ProductActionsModal] Action: Toggle statut produit \\${product['name'] ?? ''}',
                );
                Navigator.of(context).pop('toggle_status');
              },
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Gérer le stock',
              Icons.inventory,
              Colors.purple,
              () => Navigator.of(context).pop('manage_stock'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Voir l\'historique',
              Icons.history,
              Colors.indigo,
              () => Navigator.of(context).pop('history'),
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              context,
              'Supprimer le produit',
              Icons.delete,
              Colors.red,
              () {
                debugPrint(
                  '[WIDGET][ProductActionsModal] Action: Demande suppression produit \\${product['name'] ?? ''}',
                );
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(text, style: TextStyle(color: color)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le produit "${product['name'] ?? ''}" ?\n\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint(
                '[WIDGET][ProductActionsModal] Action: Suppression confirmée pour \\${product['name'] ?? ''}',
              );
              Navigator.of(context).pop();
              Navigator.of(context).pop('delete');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
