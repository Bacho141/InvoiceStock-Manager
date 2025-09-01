import 'package:flutter/material.dart';

class ClientFiltersWidget extends StatelessWidget {
  final String selectedStatus;
  final String selectedCategory;
  final String sortBy;
  final String sortOrder;
  final Function(String?) onStatusChanged;
  final Function(String?) onCategoryChanged;
  final Function(String, String) onSortChanged;
  final VoidCallback onClearFilters;

  const ClientFiltersWidget({
    Key? key,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.sortBy,
    required this.sortOrder,
    required this.onStatusChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterHeader(),
          const SizedBox(height: 12),
          _buildFilterRow(),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Icon(Icons.filter_list, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Text(
          'Filtres',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.clear, size: 16),
          label: const Text('Effacer'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: _buildModernDropdown('Statut', selectedStatus, [
            {
              'value': 'all',
              'label': 'Tous',
              'icon': Icons.all_inclusive,
            },
            {
              'value': 'active',
              'label': 'Actif',
              'icon': Icons.check_circle,
            },
            {
              'value': 'inactive',
              'label': 'Inactif',
              'icon': Icons.pause_circle,
            },
            {'value': 'blocked', 'label': 'Bloqué', 'icon': Icons.block},
          ], onStatusChanged),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildModernDropdown('Catégorie', selectedCategory, [
            {'value': 'all', 'label': 'Toutes', 'icon': Icons.category},
            {
              'value': 'particulier',
              'label': 'Particulier',
              'icon': Icons.person,
            },
            {
              'value': 'grossiste',
              'label': 'Grossiste',
              'icon': Icons.business,
            },
            {
              'value': 'detaillant',
              'label': 'Détaillant',
              'icon': Icons.store,
            },
          ], onCategoryChanged),
        ),
        const SizedBox(width: 12),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildModernDropdown(
    String label,
    String value,
    List<Map<String, dynamic>> items,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'],
            child: Row(
              children: [
                Icon(item['icon'], size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(item['label']),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: TextStyle(color: Colors.grey[800], fontSize: 14),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DropdownButton<String>(
        value: '$sortBy-$sortOrder',
        underline: const SizedBox(),
        icon: Icon(Icons.sort, color: Colors.grey[600]),
        style: TextStyle(color: Colors.grey[800], fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'createdAt-desc', child: Text('Plus récent')),
          DropdownMenuItem(value: 'createdAt-asc', child: Text('Plus ancien')),
          DropdownMenuItem(value: 'name-asc', child: Text('Nom A-Z')),
          DropdownMenuItem(value: 'name-desc', child: Text('Nom Z-A')),
          DropdownMenuItem(
            value: 'totalRevenue-desc',
            child: Text('CA décroissant'),
          ),
          DropdownMenuItem(
            value: 'creditScore-desc',
            child: Text('Meilleur score'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            final parts = value.split('-');
            onSortChanged(parts[0], parts[1]);
          }
        },
      ),
    );
  }
}