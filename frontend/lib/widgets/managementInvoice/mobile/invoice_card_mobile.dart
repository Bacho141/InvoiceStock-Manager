import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/invoice.dart';

class InvoiceCardMobile extends StatelessWidget {
  final Invoice invoice;

  const InvoiceCardMobile({Key? key, required this.invoice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0);
    final formatDate = DateFormat('dd/MM/yy');
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
                Flexible(
                  child: Text(
                    invoice.client.fullName.isNotEmpty ? invoice.client.fullName : 'Client introuvable',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrangeAccent),
                    ),
                  ],
                ),
              )
            else
              Text('Total : ${formatCurrency.format(invoice.total)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomLeft,
              child: _buildStatusBadge(invoice.status),
            ),
          ],
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
