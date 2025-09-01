import 'package:flutter/material.dart';

class ClientStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const ClientStatsWidget({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques rapides',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Total Clients',
                  '${stats['totalClients']}',
                  Icons.people,
                  const Color(0xFF7717E8),
                  Colors.purple[50]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModernStatCard(
                  'Clients Actifs',
                  '${stats['activeClients']}',
                  Icons.check_circle,
                  Colors.green,
                  Colors.green[50]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModernStatCard(
                  'Chiffre d\'Affaires',
                  '${(stats['totalRevenue'] / 1000).toStringAsFixed(0)}K F',
                  Icons.trending_up,
                  Colors.blue,
                  Colors.blue[50]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModernStatCard(
                  'Créances',
                  '${(stats['totalOutstanding'] / 1000).toStringAsFixed(0)}K F',
                  Icons.warning,
                  Colors.orange,
                  Colors.orange[50]!,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildModernStatCard(
                  'Score Moyen',
                  '${stats['averageScore'].toStringAsFixed(1)}/10',
                  Icons.star,
                  Colors.amber,
                  Colors.amber[50]!,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: SizedBox(),
              ), // Espace vide pour l'équilibrage
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}