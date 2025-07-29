import 'package:flutter/material.dart';

class ProductMobileHeader extends StatelessWidget {
  final VoidCallback onAddProduct;
  final VoidCallback onToggleFilters;
  final bool showFilters;

  const ProductMobileHeader({
    super.key,
    required this.onAddProduct,
    required this.onToggleFilters,
    required this.showFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('📚 Catalogue'),
      backgroundColor: const Color(0xFF7717E8),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: onAddProduct,
          icon: const Icon(Icons.add, size: 30),
          tooltip: 'Ajouter',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '🔍 Rechercher...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
