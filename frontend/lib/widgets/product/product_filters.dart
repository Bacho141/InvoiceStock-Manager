import 'package:flutter/material.dart';

class ProductFilters extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCategory;
  final String selectedStatus;
  final String selectedMargin;
  final String sortBy;
  final bool sortDescending;
  final bool showFilters;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onMarginChanged;
  final ValueChanged<String?> onSortByChanged;
  final ValueChanged<bool> onSortDescendingChanged;
  final ValueChanged<bool> onShowFiltersChanged;

  const ProductFilters({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.selectedStatus,
    required this.selectedMargin,
    required this.sortBy,
    required this.sortDescending,
    required this.showFilters,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onMarginChanged,
    required this.onSortByChanged,
    required this.onSortDescendingChanged,
    required this.onShowFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 950;
    return Container(
      padding: EdgeInsets.all(isNarrow ? 10 : 20),
      color: Colors.white,
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recherche
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: '🔍 Rechercher par nom/référence...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
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
                  decoration: InputDecoration(
                    labelText: 'Catégorie:',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: ['Tous', 'Actif', 'Inactif']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: onStatusChanged,
                  decoration: InputDecoration(
                    labelText: 'Statut:',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedMargin,
                  items: ['Toutes', '0-10%', '10-25%', '25-50%', '50%+']
                      .map(
                        (margin) => DropdownMenuItem(
                          value: margin,
                          child: Text(margin),
                        ),
                      )
                      .toList(),
                  onChanged: onMarginChanged,
                  decoration: InputDecoration(
                    labelText: 'Marge:',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => onShowFiltersChanged(!showFilters),
                      icon: Icon(
                        showFilters
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                      ),
                      tooltip: 'Filtres avancés',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: showFilters
                          ? Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: sortBy,
                                    items:
                                        [
                                              'Prix',
                                              'Marge',
                                              'Stock',
                                              'Nom',
                                              'Date',
                                            ]
                                            .map(
                                              (sort) => DropdownMenuItem(
                                                value: sort,
                                                child: Text(sort),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: onSortByChanged,
                                    decoration: InputDecoration(
                                      labelText: 'Trier par',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () =>
                                      onSortDescendingChanged(!sortDescending),
                                  icon: Icon(
                                    sortDescending
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                  ),
                                  tooltip: 'Ordre de tri',
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  children: [
                    // Recherche
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: '🔍 Rechercher par nom/référence...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Catégorie
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
                        decoration: InputDecoration(
                          labelText: 'Catégorie:',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Statut
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        items: ['Tous', 'Actif', 'Inactif']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ),
                            )
                            .toList(),
                        onChanged: onStatusChanged,
                        decoration: InputDecoration(
                          labelText: 'Statut:',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Marge
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedMargin,
                        items: ['Toutes', '0-10%', '10-25%', '25-50%', '50%+']
                            .map(
                              (margin) => DropdownMenuItem(
                                value: margin,
                                child: Text(margin),
                              ),
                            )
                            .toList(),
                        onChanged: onMarginChanged,
                        decoration: InputDecoration(
                          labelText: 'Marge:',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Bouton filtres avancés
                    IconButton(
                      onPressed: () => onShowFiltersChanged(!showFilters),
                      icon: Icon(
                        showFilters
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                      ),
                      tooltip: 'Filtres avancés',
                    ),
                  ],
                ),
                if (showFilters) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sortBy,
                          items: ['Prix', 'Marge', 'Stock', 'Nom', 'Date']
                              .map(
                                (sort) => DropdownMenuItem(
                                  value: sort,
                                  child: Text(sort),
                                ),
                              )
                              .toList(),
                          onChanged: onSortByChanged,
                          decoration: InputDecoration(
                            labelText: 'Trier par',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () =>
                            onSortDescendingChanged(!sortDescending),
                        icon: Icon(
                          sortDescending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                        ),
                        tooltip: 'Ordre de tri',
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
