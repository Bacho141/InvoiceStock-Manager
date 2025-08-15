import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

import '../../models/invoice.dart';
import '../../providers/invoice_provider.dart';
import '../../services/invoice_service.dart';
import '../../layout/main_layout.dart';
import '../../widgets/managementInvoice/period_filter_dialog.dart';

import './mobile/invoice_list_mobile_view.dart';

class InvoicesListScreen extends StatelessWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceProvider(InvoiceService()),
      child: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          return MainLayout(
            currentRoute: '/invoices',
            pageTitle: '📄 Gestion des Factures',
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return Column(
                    children: [
                      _buildFilterBar(context, provider),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildContent(context, provider),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      // Mobile filter bar (search and filter button)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (value) => provider.setSearchTerm(value),
                                decoration: const InputDecoration(
                                  hintText: '🔍 Recherche...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) {
                                    return ChangeNotifierProvider.value(
                                      value: provider,
                                      child: _buildFilterModal(context, provider),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.filter_list),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: InvoiceListMobileView(provider: provider),
                      ),
                    ],
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterModal(BuildContext context, InvoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Filtres', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildDropdownFilter(
            hint: 'Statut',
            value: provider.statusFilter,
            items: {
              '': 'Tous',
              'payee': 'Payée',
              'reste_a_payer': 'Reste à payer',
              'en_attente': 'En attente',
              'annulee': 'Annulée',
            },
            onChanged: (value) => provider.setStatusFilter(value),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ChangeNotifierProvider.value(
                    value: provider,
                    child: const PeriodFilterDialog(),
                  );
                },
              );
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(provider.periodFilterText),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterBar(BuildContext context, InvoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Partie gauche - Filtres
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  onSubmitted: (value) => provider.setSearchTerm(value),
                  decoration: const InputDecoration(
                    hintText: '🔍 Rech. (N°, client)...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 180,
                child: _buildDropdownFilter(
                  hint: 'Statut',
                  value: provider.statusFilter,
                  items: {
                    '': 'Tous',
                    'payee': 'Payée',
                    'reste_a_payer': 'Reste à payer',
                    'en_attente': 'En attente',
                    'annulee': 'Annulée',
                  },
                  onChanged: (value) => provider.setStatusFilter(value),
                ),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 200,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ChangeNotifierProvider.value(
                          value: provider,
                          child: const PeriodFilterDialog(),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(provider.periodFilterText),
                  style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Colors.deepPurple),
                ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: Handle bulk actions
                },
                enabled: provider.selectedInvoices.isNotEmpty,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'download_pdf',
                    child: Text('Télécharger les PDF'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Actions',
                        style: TextStyle(
                          color: provider.selectedInvoices.isNotEmpty ? Colors.black : Colors.grey,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: provider.selectedInvoices.isNotEmpty ? Colors.black : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Partie droite - Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/new-sale'),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text(' Nouvelle Vente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      items: items.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildContent(BuildContext context, InvoiceProvider provider) {

    // État de chargement
    if (provider.isLoading && provider.invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement des factures...', 
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Veuillez patienter un moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // État d'erreur
    if (provider.error != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oups ! Une erreur est survenue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => provider.loadInvoices(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Ouvrir support ou aide
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Aide'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // État vide
    if (provider.invoices.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucune facture trouvée',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Il semble qu\'il n\'y ait aucune facture correspondant à vos critères de recherche.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/new-sale'),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Créer une facture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Réinitialiser les filtres
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Effacer filtres'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _PaginatedInvoicesTable(provider: provider);
        } else {
          return _buildMobileView(context, provider);
        }
      },
    );
  }

  Widget _buildMobileView(BuildContext context, InvoiceProvider provider) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final formatDate = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      itemCount: provider.invoices.length,
      itemBuilder: (context, index) {
        final invoice = provider.invoices[index];
        final resteAPayer = invoice.total - invoice.montantPaye;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(invoice.client.fullName.isNotEmpty ? invoice.client.fullName : 'Client introuvable', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
                    _buildStatusBadge(invoice.status),
                  ],
                ),
                const Divider(height: 20),
                Text('N° ${invoice.number}  •  ${formatDate.format(invoice.date)}'),
                const SizedBox(height: 8),
                if (resteAPayer > 0)
                  Text.rich(
                    TextSpan(
                      text: 'Reste: ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: <TextSpan>[
                        TextSpan(
                          text: formatCurrency.format(resteAPayer),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrangeAccent),
                        ),
                      ],
                    ),
                  )
                else
                  Text('Total: ${formatCurrency.format(invoice.total)}', style: const TextStyle(fontSize: 16)),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildActionsMenu(context, invoice),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'payee':
        color = Colors.green.shade700;
        text = 'Payée';
        icon = Icons.check_circle;
        break;
      case 'reste_a_payer':
        color = Colors.orange.shade800;
        text = 'Reste à payer';
        icon = Icons.hourglass_bottom;
        break;
      case 'annulee':
        color = Colors.red.shade700;
        text = 'Annulée';
        icon = Icons.cancel;
        break;
      case 'en_attente':
        color = Colors.blue.shade700;
        text = 'En attente';
        icon = Icons.pause_circle;
        break;
      default:
        color = Colors.grey.shade600;
        text = status;
        icon = Icons.info;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      labelPadding: const EdgeInsets.only(left: 4),
    );
  }

  Widget _buildActionsMenu(BuildContext context, Invoice invoice) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        // TODO: Handle actions like navigation to detail, showing dialogs, etc.
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'details', child: ListTile(leading: Icon(Icons.visibility), title: Text('Voir les détails'))),
        const PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Télécharger PDF'))),
        if (invoice.status == 'reste_a_payer' || invoice.status == 'en_attente')
          const PopupMenuItem(value: 'payment', child: ListTile(leading: Icon(Icons.payment), title: Text('Enregistrer un paiement'))),
        if (invoice.status != 'annulee')
          const PopupMenuItem(value: 'cancel', child: ListTile(leading: Icon(Icons.cancel_outlined), title: Text('Annuler la facture'))),
      ],
    );
  }
}

