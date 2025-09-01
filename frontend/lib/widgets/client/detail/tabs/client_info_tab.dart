// lib/widgets/client/detail/tabs/client_info_tab.dart
import 'package:flutter/material.dart';
import '../../../../models/client.dart';

class ClientInfoTab extends StatelessWidget {
  final Client client;

  const ClientInfoTab({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection('Contact', [
            _buildInfoRow('Téléphone', client.phone ?? 'N/A'),
            _buildInfoRow('Email', client.email ?? 'N/A'),
            _buildInfoRow('Adresse', client.address ?? 'N/A'),
            _buildInfoRow('Ville', client.city ?? 'N/A'),
            _buildInfoRow('Région', client.region ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Commercial', [
            _buildInfoRow('Entreprise', client.company ?? 'N/A'),
            _buildInfoRow('Type client', client.customerTypeDisplay),
            _buildInfoRow('Catégorie', client.categoryDisplay),
            _buildInfoRow('Priorité', client.priorityDisplay),
            _buildInfoRow('Magasin assigné', client.assignedStore ?? 'N/A'),
            _buildInfoRow('Commercial', client.assignedSalesperson ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _buildInfoSection('Configuration', [
            _buildInfoRow(
              'Limite crédit',
              client.creditLimit > 0
                  ? '${(client.creditLimit / 1000).toStringAsFixed(0)}K F'
                  : 'Aucune limite',
            ),
            _buildInfoRow('Délai paiement', '${client.paymentTerms} jours'),
            _buildInfoRow(
              'Mode paiement préféré',
              client.preferredPaymentMethod ?? 'N/A',
            ),
            _buildInfoRow(
              'Alertes activées',
              client.alertsEnabled ? 'Oui' : 'Non',
            ),
            _buildInfoRow(
              'Alertes crédit',
              client.creditLimitAlerts ? 'Oui' : 'Non',
            ),
            _buildInfoRow(
              'Factures email',
              client.emailInvoices ? 'Oui' : 'Non',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}