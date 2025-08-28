// widgets/invoice_content/mobile/simplified_mobile_invoice_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../providers/invoice_provider.dart';
import '../../invoice_common/invoice_common.dart';
import '../../invoice_detail/payment_dialog.dart';
import '../../cancel/cancel_invoice_dialog.dart';
import '../../../../services/invoice_service.dart';
import '../../../../routes/routes.dart';

class SimplifiedMobileInvoiceList extends StatelessWidget {
  final InvoiceProvider provider;

  const SimplifiedMobileInvoiceList({Key? key, required this.provider})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    return ListView.builder(
      itemCount: provider.invoices.length,
      itemBuilder: (context, index) {
        final invoice = provider.invoices[index];
        final resteAPayer = invoice.total - invoice.montantPaye;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        invoice.client.fullName.isNotEmpty
                            ? invoice.client.fullName
                            : 'Client introuvable',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    InvoiceStatusBadge(status: invoice.status),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'N° ${invoice.number}  •  ${formatDate.format(invoice.date)}',
                ),
                const SizedBox(height: 8),
                if (resteAPayer > 0)
                  Text.rich(
                    TextSpan(
                      text: 'Reste: ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: <TextSpan>[
                        TextSpan(
                          text: formatCurrency.format(resteAPayer),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepOrangeAccent,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    'Total: ${formatCurrency.format(invoice.total)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: InvoiceActionsMenu(
                    invoice: invoice,
                    onActionSelected: (action, invoice) {
                      _handleAction(context, action, invoice);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, String action, dynamic invoice) {
    switch (action) {
      case 'details':
        Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetail,
          arguments: invoice.id,
        );
        break;
      case 'pdf':
        _downloadPDFDirect(context, invoice);
        break;
      case 'payment':
        _showPaymentDialog(context, invoice);
        break;
      case 'cancel':
        _handleCancelInvoice(context, invoice);
        break;
    }
  }

  /// Télécharge directement le PDF
  Future<void> _downloadPDFDirect(BuildContext context, dynamic invoice) async {
    try {
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
              Text('Téléchargement PDF #${invoice.number}...'),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );

      final invoiceService = InvoiceService();
      final pdfUrl = await invoiceService.downloadInvoicePDFForced(invoice.id);

      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 16),
                  Text('PDF #${invoice.number} téléchargé !'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche le dialog de paiement
  Future<void> _showPaymentDialog(BuildContext context, dynamic invoice) async {
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

        if (context.mounted) {
          // Rafraîchir via le provider
          Provider.of<InvoiceProvider>(context, listen: false).refresh();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement enregistré avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'enregistrement du paiement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Gère l'annulation d'une facture avec confirmation
  Future<void> _handleCancelInvoice(
    BuildContext context,
    dynamic invoice,
  ) async {
    try {
      // Afficher le dialog de confirmation
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CancelInvoiceDialog(invoice: invoice),
      );

      if (result != null && result['confirmed'] == true) {
        final reason = result['reason'] as String;

        // Afficher un indicateur de chargement
        if (context.mounted) {
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
        }

        // Appeler le service d'annulation
        final invoiceService = InvoiceService();
        await invoiceService.cancelInvoice(invoice.id, reason);

        // Rafraîchir les données
        if (context.mounted) {
          Provider.of<InvoiceProvider>(context, listen: false).refresh();

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
        }
      }
    } catch (e) {
      if (context.mounted) {
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
          ),
        );
      }
    }
  }
}
