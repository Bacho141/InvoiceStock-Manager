// widgets/invoice_table/invoice_data_source.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/invoice_provider.dart';
import '../invoice_common/invoice_common.dart';
import '../invoice_detail/payment_dialog.dart';
import '../cancel/cancel_invoice_dialog.dart';
import '../../../services/invoice_service.dart';
import '../../../routes/routes.dart'; // Import des routes

class InvoiceDataSource extends DataTableSource {
  InvoiceProvider _provider;
  final BuildContext context;
  final formatCurrency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'F',
    decimalDigits: 0,
  );
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
      return const DataRow(cells: [DataCell(Text(''))]);
    }

    final invoice = _provider.invoices[localIndex];

    return DataRow.byIndex(
      index: index,
      selected: _provider.selectedInvoices.contains(invoice.id),
      onSelectChanged: (isSelected) {
        _provider.selectInvoice(invoice.id, isSelected ?? false);
      },
      cells: [
        DataCell(InvoiceStatusBadge(status: invoice.status, isChip: false)),
        DataCell(Text(invoice.number)),
        DataCell(
          Text(
            invoice.client.fullName.isNotEmpty
                ? invoice.client.fullName
                : 'Client introuvable',
          ),
        ),
        DataCell(Text(formatDate.format(invoice.date))),
        DataCell(Text(formatCurrency.format(invoice.total))),
        DataCell(
          Text(formatCurrency.format(invoice.total - invoice.montantPaye)),
        ),
        DataCell(
          InvoiceActionsMenu(
            invoice: invoice,
            isCompact: true,
            onActionSelected: (action, invoice) {
              _handleAction(action, invoice);
            },
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, dynamic invoice) async {
    switch (action) {
      case 'details':
        Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetail,
          arguments: invoice.id,
        );
        break;
      case 'pdf':
        // TODO: Implement PDF download
        break;
      case 'payment':
        final result = await showDialog(
          context: context,
          builder: (context) =>
              PaymentDialog(initialAmount: invoice.total - invoice.montantPaye),
        );
        if (result != null) {
          try {
            final invoiceService = InvoiceService();
            await invoiceService.addPayment(
              invoice.id,
              result['amount'],
              result['method'],
            );
            _provider.refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement enregistré avec succès'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Erreur lors de l'enregistrement du paiement: $e",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
      case 'cancel':
        await _handleCancelInvoice(context, invoice);
        break;
    }
  }

  /// Gère l'annulation d'une facture avec confirmation
  Future<void> _handleCancelInvoice(BuildContext context, invoice) async {
    debugPrint(
      '[InvoiceDataSource] Demande d\'annulation facture ${invoice.id}',
    );

    try {
      // Afficher le dialog de confirmation
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CancelInvoiceDialog(invoice: invoice),
      );

      if (result != null && result['confirmed'] == true) {
        final reason = result['reason'] as String;
        debugPrint('[InvoiceDataSource] Confirmation reçue, motif: $reason');

        // Afficher un indicateur de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Annulation de la facture ${invoice.number}...'),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );

        // Appeler le service d'annulation
        final invoiceService = InvoiceService();
        await invoiceService.cancelInvoice(invoice.id, reason);

        // Rafraîchir les données
        _provider.refresh();

        // Masquer le snackbar de chargement et afficher le succès
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                Text('Facture ${invoice.number} annulée avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        debugPrint(
          '[InvoiceDataSource] Facture ${invoice.id} annulée avec succès',
        );
      } else {
        debugPrint('[InvoiceDataSource] Annulation annulée par l\'utilisateur');
      }
    } catch (e) {
      debugPrint('[InvoiceDataSource] Erreur lors de l\'annulation: $e');

      // Masquer le snackbar de chargement
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String errorMessage = 'Erreur lors de l\'annulation de la facture';

      // Messages d'erreur spécifiques
      if (e.toString().contains('déjà annulée')) {
        errorMessage = 'Cette facture est déjà annulée';
      } else if (e.toString().contains('introuvable')) {
        errorMessage = 'Facture introuvable';
      } else if (e.toString().contains('Token')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter';
      } else if (e.toString().contains('stock')) {
        errorMessage = 'Erreur lors de la remise en stock des produits';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Fermer',
            textColor: Colors.white,
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _provider.totalInvoices;

  @override
  int get selectedRowCount => _provider.selectedInvoices.length;
}
