// widgets/invoice_common/invoice_status_badge.dart
import 'package:flutter/material.dart';

class InvoiceStatusBadge extends StatelessWidget {
  final String status;
  final bool isChip;

  const InvoiceStatusBadge({
    Key? key,
    required this.status,
    this.isChip = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    if (isChip) {
      return Chip(
        avatar: Icon(
          statusConfig.icon,
          color: Colors.white,
          size: 16,
        ),
        label: Text(
          statusConfig.text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: statusConfig.color,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        labelPadding: const EdgeInsets.only(left: 4),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusConfig.text,
        style: TextStyle(
          color: statusConfig.color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'payee':
        return _StatusConfig(
          color: Colors.green.shade700,
          text: 'Payée',
          icon: Icons.check_circle,
        );
      case 'reste_a_payer':
        return _StatusConfig(
          color: Colors.orange.shade800,
          text: 'Reste à payer',
          icon: Icons.hourglass_bottom,
        );
      case 'annulee':
        return _StatusConfig(
          color: Colors.red.shade700,
          text: 'Annulée',
          icon: Icons.cancel,
        );
      case 'en_attente':
        return _StatusConfig(
          color: Colors.blue.shade700,
          text: 'En attente',
          icon: Icons.pause_circle,
        );
      default:
        return _StatusConfig(
          color: Colors.grey.shade600,
          text: status,
          icon: Icons.info,
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final String text;
  final IconData icon;

  _StatusConfig({
    required this.color,
    required this.text,
    required this.icon,
  });
}