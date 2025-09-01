// lib/widgets/client/detail/client_detail_header.dart
import 'package:flutter/material.dart';
import '../../../models/client.dart';

class ClientDetailHeader extends StatelessWidget {
  final Client client;

  const ClientDetailHeader({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: client.status == 'active'
                ? Colors.green
                : client.status == 'blocked'
                ? Colors.red
                : Colors.grey,
            child: Text(
              client.firstName.isNotEmpty
                  ? client.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${client.phone ?? 'N/A'} • ${client.categoryDisplay}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatusChip(),
                    const SizedBox(width: 8),
                    _buildScoreChip(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    String label;
    switch (client.status) {
      case 'active':
        color = Colors.green;
        label = 'Actif';
        break;
      case 'blocked':
        color = Colors.red;
        label = 'Bloqué';
        break;
      default:
        color = Colors.grey;
        label = 'Inactif';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget _buildScoreChip() {
    final score = client.creditScore;
    Color color;
    if (score >= 8) {
      color = Colors.green;
    } else if (score >= 6) {
      color = Colors.blue;
    } else if (score >= 4) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Chip(
      label: Text(
        'Score: ${score.toStringAsFixed(1)}/10',
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}