class _PaginatedInvoicesTable extends StatefulWidget {
  final InvoiceProvider provider;
  const _PaginatedInvoicesTable({Key? key, required this.provider}) : super(key: key);

  @override
  State<_PaginatedInvoicesTable> createState() => _PaginatedInvoicesTableState();
}

class _PaginatedInvoicesTableState extends State<_PaginatedInvoicesTable> {
  int _sortColumnIndex = 3; // Default sort by date
  bool _sortAscending = false; // Default descending

  @override
  Widget build(BuildContext context) {
    final dataSource = InvoiceDataSource(widget.provider, context);
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
        source: dataSource,
        onSelectAll: (isSelected) {
          widget.provider.selectAll(isSelected ?? false);
        },
        columns: [
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
            numeric: true
          ),
          const DataColumn(label: Text('Total TTC'), numeric: true),
          const DataColumn(label: Text('Reste à Payer'), numeric: true),
          const DataColumn(label: Text('Actions')),
        ],
        onPageChanged: (firstRowIndex) {
          final newPage = (firstRowIndex ~/ widget.provider.pageSize) + 1;
          widget.provider.changePage(newPage);
        },
      ),
    );
  }
}

class InvoiceDataSource extends DataTableSource {
  InvoiceProvider _provider;
  final BuildContext context;
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
  final formatDate = DateFormat('dd/MM/yyyy');

  InvoiceDataSource(this._provider, this.context);

  void updateProvider(InvoiceProvider provider) {
    _provider = provider;
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    final localIndex = index % _provider.pageSize;
    if (localIndex >= _provider.invoices.length) {
      return const DataRow(cells: [DataCell(Text(''))]); // Should not happen
    }
    final invoice = _provider.invoices[localIndex];
    
    return DataRow.byIndex(
      index: index,
      selected: _provider.selectedInvoices.contains(invoice.id),
      onSelectChanged: (isSelected) {
        _provider.selectInvoice(invoice.id, isSelected ?? false);
      },
      cells: [
        DataCell(_buildStatusBadge(invoice.status, isChip: false)),
        DataCell(Text(invoice.number)),
        DataCell(Text(invoice.client.fullName.isNotEmpty ? invoice.client.fullName : 'Client introuvable')),
        DataCell(Text(formatDate.format(invoice.date))),
        DataCell(Text(formatCurrency.format(invoice.total))),
        DataCell(Text(formatCurrency.format(invoice.total - invoice.montantPaye))),
        DataCell(_buildActionsMenu(context, invoice)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _provider.totalInvoices;

  @override
  int get selectedRowCount => _provider.selectedInvoices.length;

  Widget _buildStatusBadge(String status, {bool isChip = true}) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'payee': color = Colors.green.shade700; text = 'Payée'; icon = Icons.check_circle; break;
      case 'reste_a_payer': color = Colors.orange.shade800; text = 'Reste à payer'; icon = Icons.hourglass_bottom; break;
      case 'annulee': color = Colors.red.shade700; text = 'Annulée'; icon = Icons.cancel; break;
      case 'en_attente': color = Colors.blue.shade700; text = 'En attente'; icon = Icons.pause_circle; break;
      default: color = Colors.grey.shade600; text = status; icon = Icons.info;
    }

    if (isChip) {
      return Chip(
        avatar: Icon(icon, color: Colors.white, size: 16),
        label: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionsMenu(BuildContext context, Invoice invoice) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) { /* TODO: Handle actions */ },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'details', child: Text('Détails')),
        const PopupMenuItem(value: 'pdf', child: Text('PDF')),
        if (invoice.status == 'reste_a_payer' || invoice.status == 'en_attente')
          const PopupMenuItem(value: 'payment', child: Text('Payer')),
        if (invoice.status != 'annulee')
          const PopupMenuItem(value: 'cancel', child: Text('Annuler')),
      ],
    );
  }
}