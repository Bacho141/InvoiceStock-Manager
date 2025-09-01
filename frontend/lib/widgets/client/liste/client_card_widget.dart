import 'package:flutter/material.dart';
import '../../../models/client.dart';

class ClientCardWidget extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ClientCardWidget({
    Key? key,
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(client.status);
    final scoreColor = _getScoreColor(client.creditScore);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(statusColor),
              const SizedBox(width: 16),
              Expanded(
                child: _buildClientInfo(statusColor, scoreColor),
              ),
              _buildActionMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color statusColor) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [statusColor.withOpacity(0.8), statusColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            client.firstName.isNotEmpty
                ? client.firstName[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        if (client.currentOutstanding > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClientInfo(Color statusColor, Color scoreColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                client.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            _buildStatusChip(client.status, statusColor),
          ],
        ),
        const SizedBox(height: 4),

        // Contact et catégorie
        Text(
          '${client.phone ?? 'N/A'} • ${client.categoryDisplay}',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        if (client.company != null &&
            client.company!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            client.company!,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],

        const SizedBox(height: 8),

        // Métriques
        Row(
          children: [
            _buildMetricChip(
              'CA',
              '${(client.totalRevenue / 1000).toStringAsFixed(0)}K F',
              Colors.blue,
              Icons.trending_up,
            ),
            const SizedBox(width: 8),
            _buildMetricChip(
              'Score',
              '${client.creditScore.toStringAsFixed(1)}/10',
              scoreColor,
              Icons.star,
            ),
            if (client.currentOutstanding > 0) ...[
              const SizedBox(width: 8),
              _buildMetricChip(
                'Créances',
                '${(client.currentOutstanding / 1000).toStringAsFixed(0)}K F',
                Colors.red,
                Icons.warning,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'view':
              onTap();
              break;
            case 'edit':
              onEdit();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility, size: 18),
                SizedBox(width: 8),
                Text('Voir détails'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Modifier'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    String label;
    switch (status) {
      case 'active':
        label = 'Actif';
        break;
      case 'blocked':
        label = 'Bloqué';
        break;
      default:
        label = 'Inactif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.blue;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}