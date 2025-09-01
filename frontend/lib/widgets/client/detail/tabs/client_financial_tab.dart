import 'package:flutter/material.dart';
import '../../../../models/client.dart';
import '../../../common/metric_card.dart';

class ClientFinancialTab extends StatelessWidget {
  final Client client;

  const ClientFinancialTab({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          MetricCard(
            title: 'Chiffre d\'affaires total',
            value: '${(client.totalRevenue / 1000).toStringAsFixed(0)}K F',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'Créances actuelles',
            value: '${(client.currentOutstanding / 1000).toStringAsFixed(0)}K F',
            icon: Icons.account_balance_wallet,
            color: client.currentOutstanding > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'Score de crédit',
            value: '${client.creditScore.toStringAsFixed(1)}/10 (${client.creditScoreLevel})',
            icon: Icons.star,
            color: client.creditScore >= 6 ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 16),
          MetricCard(
            title: 'Délai de paiement moyen',
            value: '${client.averagePaymentDelay} jours',
            icon: Icons.schedule,
            color: client.averagePaymentDelay <= client.paymentTerms
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  title: 'Nombre de factures',
                  value: '${client.invoiceCount}',
                  icon: Icons.receipt,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MetricCard(
                  title: 'Facture moyenne',
                  value: client.invoiceCount > 0
                      ? '${((client.totalRevenue / client.invoiceCount) / 1000).toStringAsFixed(0)}K F'
                      : '0 F',
                  icon: Icons.calculate,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          if (client.lastInvoiceDate != null) ...[
            const SizedBox(height: 16),
            MetricCard(
              title: 'Dernière facture',
              value: '${DateTime.now().difference(client.lastInvoiceDate!).inDays} jours',
              icon: Icons.access_time,
              color: Colors.grey,
            ),
          ],
        ],
      ),
    );
  }
}