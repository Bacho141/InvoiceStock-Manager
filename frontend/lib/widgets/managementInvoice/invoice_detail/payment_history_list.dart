import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/invoice.dart';

class PaymentHistoryList extends StatelessWidget {
  final List<PaymentHistory> paymentHistory;

  const PaymentHistoryList({Key? key, required this.paymentHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (paymentHistory.isEmpty) {
      return const Center(
        child: Text('Aucun paiement enregistré pour cette facture.'),
      );
    }

    return ListView.builder(
      itemCount: paymentHistory.length,
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.payment),
            title: Text('${DateFormat('dd/MM/yyyy').format(payment.date)} - ${payment.amount.toStringAsFixed(2)} F'),
            subtitle: Text('Méthode: ${payment.method}'),
          ),
        );
      },
    );
  }
}
