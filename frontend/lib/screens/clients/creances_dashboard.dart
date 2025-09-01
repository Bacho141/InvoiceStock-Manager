import 'package:flutter/material.dart';
import '../../controllers/creance_controller.dart';
import '../../controllers/client_analytics_controller.dart';
import '../../models/client.dart' as model;
import 'client_detail_screen.dart';

/// Dashboard des créances avec métriques et graphiques
/// Selon le plan Sprint 2 - Frontend Core
class CreancesDashboard extends StatefulWidget {
  const CreancesDashboard({Key? key}) : super(key: key);

  @override
  State<CreancesDashboard> createState() => _CreancesDashboardState();
}

class _CreancesDashboardState extends State<CreancesDashboard> {
  final CreanceController _creanceController = CreanceController();
  final ClientAnalyticsController _analyticsController =
      ClientAnalyticsController();

  bool _isLoading = false;
  String _selectedPeriod = '30';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _creanceController.loadOverdueInvoices(),
      _creanceController.loadCreancesAnalysis(),
      _analyticsController.loadDashboardMetrics(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _refreshData() async {
    await _creanceController.refresh();
    await _analyticsController.loadDashboardMetrics(refresh: true);
    setState(() {});
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    _creanceController.updateDaysFilter(int.parse(period));
    _creanceController.loadOverdueInvoices();
  }

  void _navigateToClientDetail(model.Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(clientId: client.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey[50]!, Colors.white],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildModernHeader(),
                    const SizedBox(height: 20),
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),
                    _buildQuickStats(),
                    const SizedBox(height: 20),
                    _buildAnalysisCards(),
                    const SizedBox(height: 20),
                    _buildTopOverdueClients(),
                    const SizedBox(height: 20),
                    _buildActionableInsights(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7717E8).withOpacity(0.9),
            const Color(0xFF9C27B0).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.dashboard, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Créances',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Vue d\'ensemble des créances et risques',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Actualiser',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF7717E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.date_range,
                  color: Color(0xFF7717E8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Période d\'analyse',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildModernPeriodChip('7', '7 jours'),
              _buildModernPeriodChip('30', '30 jours'),
              _buildModernPeriodChip('60', '60 jours'),
              _buildModernPeriodChip('90', '90 jours'),
              _buildModernPeriodChip('180', '6 mois'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _onPeriodChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7717E8), Color(0xFF9C27B0)],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7717E8).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = _creanceController.quickStats;
    final analytics = _analyticsController.dashboardMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistiques rapides',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Factures en retard',
                '${stats['totalInvoices'] ?? 0}',
                Icons.receipt,
                Colors.orange,
                Colors.orange[50]!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                'Montant total',
                _formatCurrency(stats['totalAmount']?.toDouble() ?? 0),
                Icons.account_balance_wallet,
                Colors.red,
                Colors.red[50]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Montant moyen',
                _formatCurrency(stats['averageAmount']?.toDouble() ?? 0),
                Icons.calculate,
                Colors.blue,
                Colors.blue[50]!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                'Factures critiques',
                '${stats['criticalInvoices'] ?? 0}',
                Icons.warning,
                Colors.red[700]!,
                Colors.red[50]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCards() {
    final analysis = _creanceController.creancesAnalysis;

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Analyse par ancienneté',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (analysis.isNotEmpty) ...[
          _buildAgeAnalysisCard(
            '0-30 jours',
            analysis['current'],
            Colors.green,
            Icons.timelapse,
          ),
          const SizedBox(height: 12),
          _buildAgeAnalysisCard(
            '31-60 jours',
            analysis['30days'],
            Colors.orange,
            Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildAgeAnalysisCard(
            '61-90 jours',
            analysis['60days'],
            Colors.red,
            Icons.warning,
          ),
          const SizedBox(height: 12),
          _buildAgeAnalysisCard(
            'Plus de 90 jours',
            analysis['90days'],
            Colors.red[900]!,
            Icons.error,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Aucune donnée d\'analyse disponible',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAgeAnalysisCard(
    String period,
    dynamic data,
    Color color,
    IconData icon,
  ) {
    if (data == null) return const SizedBox.shrink();

    final count = data['count'] ?? 0;
    final amount = (data['amount'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count clients',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopOverdueClients() {
    // Utilisation des créances regroupées par client
    final clientSummaries = _creanceController.clientOverdueSummaries
        .take(5)
        .toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top 5 Créances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigation vers la liste complète des créances
                // TODO: Implémenter navigation
              },
              child: const Text(
                'Voir tout',
                style: TextStyle(
                  color: Color(0xFF7717E8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (clientSummaries.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: clientSummaries
                  .map((summary) => _buildClientSummaryCard(summary))
                  .toList(),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Aucune créance en cours',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Nouvelle méthode pour afficher une carte de client avec ses créances
  Widget _buildClientSummaryCard(model.ClientOverdueSummary summary) {
    final client = summary.client;
    final riskLevel = summary.riskLevel;
    final riskColor = summary.riskColor;

    // Vérification et affichage du nom du client
    String clientName = client.fullName.trim();
    if (clientName.isEmpty) {
      clientName = '${client.firstName} ${client.lastName}'.trim();
      if (clientName.isEmpty) {
        clientName = 'Client sans nom';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: riskColor.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Icon(Icons.account_circle, color: riskColor, size: 30),
          ),
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
              '${client.phone ?? 'N/A'} • Score: ${client.creditScore.toStringAsFixed(1)}/10',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: riskColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${summary.totalInvoices} factures',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: riskColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Max: ${summary.maxDaysOverdue}j',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
              _formatCurrency(summary.totalOutstanding),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                riskLevel,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _navigateToClientDetail(client),
      ),
    );
  }

  Widget _buildActionableInsights() {
    final insights = _generateInsights();

    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Actions recommandées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (insights.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: insights
                  .map((insight) => _buildInsightCard(insight))
                  .toList(),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.thumb_up, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Situation saine - Aucune action urgente requise',
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (insight['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              insight['icon'] as IconData,
              color: insight['color'] as Color,
              size: 24,
            ),
          ),
        ),
        title: Text(
          insight['title'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Text(
          insight['description'] as String,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: insight['priority'] == 'high'
            ? const Icon(Icons.priority_high, color: Colors.red, size: 20)
            : null,
      ),
    );
  }

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];
    final stats = _creanceController.quickStats;
    final invoices = _creanceController.filteredOverdueInvoices;

    // Clients critiques
    final criticalInvoices = stats['criticalInvoices'] as int? ?? 0;
    if (criticalInvoices > 0) {
      insights.add({
        'title': 'Factures en situation critique',
        'description':
            '$criticalInvoices factures avec un score client < 3 nécessitent une attention immédiate',
        'icon': Icons.warning,
        'color': Colors.red,
        'priority': 'high',
      });
    }

    // Gros montants
    final highValueInvoices = invoices
        .where((invoice) => invoice.outstandingAmount >= 200000)
        .length;
    if (highValueInvoices > 0) {
      insights.add({
        'title': 'Créances importantes',
        'description': '$highValueInvoices factures avec des créances > 200K F',
        'icon': Icons.account_balance,
        'color': Colors.orange,
        'priority': 'medium',
      });
    }

    // Retards importants
    final veryOverdueInvoices = invoices
        .where((invoice) => invoice.daysOverdue > 90)
        .length;
    if (veryOverdueInvoices > 0) {
      insights.add({
        'title': 'Retards prolongés',
        'description':
            '$veryOverdueInvoices factures en retard depuis plus de 90 jours',
        'icon': Icons.schedule,
        'color': Colors.red,
        'priority': 'high',
      });
    }

    // Tendance positive
    if ((stats['totalInvoices'] as int? ?? 0) < 5) {
      insights.add({
        'title': 'Situation sous contrôle',
        'description': 'Peu de factures en retard, continuez le bon travail',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'priority': 'low',
      });
    }

    return insights;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M F';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K F';
    }
    return '${amount.toStringAsFixed(0)} F';
  }
}
