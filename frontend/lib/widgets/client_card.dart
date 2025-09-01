import 'package:flutter/material.dart';
import '../models/client.dart';

/// Widget réutilisable pour afficher une carte client
/// Selon le plan Sprint 2 - Frontend Core
class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool compact;

  const ClientCard({
    Key? key,
    required this.client,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: compact ? _buildCompactView() : _buildDetailedView(),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                client.phone ?? 'N/A',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
        _buildStatusIndicator(),
        if (showActions) _buildActionsButton(),
      ],
    );
  }

  Widget _buildDetailedView() {
    return Column(
      children: [
        Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                          ),
                        ),
                      ),
                      _buildStatusIndicator(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${client.phone ?? 'N/A'} • ${client.categoryDisplay}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (client.company != null && client.company!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      client.company!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showActions) _buildActionsButton(),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetrics(),
        if (client.currentOutstanding > 0 || client.isOverCreditLimit) ...[
          const SizedBox(height: 8),
          _buildWarnings(),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    Color avatarColor;
    switch (client.status) {
      case 'active':
        avatarColor = Colors.green;
        break;
      case 'blocked':
        avatarColor = Colors.red;
        break;
      default:
        avatarColor = Colors.grey;
    }

    return CircleAvatar(
      radius: compact ? 20 : 24,
      backgroundColor: avatarColor,
      child: Text(
        client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 14 : 16,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    String statusText;

    switch (client.status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'Actif';
        break;
      case 'blocked':
        statusColor = Colors.red;
        statusText = 'Bloqué';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inactif';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            'CA Total',
            _formatCurrency(client.totalRevenue),
            Icons.trending_up,
            Colors.green,
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            'Score',
            '${client.creditScore.toStringAsFixed(1)}/10',
            Icons.star,
            _getScoreColor(client.creditScore),
          ),
        ),
        if (client.currentOutstanding > 0)
          Expanded(
            child: _buildMetricItem(
              'Créances',
              _formatCurrency(client.currentOutstanding),
              Icons.warning,
              Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWarnings() {
    final warnings = <Widget>[];

    if (client.currentOutstanding > 0) {
      warnings.add(
        _buildWarningChip(
          'Créances: ${_formatCurrency(client.currentOutstanding)}',
          Colors.red,
          Icons.account_balance_wallet,
        ),
      );
    }

    if (client.isOverCreditLimit) {
      warnings.add(
        _buildWarningChip(
          'Limite crédit dépassée',
          Colors.orange,
          Icons.warning,
        ),
      );
    }

    if (client.isLowCreditScore) {
      warnings.add(
        _buildWarningChip(
          'Score faible: ${client.creditScore.toStringAsFixed(1)}',
          Colors.red,
          Icons.star_outline,
        ),
      );
    }

    if (warnings.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 4, runSpacing: 4, children: warnings);
  }

  Widget _buildWarningChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onTap?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Voir détails'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Modifier'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M F';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K F';
    }
    return '${amount.toStringAsFixed(0)} F';
  }

  Color _getScoreColor(double score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.blue;
    if (score >= 4) return Colors.orange;
    return Colors.red;
  }
}
