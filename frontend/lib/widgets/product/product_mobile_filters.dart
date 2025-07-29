import 'package:flutter/material.dart';

class ProductMobileFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedStatus;
  final String sortBy;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSortByChanged;

  const ProductMobileFilters({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.sortBy,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSortByChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              items: ['Toutes', 'Boissons', 'Snacks', 'Divers']
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: onCategoryChanged,
              decoration: const InputDecoration(
                labelText: 'Filtres',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: sortBy,
              items: ['Prix', 'Marge', 'Stock', 'Nom']
                  .map(
                    (sort) => DropdownMenuItem(value: sort, child: Text(sort)),
                  )
                  .toList(),
              onChanged: onSortByChanged,
              decoration: const InputDecoration(
                labelText: 'Tri',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
