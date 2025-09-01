import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher une métrique
/// Selon le plan Sprint 2 - Frontend Core
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;
  final bool showTrend;
  final double? trendValue;
  final bool? isPositiveTrend;

  const MetricCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.onTap,
    this.trailing,
    this.compact = false,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: compact ? _buildCompactView() : _buildDetailedView(),
        ),
      ),
    );
  }

  Widget _buildCompactView() {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }

  Widget _buildDetailedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 32),
            const Spacer(),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
        if (showTrend && trendValue != null) ...[
          const SizedBox(height: 8),
          _buildTrendIndicator(),
        ],
      ],
    );
  }

  Widget _buildTrendIndicator() {
    if (trendValue == null) return const SizedBox.shrink();

    final isPositive = isPositiveTrend ?? (trendValue! > 0);
    final trendColor = isPositive ? Colors.green : Colors.red;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Row(
      children: [
        Icon(trendIcon, color: trendColor, size: 16),
        const SizedBox(width: 4),
        Text(
          '${trendValue!.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            color: trendColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'vs mois dernier',
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}

/// Widget spécialisé pour les métriques financières
class FinancialMetricCard extends MetricCard {
  FinancialMetricCard({
    Key? key,
    required String title,
    required double amount,
    String? subtitle,
    IconData icon = Icons.account_balance_wallet,
    Color color = Colors.green,
    Color? backgroundColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool compact = false,
    bool showTrend = false,
    double? trendValue,
    bool? isPositiveTrend,
  }) : super(
         key: key,
         title: title,
         value: _formatCurrency(amount),
         subtitle: subtitle,
         icon: icon,
         color: color,
         backgroundColor: backgroundColor,
         onTap: onTap,
         trailing: trailing,
         compact: compact,
         showTrend: showTrend,
         trendValue: trendValue,
         isPositiveTrend: isPositiveTrend,
       );

  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M F';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K F';
    }
    return '${amount.toStringAsFixed(0)} F';
  }
}

/// Widget spécialisé pour les métriques de comptage
class CountMetricCard extends MetricCard {
  CountMetricCard({
    Key? key,
    required String title,
    required int count,
    String? subtitle,
    IconData icon = Icons.people,
    Color color = Colors.blue,
    Color? backgroundColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool compact = false,
    bool showTrend = false,
    double? trendValue,
    bool? isPositiveTrend,
  }) : super(
         key: key,
         title: title,
         value: count.toString(),
         subtitle: subtitle,
         icon: icon,
         color: color,
         backgroundColor: backgroundColor,
         onTap: onTap,
         trailing: trailing,
         compact: compact,
         showTrend: showTrend,
         trendValue: trendValue,
         isPositiveTrend: isPositiveTrend,
       );
}

/// Widget spécialisé pour les métriques de pourcentage
class PercentageMetricCard extends MetricCard {
  PercentageMetricCard({
    Key? key,
    required String title,
    required double percentage,
    String? subtitle,
    IconData icon = Icons.percent,
    Color? color,
    Color? backgroundColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool compact = false,
    bool showTrend = false,
    double? trendValue,
    bool? isPositiveTrend,
  }) : super(
         key: key,
         title: title,
         value: '${percentage.toStringAsFixed(1)}%',
         subtitle: subtitle,
         icon: icon,
         color: color ?? _getPercentageColor(percentage),
         backgroundColor: backgroundColor,
         onTap: onTap,
         trailing: trailing,
         compact: compact,
         showTrend: showTrend,
         trendValue: trendValue,
         isPositiveTrend: isPositiveTrend,
       );

  static Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Widget spécialisé pour les métriques de score
class ScoreMetricCard extends MetricCard {
  ScoreMetricCard({
    Key? key,
    required String title,
    required double score,
    required double maxScore,
    String? subtitle,
    IconData icon = Icons.star,
    Color? color,
    Color? backgroundColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool compact = false,
    bool showTrend = false,
    double? trendValue,
    bool? isPositiveTrend,
  }) : super(
         key: key,
         title: title,
         value: '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(0)}',
         subtitle: subtitle,
         icon: icon,
         color: color ?? _getScoreColor(score, maxScore),
         backgroundColor: backgroundColor,
         onTap: onTap,
         trailing: trailing,
         compact: compact,
         showTrend: showTrend,
         trendValue: trendValue,
         isPositiveTrend: isPositiveTrend,
       );

  static Color _getScoreColor(double score, double maxScore) {
    final percentage = (score / maxScore) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 40) return Colors.orange;
    return Colors.red;
  }
}

/// Widget pour afficher un groupe de métriques
class MetricGroup extends StatelessWidget {
  final String? title;
  final List<Widget> metrics;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const MetricGroup({
    Key? key,
    this.title,
    required this.metrics,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: metrics,
        ),
      ],
    );
  }
}
