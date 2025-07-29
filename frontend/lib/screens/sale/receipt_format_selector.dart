import 'package:flutter/material.dart';

enum ReceiptFormat { pos, a5 }

class _ReceiptFormatSelectorView extends StatefulWidget {
  final ScrollController scrollController;

  const _ReceiptFormatSelectorView({required this.scrollController});

  @override
  State<_ReceiptFormatSelectorView> createState() =>
      _ReceiptFormatSelectorViewState();
}

class _ReceiptFormatSelectorViewState extends State<_ReceiptFormatSelectorView> {
  ReceiptFormat? _selectedFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // "Grip" pour indiquer que la feuille est déplaçable
        Center(
          child: Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Text(
                'Format du reçu',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez le format d\'impression souhaité.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildFormatCard(
                context,
                title: 'Ticket de caisse (POS)',
                description: 'Idéal pour les imprimantes thermiques.',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF7717E8),
                isSelected: _selectedFormat == ReceiptFormat.pos,
                onTap: () => setState(() => _selectedFormat = ReceiptFormat.pos),
              ),
              const SizedBox(height: 16),
              _buildFormatCard(
                context,
                title: 'Facture A5',
                description: 'Format standard pour les factures détaillées.',
                icon: Icons.document_scanner_outlined,
                color: const Color(0xFF2196F3),
                isSelected: _selectedFormat == ReceiptFormat.a5,
                onTap: () => setState(() => _selectedFormat = ReceiptFormat.a5),
              ),
            ],
          ),
        ),
        _buildConfirmButton(context),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedFormat == null
              ? null
              : () => Navigator.of(context).pop(_selectedFormat),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF7717E8),
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: const Text(
            'Confirmer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[200]!,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

Future<ReceiptFormat?> showReceiptFormatSelector({
  required BuildContext context,
}) async {
  return await showModalBottomSheet<ReceiptFormat>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _ReceiptFormatSelectorView(scrollController: controller),
          );
        },
      );
    },
  );
}
