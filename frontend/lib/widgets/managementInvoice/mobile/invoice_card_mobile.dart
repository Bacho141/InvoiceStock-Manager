import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/invoice.dart';
import '../../../providers/invoice_provider.dart';
import '../../../services/invoice_service.dart';
import '../../managementInvoice/invoice_detail/payment_dialog.dart';
import '../cancel/cancel_invoice_dialog.dart';
import '../../../routes/routes.dart'; // Import des routes

class InvoiceCardMobile extends StatelessWidget {
  final Invoice invoice;

  const InvoiceCardMobile({Key? key, required this.invoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'F',
      decimalDigits: 0,
    );
    final formatDate = DateFormat('dd/MM/yy');
    final resteAPayer = invoice.total - invoice.montantPaye;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleAction('details', invoice, context),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildActionsMenu(context, invoice),
                ],
              ),
              const SizedBox(height: 4),
              Text('#${invoice.number} | ${formatDate.format(invoice.date)}'),
              const SizedBox(height: 12),
              if (resteAPayer > 0)
                Text.rich(
                  TextSpan(
                    text: 'Reste à Payer : ',
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
                  'Total : ${formatCurrency.format(invoice.total)}',
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomLeft,
                child: _buildStatusBadge(invoice.status),
              ),
            ],
          ),
        ),
      ),
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
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      labelPadding: const EdgeInsets.only(left: 4),
    );
  }

  void _handleAction(
    String action,
    Invoice invoice,
    BuildContext context,
  ) async {
    switch (action) {
      case 'details':
        Navigator.pushNamed(
          context,
          AppRoutes.invoiceDetail,
          arguments: invoice.id,
        );
        break;
      case 'pdf':
        await _downloadPDFDirect(context, invoice);
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
            Provider.of<InvoiceProvider>(context, listen: false).refresh();
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
                  'Erreur lors de l\'enregistrement du paiement: $e',
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

  Widget _buildActionsMenu(BuildContext context, Invoice invoice) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleAction(value, invoice, context),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Voir les détails'),
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Télécharger PDF'),
          ),
        ),
        if (invoice.status == 'reste_a_payer' || invoice.status == 'en_attente')
          const PopupMenuItem(
            value: 'payment',
            child: ListTile(
              leading: Icon(Icons.payment),
              title: Text('Enregistrer un paiement'),
            ),
          ),
        if (invoice.status != 'annulee')
          const PopupMenuItem(
            value: 'cancel',
            child: ListTile(
              leading: Icon(Icons.cancel_outlined),
              title: Text('Annuler la facture'),
            ),
          ),
      ],
    );
  }

  /// Télécharge directement le PDF sans menu d'options
  Future<void> _downloadPDFDirect(BuildContext context, Invoice invoice) async {
    debugPrint(
      '[InvoiceCardMobile] Téléchargement direct PDF facture ${invoice.id}',
    );

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
      debugPrint('[InvoiceCardMobile] URL PDF obtenue: $pdfUrl');

      // Lancer le téléchargement avec mode platformDefault pour forcer la sauvegarde
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        debugPrint('[InvoiceCardMobile] Lancement du téléchargement...');

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
      } else {
        throw Exception('Impossible de lancer le téléchargement');
      }
    } catch (e) {
      debugPrint('[InvoiceCardMobile] Erreur téléchargement: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        String errorMessage = 'Erreur lors du téléchargement du PDF';

        // Messages d'erreur spécifiques
        if (e.toString().contains('Permission denied')) {
          errorMessage = 'Erreur de permission. Vérifiez les autorisations.';
        } else if (e.toString().contains('Network')) {
          errorMessage =
              'Erreur de connexion. Vérifiez votre connexion internet.';
        } else if (e.toString().contains('Token')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: () => _downloadPDFDirect(context, invoice),
            ),
          ),
        );
      }
    }
  }

  /// Gère l'annulation d'une facture avec confirmation
  Future<void> _handleCancelInvoice(
    BuildContext context,
    Invoice invoice,
  ) async {
    debugPrint(
      '[InvoiceCardMobile] Demande d\'annulation facture ${invoice.id}',
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
        debugPrint('[InvoiceCardMobile] Confirmation reçue, motif: $reason');

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

        debugPrint(
          '[InvoiceCardMobile] Facture ${invoice.id} annulée avec succès',
        );
      } else {
        debugPrint('[InvoiceCardMobile] Annulation annulée par l\'utilisateur');
      }
    } catch (e) {
      debugPrint('[InvoiceCardMobile] Erreur lors de l\'annulation: $e');

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
  }
}
