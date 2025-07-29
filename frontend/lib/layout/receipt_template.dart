import 'package:flutter/material.dart';

/// Modèle de reçu pour l'impression et l'affichage
///
/// Ce widget gère :
/// - Mise en page du reçu
/// - Informations de l'entreprise
/// - Détails de la transaction
/// - Calculs et totaux
/// - Options d'impression
class ReceiptTemplate extends StatelessWidget {
  final Map<String, dynamic> receiptData;
  final bool isPrintMode;

  const ReceiptTemplate({
    Key? key,
    required this.receiptData,
    this.isPrintMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPrintMode ? 300 : double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isPrintMode ? Border.all(color: Colors.grey[300]!) : null,
        borderRadius: isPrintMode ? null : BorderRadius.circular(8),
        boxShadow: isPrintMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(),
          _buildReceiptInfo(),
          const SizedBox(height: 16),
          _buildItemsList(),
          const Divider(),
          _buildTotals(),
          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo et nom de l'entreprise
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF7717E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store_mall_directory,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'InvoiceStock Manager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7717E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Adresse de l'entreprise
        const Text(
          '123 Rue du Commerce\nNiamey, Niger',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        // Téléphone
        const Text(
          'Tél: +227 90 12 34 56',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildReceiptInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reçu #${receiptData['receiptNumber'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              receiptData['date'] ?? DateTime.now().toString().substring(0, 10),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Client: ${receiptData['customerName'] ?? 'Client'}',
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          'Caissier: ${receiptData['cashierName'] ?? 'Caissier'}',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    final items = receiptData['items'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // En-tête
        const Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'Article',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text(
                'Prix',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Articles
        ...items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['name'] ?? 'Article',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item['quantity'] ?? 0}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item['price'] ?? 0} FCFA',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${(item['quantity'] ?? 0) * (item['price'] ?? 0)} FCFA',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildTotals() {
    final subtotal = receiptData['subtotal'] ?? 0.0;
    final tax = receiptData['tax'] ?? 0.0;
    final total = receiptData['total'] ?? 0.0;
    final paid = receiptData['paid'] ?? 0.0;
    final change = paid - total;

    return Column(
      children: [
        _buildTotalRow('Sous-total', subtotal),
        _buildTotalRow('TVA (19%)', tax),
        const Divider(),
        _buildTotalRow('Total', total, isTotal: true),
        const SizedBox(height: 8),
        _buildTotalRow('Payé', paid),
        _buildTotalRow('Monnaie', change),
      ],
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Merci pour votre achat !',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Conservez ce reçu pour toute réclamation',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        // Code QR ou barre
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Text(
              'QR Code\nou\nCode Barre',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
