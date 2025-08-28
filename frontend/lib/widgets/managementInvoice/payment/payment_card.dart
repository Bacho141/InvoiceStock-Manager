import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/payment.dart';

class PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final bool showActions;

  const PaymentCard({
    Key? key,
    required this.payment,
    this.onCancel,
    this.onEdit,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPaymentDetails(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icône de méthode de paiement
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          payment.method.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                payment.formattedAmount,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  payment.status.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.method.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    if (showActions &&
                        payment.status != PaymentStatus.cancelled)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Détails'),
                              ],
                            ),
                          ),
                          if (payment.status == PaymentStatus.confirmed)
                            const PopupMenuItem(
                              value: 'receipt',
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Reçu'),
                                ],
                              ),
                            ),
                          if (onCancel != null &&
                              payment.status != PaymentStatus.cancelled)
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Annuler',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        onSelected: (value) => _handleAction(context, value),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations secondaires
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      payment.formattedDate,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (payment.reference != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.tag, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Réf: ${payment.reference}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),

                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      payment.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (payment.status) {
      case PaymentStatus.confirmed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'details':
        _showPaymentDetails(context);
        break;
      case 'receipt':
        _generateReceipt(context);
        break;
      case 'cancel':
        onCancel?.call();
        break;
    }
  }

  void _showPaymentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentDetailsSheet(payment: payment),
    );
  }

  void _generateReceipt(BuildContext context) {
    // TODO: Implémenter la génération de reçu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération de reçu - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class PaymentDetailsSheet extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsSheet({Key? key, required this.payment})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7717E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      payment.method.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Détails du Paiement',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Text(
                        payment.formattedAmount,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF7717E8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildDetailRow('Méthode', payment.method.label),
                _buildDetailRow('Statut', payment.status.label),
                _buildDetailRow('Date', payment.formattedDate),
                if (payment.reference != null)
                  _buildDetailRow('Référence', payment.reference!),
                if (payment.receiptNumber != null)
                  _buildDetailRow('N° Reçu', payment.receiptNumber!),
                if (payment.processedBy != null)
                  _buildDetailRow('Traité par', payment.processedBy!.username),
                if (payment.notes != null && payment.notes!.isNotEmpty)
                  _buildDetailRow('Notes', payment.notes!, isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: payment.id));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('ID copié')));
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copier ID'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.receipt_outlined, size: 18),
                    label: const Text('Générer Reçu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7717E8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
