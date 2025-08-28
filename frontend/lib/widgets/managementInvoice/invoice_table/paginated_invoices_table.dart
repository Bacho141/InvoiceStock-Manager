// widgets/invoice_table/paginated_invoices_table.dart
import 'package:flutter/material.dart';
import '../../../providers/invoice_provider.dart';
import 'invoice_data_source.dart';

class PaginatedInvoicesTable extends StatefulWidget {
  final InvoiceProvider provider;

  const PaginatedInvoicesTable({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  State<PaginatedInvoicesTable> createState() => _PaginatedInvoicesTableState();
}

class _PaginatedInvoicesTableState extends State<PaginatedInvoicesTable> {
  int _sortColumnIndex = 3; // Default sort by date
  bool _sortAscending = false; // Default descending
  late InvoiceDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = InvoiceDataSource(widget.provider, context);
    widget.provider.addListener(_onProviderChanged);
  }

  @override
  void didUpdateWidget(PaginatedInvoicesTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      oldWidget.provider.removeListener(_onProviderChanged);
      widget.provider.addListener(_onProviderChanged);
      _dataSource.updateProvider(widget.provider);
    }
  }

  void _onProviderChanged() {
    // The provider has changed, so we need to update the data source.
    // We can just create a new data source, which will be simpler.
    setState(() {
      _dataSource = InvoiceDataSource(widget.provider, context);
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    _dataSource.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PaginatedDataTable(
        header: const Text('Liste des factures'),
        rowsPerPage: widget.provider.pageSize,
        availableRowsPerPage: const [5, 10, 20],
        onRowsPerPageChanged: (value) {
          // TODO: Add logic to change page size in provider
        },
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        source: _dataSource,
        onSelectAll: (isSelected) {
          widget.provider.selectAll(isSelected ?? false);
        },
        columns: _buildColumns(),
        onPageChanged: (firstRowIndex) {
          final newPage = (firstRowIndex ~/ widget.provider.pageSize) + 1;
          widget.provider.changePage(newPage);
        },
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(label: Text('Statut')),
      const DataColumn(label: Text('N° Facture')),
      const DataColumn(label: Text('Client')),
      DataColumn(
        label: const Text('Date'),
        onSort: (columnIndex, ascending) {
          // TODO: Implement sorting logic in provider
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortAscending = ascending;
          });
        },
        numeric: true,
      ),
      const DataColumn(label: Text('Total TTC'), numeric: true),
      const DataColumn(label: Text('Reste à Payer'), numeric: true),
      const DataColumn(label: Text('Actions')),
    ];
  }
}