import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../models/client.dart' as model; // Import avec alias
import '../services/client_service.dart';

class ClientAnalyticsController with ChangeNotifier {
  final ClientService _clientService = ClientService();

  // Cache local pour les données
  Map<String, dynamic> _dashboardMetrics = {};
  List<Client> _topClients = [];
  Map<String, dynamic> _clientStats = {};
  String _selectedClientId = '';
  List<Map<String, dynamic>> _clientEvolution = [];
  Map<String, dynamic> _creancesAnalysis = {};
  String _lastError = '';

  // Paramètres
  int _topClientsLimit = 10;
  int _evolutionMonths = 12;

  // Getters
  Map<String, dynamic> get dashboardMetrics =>
      Map.unmodifiable(_dashboardMetrics);
  List<Client> get topClients => List.unmodifiable(_topClients);
  Map<String, dynamic> get clientStats => Map.unmodifiable(_clientStats);
  String get selectedClientId => _selectedClientId;
  List<Map<String, dynamic>> get clientEvolution =>
      List.unmodifiable(_clientEvolution);
  Map<String, dynamic> get creancesAnalysis =>
      Map.unmodifiable(_creancesAnalysis);
  String get lastError => _lastError;
  int get topClientsLimit => _topClientsLimit;
  int get evolutionMonths => _evolutionMonths;

  // ============ Méthodes de chargement du dashboard ============

  /// Charge les métriques du dashboard
  Future<bool> loadDashboardMetrics({bool refresh = false}) async {
    try {
      debugPrint(
        '[ClientAnalyticsController] Chargement métriques dashboard...',
      );

      final metrics = await _clientService.getDashboardMetrics();
      _dashboardMetrics = metrics;

      debugPrint('[ClientAnalyticsController] Métriques dashboard chargées');
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement métriques: $e';
      debugPrint('[ClientAnalyticsController] Erreur: $e');
      return false;
    }
  }

  /// Charge le top des clients par CA
  Future<bool> loadTopClients({bool refresh = false}) async {
    try {
      debugPrint(
        '[ClientAnalyticsController] Chargement top clients ($_topClientsLimit)...',
      );
      _lastError = '';

      final clients = await _clientService.getTopClients(
        limit: _topClientsLimit,
      );
      _topClients = clients;

      debugPrint(
        '[ClientAnalyticsController] ${clients.length} top clients chargés',
      );
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement top clients: $e';
      debugPrint('[ClientAnalyticsController] Erreur: $e');
      return false;
    }
  }

  /// Charge l'analyse des créances
  Future<bool> loadCreancesAnalysis({bool refresh = false}) async {
    try {
      debugPrint('[ClientAnalyticsController] Chargement analyse créances...');
      _lastError = '';

      final analysis = await _clientService.getCreancesAnalysis();
      _creancesAnalysis = analysis;

      debugPrint('[ClientAnalyticsController] Analyse créances chargée');
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement analyse créances: $e';
      debugPrint('[ClientAnalyticsController] Erreur: $e');
      return false;
    }
  }

  // ============ Méthodes pour un client spécifique ============

  /// Charge les statistiques d'un client spécifique
  Future<bool> loadClientStats(String clientId, {bool refresh = false}) async {
    try {
      debugPrint(
        '[ClientAnalyticsController] Chargement stats client: $clientId',
      );
      _lastError = '';
      _selectedClientId = clientId;

      final stats = await _clientService.getClientStats(clientId);
      _clientStats = stats;

      debugPrint('[ClientAnalyticsController] Stats client chargées');
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement stats client: $e';
      debugPrint('[ClientAnalyticsController] Erreur: $e');
      return false;
    }
  }

  /// Charge l'évolution financière d'un client
  Future<bool> loadClientEvolution(
    String clientId, {
    bool refresh = false,
  }) async {
    try {
      debugPrint(
        '[ClientAnalyticsController] Chargement évolution client: $clientId ($_evolutionMonths mois)',
      );
      _lastError = '';

      final evolution = await _clientService.getClientEvolution(
        clientId,
        months: _evolutionMonths,
      );
      _clientEvolution = evolution;

      debugPrint(
        '[ClientAnalyticsController] Évolution client chargée: ${evolution.length} points',
      );
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement évolution client: $e';
      debugPrint('[ClientAnalyticsController] Erreur: $e');
      return false;
    }
  }

  // ============ Méthodes de configuration ============

  /// Met à jour la limite du top clients
  void updateTopClientsLimit(int limit) {
    _topClientsLimit = limit;
    // Le rechargement sera déclenché manuellement par l'UI
  }

  /// Met à jour la période d'évolution
  void updateEvolutionMonths(int months) {
    _evolutionMonths = months;
    // Le rechargement sera déclenché manuellement par l'UI
  }

  // ============ Getters pour les métriques ============

  /// Obtient le total des clients
  int get totalClients =>
      (_dashboardMetrics['totalClients'] as num?)?.toInt() ?? 0;

  /// Obtient le nombre de clients actifs
  int get activeClients =>
      (_dashboardMetrics['activeClients'] as num?)?.toInt() ?? 0;

