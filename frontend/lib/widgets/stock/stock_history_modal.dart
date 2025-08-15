import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'status_badge.dart';
import '../../controllers/stock_controller.dart';
import '../../models/stock.dart';
import '../../models/stock_movement.dart';

class StockHistoryModal extends StatefulWidget {
  final Stock stock;
  const StockHistoryModal({required this.stock, Key? key}) : super(key: key);

  @override
  State<StockHistoryModal> createState() => _StockHistoryModalState();
}

class _StockHistoryModalState extends State<StockHistoryModal> {
  final StockController _controller = StockController();

  // Filtres
  String _selectedPeriod = 'Derniers 30 jours';
  String _selectedUser = 'Tous';
  String _selectedType = 'Tous';

  // Options de filtres
  final List<String> _periods = [
    'Derniers 30 jours',
    'Ce mois',
    'Cette année',
    'Tout',
  ];
  List<String> _users = ['Tous'];
  List<String> _types = [
    'Tous',
    'vente',
    'correction',
    'achat',
    'entrée',
    'sortie',
  ];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    debugPrint(
      '[SCREEN][StockHistoryModal] Chargement historique pour ${widget.stock.description}',
    );

    // Calculer les dates selon la période sélectionnée
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedPeriod) {
      case 'Derniers 30 jours':
        startDate = DateTime.now().subtract(const Duration(days: 30));
        break;
      case 'Ce mois':
        startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
        break;
      case 'Cette année':
        startDate = DateTime(DateTime.now().year, 1, 1);
        break;
      case 'Tout':
        startDate = null;
        break;
    }

    await _controller.loadProductMovements(
      widget.stock.storeId,
      widget.stock.productId,
      startDate: startDate,
      endDate: endDate,
      userId: _selectedUser == 'Tous' ? null : _selectedUser,
      type: _selectedType == 'Tous' ? null : _selectedType,
    );

    // Mettre à jour les listes d'utilisateurs disponibles
    _updateFilterOptions();

    setState(() {});
  }

  void _updateFilterOptions() {
    // Extraire les utilisateurs uniques des mouvements
    final uniqueUsers = _controller.movements
        .map((m) => m.userName ?? 'Utilisateur inconnu')
        .toSet()
        .toList();

    _users = ['Tous', ...uniqueUsers];

    // Extraire les types uniques
    final uniqueTypes = _controller.movements
        .map((m) => m.type)
        .toSet()
        .toList();

    _types = ['Tous', ...uniqueTypes];
  }

  void _onFilterChanged() {
    _loadMovements();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          final dialogWidth = screenWidth * 0.6 > 900
              ? 900.0
              : screenWidth * 0.6;
          final width = isMobile
              ? MediaQuery.of(context).size.width * 0.965
              : dialogWidth;
          return SizedBox(
            width: width,
            child: isMobile
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header violet responsive
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF7717E8), Color(0xFFB388FF)],
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Historique',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Text(
                                  widget.stock.description ?? 'Produit',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Card de filtres modernisée
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        const InputDecorationTheme(
                                          labelStyle: TextStyle(fontSize: 13),
                                          hintStyle: TextStyle(fontSize: 13),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPeriod,
                                    items: _periods
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(
                                              p,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPeriod = value!;
                                      });
                                      _onFilterChanged();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Période',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        const InputDecorationTheme(
                                          labelStyle: TextStyle(fontSize: 13),
                                          hintStyle: TextStyle(fontSize: 13),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedUser,
                                    items: _users
                                        .map(
                                          (u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              u,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedUser = value!;
                                      });
                                      _onFilterChanged();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Utilisateur',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    inputDecorationTheme:
                                        const InputDecorationTheme(
                                          labelStyle: TextStyle(fontSize: 13),
                                          hintStyle: TextStyle(fontSize: 13),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedType,
                                    items: _types
                                        .map(
                                          (t) => DropdownMenuItem(
                                            value: t,
                                            child: Text(
                                              t,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedType = value!;
                                      });
                                      _onFilterChanged();
                                    },
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Affichage historique avec loading/erreur
                        _buildMovementsContent(isMobile),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header violet responsive
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7717E8), Color(0xFFB388FF)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Historique : ${widget.stock.description ?? 'Produit'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Card de filtres modernisée
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedPeriod,
                                  items: _periods
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPeriod = value!;
                                    });
                                    _onFilterChanged();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Période',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedUser,
                                  items: _users
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(u),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedUser = value!;
                                    });
                                    _onFilterChanged();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Utilisateur',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  items: _types
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedType = value!;
                                    });
                                    _onFilterChanged();
                                  },
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Affichage historique avec loading/erreur
                      Expanded(child: _buildMovementsContent(isMobile)),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildMovementsContent(bool isMobile) {
    if (_controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF7717E8)),
              SizedBox(height: 16),
              Text('Chargement de l\'historique...'),
            ],
          ),
        ),
      );
    }

    if (_controller.error != null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _controller.error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMovements,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller.movements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun mouvement trouvé',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun mouvement de stock pour ce produit dans la période sélectionnée.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Affichage des mouvements
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: _controller.movements
              .map((movement) => _HistoryCard(movement))
              .toList(),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF7717E8),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
                  if (states.contains(MaterialState.hovered)) {
                    return const Color(0xFFF8F8FA);
                  }
                  return null;
                }),
                columnSpacing: 18,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('Date/Heure')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Quantité')),
                  DataColumn(label: Text('Stock Résultant')),
                  DataColumn(label: Text('Utilisateur')),
                  DataColumn(label: Text('Référence/Raison')),
                ],
                rows: _controller.movements
                    .map(
                      (movement) => DataRow(
                        cells: [
                          DataCell(Text(_formatDateTime(movement.createdAt))),
                          DataCell(_buildMouvementBadge(movement.type)),
                          DataCell(
                            Text(
                              '${movement.quantity > 0 ? '+' : ''}${movement.quantity}',
                            ),
                          ),
                          DataCell(Text('${movement.newQuantity}')),
                          DataCell(
                            Text(movement.userName ?? 'Utilisateur inconnu'),
                          ),
                          DataCell(Text(movement.reason ?? '-')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Carte historique mobile
Widget _HistoryCard(StockMovement movement) {
  Color color;
  IconData icon;
  switch (movement.type) {
    case 'vente':
      color = const Color(0xFF3F51B5);
      icon = Icons.south; // flèche vers le bas
      break;
    case 'correction':
      color = const Color(0xFF7717E8);
      icon = Icons.remove;
      break;
    case 'achat':
      color = const Color(0xFF27AE60);
      icon = Icons.north; // flèche vers le haut
      break;
    case 'entrée':
      color = const Color(0xFF1976D2);
      icon = Icons.north; // flèche vers le haut
      break;
    case 'sortie':
      color = const Color(0xFFEB5757);
      icon = Icons.south; // flèche vers le bas
      break;
    default:
      color = Colors.grey;
      icon = Icons.info;
  }

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${movement.type.substring(0, 1).toUpperCase()}${movement.type.substring(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${movement.quantity > 0 ? '+' : ''}${movement.quantity}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Le ${_formatDateTime(movement.createdAt)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  movement.reason?.startsWith('Facture') == true ||
                          movement.reason?.startsWith('Achat') == true
                      ? 'Réf: ${movement.reason}'
                      : 'Raison: ${movement.reason ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${movement.newQuantity} | Par: ${movement.userName ?? 'Utilisateur inconnu'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatDateTime(DateTime dateTime) {
  return '${dateTime.day.toString().padLeft(2, '0')}/'
      '${dateTime.month.toString().padLeft(2, '0')}/'
      '${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}

StatusBadge _buildMouvementBadge(String type) {
  Color color;
  String label;
  IconData icon;
  switch (type) {
    case 'vente':
      color = const Color(0xFF3F51B5);
      label = 'Vente';
      icon = Icons.shopping_cart;
      break;
    case 'correction':
      color = const Color(0xFF7717E8);
      label = 'Correction';
      icon = Icons.build;
      break;
    case 'achat':
      color = const Color(0xFF27AE60);
      label = 'Achat';
      icon = Icons.add_shopping_cart;
      break;
    case 'entrée':
      color = const Color(0xFF1976D2);
      label = 'Entrée';
      icon = Icons.arrow_downward;
      break;
    case 'sortie':
      color = const Color(0xFFEB5757);
      label = 'Sortie';
      icon = Icons.arrow_upward;
      break;
    default:
      color = Colors.grey;
      label = type;
      icon = Icons.info;
  }
  return StatusBadge(label: label, color: color, icon: icon);
}