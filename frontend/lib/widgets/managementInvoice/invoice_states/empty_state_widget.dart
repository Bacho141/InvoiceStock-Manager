// widgets/invoice_states/empty_state_widget.dart
import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onCreateInvoice;
  final VoidCallback? onClearFilters;
  final IconData icon;

  const EmptyStateWidget({
    Key? key,
    this.title = 'Aucune facture trouvée',
    this.subtitle = 'Il semble qu\'il n\'y ait aucune facture correspondant à vos critères de recherche.',
    this.onCreateInvoice,
    this.onClearFilters,
    this.icon = Icons.receipt_long_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (onCreateInvoice != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onCreateInvoice,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Créer une facture'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    if (onClearFilters != null) {
      if (buttons.isNotEmpty) {
        buttons.add(const SizedBox(width: 12));
      }
      buttons.add(
        OutlinedButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Effacer filtres'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}