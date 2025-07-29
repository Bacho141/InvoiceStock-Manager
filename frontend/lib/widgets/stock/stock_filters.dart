import 'package:flutter/material.dart';

class StockFilters extends StatelessWidget {
  final VoidCallback? onNewAdjust;
  const StockFilters({Key? key, this.onNewAdjust}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Spacer(),
                ElevatedButton.icon(
                  onPressed: onNewAdjust,
                  icon: const Icon(Icons.edit),
                  label: const Text('Nouvel Ajustement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7717E8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isMobile) ...[
              _FilterBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Toutes',
                    items: const [
                      DropdownMenuItem(value: 'Toutes', child: Text('Toutes')),
                      DropdownMenuItem(
                        value: 'Boissons',
                        child: Text('Boissons'),
                      ),
                      DropdownMenuItem(value: 'Snacks', child: Text('Snacks')),
                    ],
                    onChanged: (_) {},
                    isExpanded: true,
                    icon: const Icon(Icons.category, color: Color(0xFF7717E8)),
                  ),
                ),
                label: 'Catégorie',
              ),
              const SizedBox(height: 12),
              _FilterBox(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Tous',
                    items: const [
                      DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                      DropdownMenuItem(value: 'ok', child: Text('En Stock')),
                      DropdownMenuItem(value: 'faible', child: Text('Faible')),
                      DropdownMenuItem(
                        value: 'rupture',
                        child: Text('Rupture'),
                      ),
                    ],
                    onChanged: (_) {},
                    isExpanded: true,
                    icon: const Icon(
                      Icons.filter_alt,
                      color: Color(0xFF7717E8),
                    ),
                  ),
                ),
                label: 'Statut',
              ),
              const SizedBox(height: 12),
              _FilterBox(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF7717E8),
                    ),
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                label: 'Recherche',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, color: Color(0xFF7717E8)),
                label: const Text(
                  'Export',
                  style: TextStyle(color: Color(0xFF7717E8)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF7717E8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                ),
              ),
            ] else ...[
              // Desktop : layout d'origine
              Row(
                children: [
                  Expanded(
                    child: _FilterBox(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'Toutes',
                          items: const [
                            DropdownMenuItem(
                              value: 'Toutes',
                              child: Text('Toutes'),
                            ),
                            DropdownMenuItem(
                              value: 'Boissons',
                              child: Text('Boissons'),
                            ),
                            DropdownMenuItem(
                              value: 'Snacks',
                              child: Text('Snacks'),
                            ),
                          ],
                          onChanged: (_) {},
                          isExpanded: true,
                          icon: const Icon(
                            Icons.category,
                            color: Color(0xFF7717E8),
                          ),
                        ),
                      ),
                      label: 'Catégorie',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FilterBox(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: 'Tous',
                          items: const [
                            DropdownMenuItem(
                              value: 'Tous',
                              child: Text('Tous'),
                            ),
                            DropdownMenuItem(
                              value: 'ok',
                              child: Text('En Stock'),
                            ),
                            DropdownMenuItem(
                              value: 'faible',
                              child: Text('Faible'),
                            ),
                            DropdownMenuItem(
                              value: 'rupture',
                              child: Text('Rupture'),
                            ),
                          ],
                          onChanged: (_) {},
                          isExpanded: true,
                          icon: const Icon(
                            Icons.filter_alt,
                            color: Color(0xFF7717E8),
                          ),
                        ),
                      ),
                      label: 'Statut',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _FilterBox(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF7717E8),
                          ),
                          hintText: 'Rechercher...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      label: 'Recherche',
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, color: Color(0xFF7717E8)),
                    label: const Text(
                      'Export',
                      style: TextStyle(color: Color(0xFF7717E8)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF7717E8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBox extends StatelessWidget {
  final Widget child;
  final String? label;
  final double? width;
  const _FilterBox({required this.child, this.label, this.width, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                label!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7717E8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: child,
          ),
        ],
      ),
    );
  }
}