  /// Obtient le CA total
  double get totalRevenue =>
      (_dashboardMetrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;

  /// Obtient le total des créances
  double get totalOutstanding =>
      (_dashboardMetrics['totalOutstanding'] as num?)?.toDouble() ?? 0.0;

  /// Obtient le score moyen des clients
  double get averageCreditScore =>
      (_dashboardMetrics['averageCreditScore'] as num?)?.toDouble() ?? 0.0;

  /// Obtient le nombre de clients en retard
  int get overdueClients =>
      (_dashboardMetrics['overdueClients'] as num?)?.toInt() ?? 0;

  /// Obtient le taux de clients actifs
  double get activeClientsRate {
    if (totalClients == 0) return 0.0;
    return (activeClients / totalClients * 100);
  }

  /// Obtient le taux de créances
  double get outstandingRate {
    if (totalRevenue == 0) return 0.0;
    return (totalOutstanding / totalRevenue * 100);
  }

  // ============ Méthodes d'analyse des créances ============

  /// Obtient les créances par ancienneté
  Map<String, dynamic> get creancesByAge {
    return _creancesAnalysis['byAge'] as Map<String, dynamic>? ?? {};
  }

  /// Obtient les alertes de créances
  List<dynamic> get creancesAlerts {
    return _creancesAnalysis['alerts'] as List<dynamic>? ?? [];
  }

  /// Obtient le nombre d'alertes critiques
  int get criticalAlertsCount {
    return creancesAlerts.where((alert) => alert['priority'] == 'high').length;
  }

  // ============ Méthodes pour les graphiques ============

  /// Prépare les données pour le graphique de répartition par âge
  List<Map<String, dynamic>> getCreancesAgeChartData() {
    final byAge = creancesByAge;
    return [
      {
        'label': '0-30 jours',
        'value': (byAge['0-30']?['amount'] as num?)?.toDouble() ?? 0.0,
        'count': (byAge['0-30']?['count'] as num?)?.toInt() ?? 0,
        'color': '#4CAF50', // Vert
      },
      {
        'label': '31-60 jours',
        'value': (byAge['31-60']?['amount'] as num?)?.toDouble() ?? 0.0,
        'count': (byAge['31-60']?['count'] as num?)?.toInt() ?? 0,
        'color': '#FF9800', // Orange
      },
      {
        'label': '61-90 jours',
        'value': (byAge['61-90']?['amount'] as num?)?.toDouble() ?? 0.0,
        'count': (byAge['61-90']?['count'] as num?)?.toInt() ?? 0,
        'color': '#F44336', // Rouge
      },
      {
        'label': '+90 jours',
        'value': (byAge['90+']?['amount'] as num?)?.toDouble() ?? 0.0,
        'count': (byAge['90+']?['count'] as num?)?.toInt() ?? 0,
        'color': '#9C27B0', // Violet
      },
    ];
  }

  /// Prépare les données pour le graphique des top clients
  List<Map<String, dynamic>> getTopClientsChartData() {
    return _topClients
        .map(
          (client) => {
            'label': client.fullName,
            'value': client.totalRevenue,
            'outstanding': client.currentOutstanding,
            'score': client.creditScore,
          },
        )
        .toList();
  }

  /// Prépare les données pour le graphique d'évolution
  List<Map<String, dynamic>> getEvolutionChartData() {
    return _clientEvolution
        .map(
          (point) => {
            'date': point['date'],
            'revenue': (point['revenue'] as num?)?.toDouble() ?? 0.0,
            'outstanding': (point['outstanding'] as num?)?.toDouble() ?? 0.0,
            'invoiceCount': (point['invoiceCount'] as num?)?.toInt() ?? 0,
          },
        )
        .toList();
  }

  // ============ Méthodes utilitaires ============

  /// Rafraîchit toutes les données du dashboard
  Future<bool> refreshDashboard() async {
    final loadDashboardResult = await loadDashboardMetrics(refresh: true);
    final loadTopClientsResult = await loadTopClients(refresh: true);
    final loadCreancesResult = await loadCreancesAnalysis(refresh: true);

    return loadDashboardResult && loadTopClientsResult && loadCreancesResult;
  }

  /// Rafraîchit les données d'un client spécifique
  Future<bool> refreshClientData(String clientId) async {
    final loadStatsResult = await loadClientStats(clientId, refresh: true);
    final loadEvolutionResult = await loadClientEvolution(
      clientId,
      refresh: true,
    );

    return loadStatsResult && loadEvolutionResult;
  }

  /// Formate un montant en devise
  String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M F';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K F';
    }
    return '${amount.toStringAsFixed(0)} F';
  }

  /// Formate un pourcentage
  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Obtient la couleur pour un score de crédit
  String getCreditScoreColor(double score) {
    if (score >= 8) return '#4CAF50'; // Vert
    if (score >= 6) return '#FF9800'; // Orange
    if (score >= 4) return '#F44336'; // Rouge
    return '#9C27B0'; // Violet
  }

  /// Obtient la tendance d'évolution
  String getTrend(List<Map<String, dynamic>> data, String field) {
    if (data.length < 2) return 'stable';

    final recent = (data.last[field] as num?)?.toDouble() ?? 0.0;
    final previous = (data[data.length - 2][field] as num?)?.toDouble() ?? 0.0;

    if (recent > previous) return 'up';
    if (recent < previous) return 'down';
    return 'stable';
  }

  /// Calcule le taux de croissance
  double getGrowthRate(List<Map<String, dynamic>> data, String field) {
    if (data.length < 2) return 0.0;

    final recent = (data.last[field] as num?)?.toDouble() ?? 0.0;
    final previous = (data[data.length - 2][field] as num?)?.toDouble() ?? 0.0;

    if (previous == 0) return 0.0;
    return ((recent - previous) / previous * 100);
  }

  /// Réinitialise les données d'un client
  void clearClientData() {
    _selectedClientId = '';
    _clientStats = {};
    _clientEvolution = [];
  }

  /// Obtient un résumé des performances
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'totalClients': totalClients,
      'activeRate': activeClientsRate,
      'totalRevenue': totalRevenue,
      'outstandingRate': outstandingRate,
      'averageScore': averageCreditScore,
      'criticalAlerts': criticalAlertsCount,
    };
  }
}
