import 'package:flutter/material.dart';
import '../models/client.dart' as model;
import '../controllers/creance_controller.dart';

/// Un widget réutilisable qui affiche les détails d'une facture en retard sous forme de carte.
class CreanceCard extends StatelessWidget {
  final model.OverdueInvoice invoice;
  final CreanceController controller;
  final VoidCallback? onNavigateToDetail;
  final VoidCallback? onAddCommunication;
  final VoidCallback? onUpdateScore;
  final bool showActions;

  const CreanceCard({
    Key? key,
    required this.invoice,
    required this.controller,
    this.onNavigateToDetail,
    this.onAddCommunication,
    this.onUpdateScore,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riskLevel = controller.getClientRiskLevel(invoice);
    final actions = controller.getRecommendedActions(invoice);

    Color riskColor;
    switch (riskLevel) {
      case 'Critique':
        riskColor = Colors.red;
        break;
      case 'Élevé':
        riskColor = Colors.orange;
        break;
      case 'Modéré':
        riskColor = Colors.yellow[700]!;
        break;
      default:
        riskColor = Colors.green;
    }

    String invoiceDate = 'N/A';
    if (invoice.invoiceDate != null) {
      invoiceDate =
          '${invoice.invoiceDate.day.toString().padLeft(2, '0')}/${invoice.invoiceDate.month.toString().padLeft(2, '0')}/${invoice.invoiceDate.year}';
    }

    String clientName = invoice.client.fullName.trim();
    if (clientName.isEmpty) {
      clientName = '${invoice.client.firstName} ${invoice.client.lastName}'.trim();
      if (clientName.isEmpty) {
        clientName = 'Client sans nom';
      }
    }

    double outstandingAmount = invoice.outstandingAmount;
    if (outstandingAmount < 0) {
      outstandingAmount = 0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Icon(Icons.receipt, color: riskColor, size: 24)),
        ),
        title: Text(
          clientName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${invoice.client.phone ?? 'N/A'} • ${invoice.client.categoryDisplay}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(invoice.invoiceNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: Text(invoiceDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${invoice.daysOverdue} jours', style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: riskColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(riskLevel, style: TextStyle(color: riskColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              controller.formatCurrency(outstandingAmount),
              style: TextStyle(fontWeight: FontWeight.bold, color: riskColor, fontSize: 16),
            ),
            Text('Créance', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(child: _buildModernInfoCard('Limite crédit', invoice.client.creditLimit > 0 ? controller.formatCurrency(invoice.client.creditLimit) : 'Aucune', Icons.credit_card)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModernInfoCard('Délai paiement', '${invoice.client.paymentTerms} jours', Icons.schedule)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildModernInfoCard('Montant facture', controller.formatCurrency(invoice.totalAmount), Icons.receipt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text('Score: ${invoice.client.creditScore.toStringAsFixed(1)}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const Spacer(),
                      Text(_getScoreDescription(invoice.client.creditScore), style: TextStyle(fontSize: 12, color: _getScoreColor(invoice.client.creditScore))),
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Actions recommandées:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3748))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: riskColor.withOpacity(0.2), width: 1),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: actions.map((action) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.circle, color: riskColor, size: 8),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(action, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                                ],
                              ),
                            ),
                          ).toList(),
                    ),
                  ),
                ],

                // Boutons d'action
                if (showActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onNavigateToDetail,
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Détails'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7717E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAddCommunication,
                          icon: const Icon(Icons.message, size: 18),
                          label: const Text('Contacter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onUpdateScore,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Score'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF7717E8)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 8) return 'Excellent';
    if (score >= 6) return 'Bon';
    if (score >= 4) return 'Moyen';
    if (score >= 2) return 'Faible';
    return 'Très faible';
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.orange;
    if (score >= 2) return Colors.deepOrange;
    return Colors.red;
  }

  
}