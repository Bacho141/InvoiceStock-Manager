// lib/widgets/client/detail/tabs/client_creances_tab.dart
import 'package:flutter/material.dart';
import '../../../../models/client.dart';
import '../../../../models/client.dart' as model;
import '../../../../controllers/creance_controller.dart';
import '../../../creance_card.dart';

class ClientCreancesTab extends StatelessWidget {
  final Client client;
  final CreanceController creanceController;

  const ClientCreancesTab({
    Key? key,
    required this.client,
    required this.creanceController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<model.OverdueInvoice>>(
      future: creanceController.loadClientOverdueInvoices(client.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final overdueInvoices = snapshot.data ?? [];

        if (overdueInvoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Aucune créance pour ce client.',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        final totalOutstanding = overdueInvoices.fold<double>(
          0,
          (sum, invoice) => sum + invoice.outstandingAmount,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Section
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Dû',
                      creanceController.formatCurrency(totalOutstanding),
                      Icons.account_balance_wallet,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Factures en Retard',
                      overdueInvoices.length.toString(),
                      Icons.receipt,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Détail des Créances',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // List of CreanceCard
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: overdueInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = overdueInvoices[index];
                  return CreanceCard(
                    invoice: invoice,
                    controller: creanceController,
                    showActions: false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
