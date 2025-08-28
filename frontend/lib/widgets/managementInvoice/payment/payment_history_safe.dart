import 'package:flutter/material.dart';
import '../../../models/invoice.dart';

class PaymentHistoryWidget extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onPaymentUpdated;

  const PaymentHistoryWidget({
    Key? key,
    required this.invoice,
    required this.onPaymentUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique des Paiements', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildPaymentSummaryRow(
              theme,
              'Total facture:',
              '${invoice.total.toStringAsFixed(2)} F',
            ),
            _buildPaymentSummaryRow(
              theme,
              'Montant payé:',
              '${invoice.montantPaye.toStringAsFixed(2)} F',
            ),
            _buildPaymentSummaryRow(
              theme,
              'Reste à payer:',
              '${(invoice.total - invoice.montantPaye).toStringAsFixed(2)} F',
              isRemainder: true,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (invoice.paymentHistory.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Détails des paiements (${invoice.paymentHistory.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: invoice.paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = invoice.paymentHistory[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getPaymentIcon(payment.method),
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                payment.method,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${payment.amount.toStringAsFixed(2)} F',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${payment.date.day}/${payment.date.month}/${payment.date.year}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Divider(height: 32),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun paiement enregistré',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isRemainder = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isRemainder ? FontWeight.bold : FontWeight.normal,
              color: isRemainder
                  ? (invoice.total - invoice.montantPaye > 0
                        ? theme.colorScheme.primary
                        : Colors.green[600])
                  : null,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (invoice.montantPaye >= invoice.total) {
      return Colors.green[600]!;
    } else if (invoice.montantPaye > 0) {
      return Colors.orange[600]!;
    } else {
      return Colors.red[600]!;
    }
  }

  String _getStatusText() {
    if (invoice.montantPaye >= invoice.total) {
      return 'PAYÉ';
    } else if (invoice.montantPaye > 0) {
      return 'PARTIELLEMENT PAYÉ';
    } else {
      return 'NON PAYÉ';
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'especes':
      case 'espèces':
        return Icons.attach_money;
      case 'carte':
      case 'cb':
        return Icons.credit_card;
      case 'cheque':
      case 'chèque':
        return Icons.receipt;
      case 'virement':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}
