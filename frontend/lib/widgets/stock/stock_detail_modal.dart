import 'package:flutter/material.dart';
import 'status_badge.dart';
import '../../models/stock.dart';

class StockDetailModal extends StatelessWidget {
  final Stock stock;
  const StockDetailModal({required this.stock, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.4;
    final width = screenWidth < 600
        ? screenWidth * 0.965
        : (dialogWidth < 350
              ? 350.0
              : (dialogWidth > 520 ? 520.0 : dialogWidth));
    final isMobile = screenWidth < 600;
    return Dialog(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minWidth: isMobile ? constraints.maxWidth : 350,
              maxWidth: width,
            ),
            padding: EdgeInsets.all(isMobile ? 10 : 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Color(0xFF7717E8),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Détails : ${stock.description ?? 'Produit sans nom'}',
                        style: const TextStyle(
                          color: Color(0xFF7717E8),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF7717E8)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      width: double.infinity,
                      constraints: isMobile
                          ? const BoxConstraints(maxWidth: 600)
                          : null,
                      decoration: BoxDecoration(
                        gradient: isMobile
                            ? const LinearGradient(
                                colors: [Color(0xFFF8F6FF), Color(0xFFEDE7F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isMobile ? null : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF7717E8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.store,
                                color: Color(0xFF7717E8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Magasin',
                                style: TextStyle(
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 28,
                              top: 2,
                              bottom: 8,
                            ),
                            child: Text(
                              stock.storeName ?? 'Magasin inconnu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.inventory_2,
                                color: Color(0xFF7717E8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Stock actuel',
                                style: TextStyle(
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 28,
                              top: 2,
                              bottom: 8,
                            ),
                            child: Text(
                              '${stock.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFF7717E8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Stock minimum',
                                style: TextStyle(
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 28,
                              top: 2,
                              bottom: 8,
                            ),
                            child: Text(
                              '${stock.minQuantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF7717E8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Statut',
                                style: TextStyle(
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, top: 2),
                            child: StatusBadge(
                              label: stock.quantity == 0
                                  ? 'Rupture'
                                  : (stock.quantity <= stock.minQuantity
                                        ? 'Faible'
                                        : (stock.isActive
                                              ? 'Actif'
                                              : 'Inactif')),
                              color: stock.quantity == 0
                                  ? const Color(0xFFEB5757)
                                  : (stock.quantity <= stock.minQuantity
                                        ? const Color(0xFFF2994A)
                                        : (stock.isActive
                                              ? const Color(0xFF27AE60)
                                              : const Color(0xFFBDBDBD))),
                              icon: stock.quantity == 0
                                  ? Icons.error
                                  : (stock.quantity <= stock.minQuantity
                                        ? Icons.warning
                                        : (stock.isActive
                                              ? Icons.check_circle
                                              : Icons.remove_circle_outline)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color(0xFF7717E8),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Dernière mise à jour',
                                style: TextStyle(
                                  color: Color(0xFF7717E8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 28, top: 2),
                            child: Text(
                              '${stock.lastUpdated.day.toString().padLeft(2, '0')}/'
                              '${stock.lastUpdated.month.toString().padLeft(2, '0')}/'
                              '${stock.lastUpdated.year} à '
                              '${stock.lastUpdated.hour.toString().padLeft(2, '0')}:'
                              '${stock.lastUpdated.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Color(0xFF7717E8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Statistiques récentes (mock)',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ventes 30j : 42 | Entrées 30j : 60 | Sorties 30j : 18',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: isMobile
                        ? Tooltip(
                            message: 'Transférer',
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7717E8),
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(18),
                                elevation: 6,
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('Transférer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7717E8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'Actif':
        return 'Actif';
      case 'Inactif':
        return 'Inactif';
      case 'Rupture':
        return 'Rupture';
      default:
        return statut ?? '';
    }
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'Actif':
        return const Color(0xFF27AE60);
      case 'Inactif':
        return const Color(0xFFBDBDBD);
      case 'Rupture':
        return const Color(0xFFEB5757);
      default:
        return const Color(0xFF7717E8);
    }
  }

  IconData _statutIcon(String? statut) {
    switch (statut) {
      case 'Actif':
        return Icons.check_circle;
      case 'Inactif':
        return Icons.remove_circle_outline;
      case 'Rupture':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
