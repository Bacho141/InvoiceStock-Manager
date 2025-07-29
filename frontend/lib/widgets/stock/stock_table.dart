import 'package:flutter/material.dart';
import 'status_badge.dart';
import 'stock_history_modal.dart';
import 'stock_transfer_modal.dart';
import 'stock_detail_modal.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../models/stock.dart';

class StockTable extends StatelessWidget {
  final List<Stock> stocks;
  const StockTable({Key? key, required this.stocks}) : super(key: key);

  void _showTransferModal(BuildContext context, Stock stock) {
    showDialog(context: context, builder: (_) => const StockTransferModal());
  }

  void _showHistoryModal(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (_) => StockHistoryModal(stock: stock),
    );
  }

  void _showDetail(BuildContext context, Stock stock) {
    showDialog(
      context: context,
      builder: (_) => StockDetailModal(stock: stock),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        if (isMobile) {
          // Version mobile : cartes Material
          return ListView.separated(
            shrinkWrap: true,
            itemCount: stocks.length,
            separatorBuilder: (_, __) => SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = stocks[i];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: SizedBox(
                          height: 26,
                          child: _buildStatusBadge(
                            s.quantity == 0
                                ? 'rupture'
                                : (s.quantity <= s.minQuantity
                                      ? 'faible'
                                      : 'ok'),
                            fontSize: 11,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Qté: ${s.quantity} | Seuil: ${s.minQuantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.swap_horiz,
                                  color: Color(0xFF7717E8),
                                ),
                                tooltip: 'Transférer',
                                onPressed: () => _showTransferModal(context, s),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Color(0xFF7717E8),
                                ),
                                tooltip: 'Détail',
                                onPressed: () => _showDetail(context, s),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.history,
                                  color: Color(0xFF7717E8),
                                ),
                                tooltip: 'Historique',
                                onPressed: () => _showHistoryModal(context, s),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          // Version desktop : DataTable2
          final maxRows = 7;
          final rowHeight = 56.0;
          final tableHeight = (maxRows * rowHeight) + 56;
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(12),
                thickness: 8,
                child: SizedBox(
                  height: tableHeight,
                  child: DataTable2(
                    minWidth: 700,
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFF7717E8),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>((
                      states,
                    ) {
                      if (states.contains(MaterialState.hovered)) {
                        return const Color(0xFFF8F8FA);
                      }
                      return null;
                    }),
                    columnSpacing: 32,
                    horizontalMargin: 24,
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey.shade200),
                    ),
                    isHorizontalScrollBarVisible: false,
                    isVerticalScrollBarVisible: true,
                    empty: const SizedBox.shrink(),
                    dataRowHeight: rowHeight,
                    headingRowHeight: 56,
                    fixedTopRows: 1, // header sticky
                    scrollController: null,
                    smRatio: 0.7,
                    lmRatio: 1.2,
                    columns: const [
                      DataColumn2(label: Text('Produit'), size: ColumnSize.L),
                      DataColumn2(
                        label: Text('Qté en Stock'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(
                        label: Text('Seuil Critique'),
                        size: ColumnSize.S,
                      ),
                      DataColumn2(label: Text('Statut'), size: ColumnSize.M),
                      DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                    ],
                    rows: stocks
                        .map(
                          (s) => DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  s.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${s.quantity}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${s.minQuantity}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              DataCell(
                                _buildStatusBadge(
                                  s.quantity == 0
                                      ? 'rupture'
                                      : (s.quantity <= s.minQuantity
                                            ? 'faible'
                                            : 'ok'),
                                ),
                              ),
                              DataCell(
                                _ActionsMenu(
                                  onTransfer: () =>
                                      _showTransferModal(context, s),
                                  onDetail: () => _showDetail(context, s),
                                  onHistory: () =>
                                      _showHistoryModal(context, s),
                                ),
                              ),
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
      },
    );
  }
}

StatusBadge _buildStatusBadge(
  String statut, {
  double fontSize = 13,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  ),
}) {
  Color color;
  String label;
  IconData icon;
  switch (statut) {
    case 'ok':
      color = const Color(0xFF27AE60);
      label = 'En Stock';
      icon = Icons.check_circle;
      break;
    case 'faible':
      color = const Color(0xFFF2994A);
      label = 'Faible';
      icon = Icons.warning;
      break;
    case 'rupture':
      color = const Color(0xFFEB5757);
      label = 'Rupture';
      icon = Icons.error;
      break;
    default:
      color = Colors.grey;
      label = statut;
      icon = Icons.info;
  }
  return StatusBadge(
    label: label,
    color: color,
    icon: icon,
    fontSize: fontSize,
    padding: padding,
  );
}

class _ActionsMenu extends StatelessWidget {
  final VoidCallback onTransfer;
  final VoidCallback onDetail;
  final VoidCallback onHistory;
  const _ActionsMenu({
    required this.onTransfer,
    required this.onDetail,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF7717E8)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          child: Row(
            children: const [
              Icon(Icons.swap_horiz, color: Color(0xFF7717E8)),
              SizedBox(width: 8),
              Text('Transférer'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: Row(
            children: const [
              Icon(Icons.visibility, color: Color(0xFF7717E8)),
              SizedBox(width: 8),
              Text('Détail'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: const [
              Icon(Icons.history, color: Color(0xFF7717E8)),
              SizedBox(width: 8),
              Text('Historique'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 0) onTransfer();
        if (value == 1) onDetail();
        if (value == 2) onHistory();
      },
    );
  }
}
