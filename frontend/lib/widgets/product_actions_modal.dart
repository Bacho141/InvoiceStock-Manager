import 'package:flutter/material.dart';



class ProductActionsModal extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductActionsModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                const Icon(Icons.more_vert, color: Color(0xFF7717E8), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Actions - ${product['name']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7717E8),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Contenu des actions
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Actions Principales
                    _buildActionSection('Actions Principales', [
                      _buildActionTile(
                        context,
                        '✏️ Modifier le produit',
                        'Modifier les informations du produit',
                        Icons.edit,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Modification du produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('edit');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '👁️ Voir les détails',
                        'Afficher toutes les informations',
                        Icons.info_outline,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Affichage détails produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('details');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '📊 Voir l\'historique des prix',
                        'Consulter l\'évolution des prix',
                        Icons.trending_up,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Historique prix produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('price_history');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '📈 Voir l\'historique des stocks',
                        'Consulter les mouvements de stock',
                        Icons.inventory,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Historique stock produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('stock_history');
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Gestion du Statut
                    _buildActionSection('Gestion du Statut', [
                      _buildActionTile(
                        context,
                        product['isActive']
                            ? '⚫ Désactiver le produit'
                            : '🟢 Activer le produit',
                        product['isActive']
                            ? 'Masquer le produit du catalogue'
                            : 'Rendre le produit visible dans le catalogue',
                        product['isActive']
                            ? Icons.visibility_off
                            : Icons.visibility,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Changement statut produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('toggle_status');
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Actions Avancées
                    _buildActionSection('Actions Avancées', [
                      _buildActionTile(
                        context,
                        '📋 Copier les informations',
                        'Copier les détails du produit',
                        Icons.copy,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Copie infos produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('copy_info');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '📤 Exporter en PDF',
                        'Générer un rapport PDF',
                        Icons.picture_as_pdf,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Export PDF produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('export_pdf');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '🗑️ Supprimer le produit',
                        'Supprimer définitivement le produit',
                        Icons.delete,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Suppression produit ${product['reference']}',
                          );
                          _showDeleteConfirmation(context);
                        },
                        isDestructive: true,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Actions en Lot
                    _buildActionSection('Actions en Lot', [
                      _buildActionTile(
                        context,
                        '📦 Modifier le stock',
                        'Ajuster la quantité en stock',
                        Icons.inventory_2,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Modification stock produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('modify_stock');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '💰 Modifier les prix',
                        'Ajuster les prix d\'achat et de vente',
                        Icons.attach_money,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Modification prix produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('modify_prices');
                        },
                      ),
                      _buildActionTile(
                        context,
                        '📝 Modifier la catégorie',
                        'Changer la catégorie du produit',
                        Icons.category,
                        () {
                          debugPrint(
                            '[WIDGET][ProductActionsModal] Modification catégorie produit ${product['reference']}',
                          );
                          Navigator.of(context).pop('modify_category');
                        },
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // Bouton d'annulation
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7717E8),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF7717E8),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDestructive ? Colors.red[300] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmation de suppression'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le produit "${product['name']}" ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la confirmation
                Navigator.of(context).pop('delete'); // Retourner l'action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}
