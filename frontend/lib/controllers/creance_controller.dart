import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/client.dart';
import '../models/client.dart' as model; // Import avec alias
import '../services/client_service.dart';

/// Contrôleur pour la gestion des créances
/// Selon le plan Sprint 2 - Frontend Core
class CreanceController {
  final ClientService _clientService = ClientService();

  // Cache local pour les données
  List<model.Client> _overdueClients = [];
  List<model.Client> _filteredOverdueClients =
      []; // Ajout de la déclaration manquante
  List<model.OverdueInvoice> _overdueInvoices =
      []; // Nouvelle liste pour les factures
  List<model.OverdueInvoice> _filteredOverdueInvoices = []; // Liste filtrée
  List<model.ClientOverdueSummary> _clientOverdueSummaries =
      []; // Liste regroupée par client
  Map<String, dynamic> _creancesAnalysis = {};
  Map<String, dynamic> _quickStats = {};
  String _lastError = '';

  // Paramètres de filtrage
  int _daysFilter = 30; // Nombre de jours de retard minimum
  String _amountFilter = 'all'; // all, low, medium, high
  String _priorityFilter = 'all';
  String _sortBy = 'amount'; // amount, days, score
  String _sortOrder = 'desc';

  // Getters
  List<model.Client> get overdueClients => List.unmodifiable(_overdueClients);
  List<model.Client> get filteredOverdueClients =>
      List.unmodifiable(_filteredOverdueClients); // Mise à jour du getter
  List<model.OverdueInvoice> get overdueInvoices =>
      List.unmodifiable(_overdueInvoices);
  List<model.OverdueInvoice> get filteredOverdueInvoices =>
      List.unmodifiable(_filteredOverdueInvoices);
  List<model.ClientOverdueSummary> get clientOverdueSummaries =>
      List.unmodifiable(_clientOverdueSummaries);
  Map<String, dynamic> get creancesAnalysis =>
      Map.unmodifiable(_creancesAnalysis);
  Map<String, dynamic> get quickStats => Map.unmodifiable(_quickStats);
  String get lastError => _lastError;
  int get daysFilter => _daysFilter;
  String get amountFilter => _amountFilter;
  String get priorityFilter => _priorityFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // ============ Méthodes de chargement ============

  /// Charge les clients en retard de paiement
  Future<bool> loadOverdueClients({bool refresh = false}) async {
    try {
      debugPrint(
        '[CreanceController] Chargement clients en retard (${_daysFilter}j)...',
      );
      _lastError = '';

      final clients = await _clientService.getOverdueClients(days: _daysFilter);

      _overdueClients = clients;
      _applyFilters();
      _updateQuickStats();

      debugPrint(
        '[CreanceController] ${clients.length} clients en retard chargés',
      );
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement clients en retard: $e';
      debugPrint('[CreanceController] Erreur: $e');
      return false;
    }
  }

  /// Charge les factures en retard de paiement
  Future<bool> loadOverdueInvoices({bool refresh = false}) async {
    try {
      debugPrint(
        '[CreanceController] Chargement factures en retard (${_daysFilter}j)...',
      );
      _lastError = '';

      final invoices = await _clientService.getOverdueInvoices(
        days: _daysFilter,
      );

      _overdueInvoices = invoices;
      _filteredOverdueInvoices = invoices;
      _updateInvoiceQuickStats();
      _groupByClient(); // Regroupement par client

      debugPrint(
        '[CreanceController] ${invoices.length} factures en retard chargées',
      );
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement factures en retard: $e';
      debugPrint('[CreanceController] Erreur: $e');
      return false;
    }
  }

  /// Regroupe les factures par client
  void _groupByClient() {
    final Map<String, List<model.OverdueInvoice>> groupedInvoices = {};

    // Regrouper les factures par ID client
    for (final invoice in _filteredOverdueInvoices) {
      final clientId = invoice.client.id;
      if (!groupedInvoices.containsKey(clientId)) {
        groupedInvoices[clientId] = [];
      }
      groupedInvoices[clientId]!.add(invoice);
    }

    // Créer les résumés par client
    _clientOverdueSummaries = groupedInvoices.entries.map((entry) {
      final invoices = entry.value;
      final client = invoices.first.client;
      final totalOutstanding = invoices.fold<double>(
        0,
        (sum, invoice) => sum + invoice.outstandingAmount,
      );

      return model.ClientOverdueSummary(
        client: client,
        overdueInvoices: invoices,
        totalOutstanding: totalOutstanding,
        totalInvoices: invoices.length,
      );
    }).toList();

    // Trier par montant de créance décroissant
    _clientOverdueSummaries.sort(
      (a, b) => b.totalOutstanding.compareTo(a.totalOutstanding),
    );

    debugPrint(
      '[CreanceController] ${_clientOverdueSummaries.length} clients avec créances regroupés',
    );
  }

  /// Charge l'analyse des créances par ancienneté
  Future<bool> loadCreancesAnalysis({bool refresh = false}) async {
    try {
      debugPrint('[CreanceController] Chargement analyse créances...');
      _lastError = '';

      final analysis = await _clientService.getCreancesAnalysis();
      _creancesAnalysis = analysis;

      debugPrint('[CreanceController] Analyse créances chargée');
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement analyse: $e';
      debugPrint('[CreanceController] Erreur: $e');
      return false;
    }
  }

  /// Charge les factures en retard pour un client spécifique
  Future<List<model.OverdueInvoice>> loadClientOverdueInvoices(
    String clientId,
  ) async {
    try {
      // Charger les factures en retard du client depuis le service
      // On utilise un filtre de 1 jour pour récupérer toutes les créances pertinentes
      // sans dépendre du filtre global de l'écran de liste.
      final clientInvoices = await _clientService.getClientOverdueInvoices(
        clientId,
        days: 1,
      );
      return clientInvoices;
    } catch (e) {
      debugPrint('[CreanceController] Erreur chargement factures client: $e');
      return [];
    }
  }

  // ============ Actions sur les créances ============

  /// Ajoute une communication à un client
  Future<Map<String, dynamic>> addCommunication(
    String clientId, {
    required String type,
    required String subject,
    required String content,
  }) async {
    try {
      debugPrint('[CreanceController] Ajout communication client: $clientId');
      _lastError = '';

      final communication = {
        'type': type,
        'subject': subject,
        'content': content,
      };

      await _clientService.addCommunication(clientId, communication);

      debugPrint('[CreanceController] Communication ajoutée: $clientId');
      return {'success': true, 'message': 'Communication ajoutée avec succès'};
    } catch (e) {
      _lastError = 'Erreur ajout communication: $e';
      debugPrint('[CreanceController] Erreur: $e');
      return {'success': false, 'message': _lastError};
    }
  }

  /// Met à jour le score de crédit d'un client
  Future<Map<String, dynamic>> updateClientScore(String clientId) async {
    try {
      debugPrint('[CreanceController] Mise à jour score client: $clientId');
      _lastError = '';

      final response = await _clientService.updateClientScore(clientId);
      final newScore = response['creditScore'];

      // Mettre à jour le client dans la liste
      final index = _overdueClients.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        _overdueClients[index] = _overdueClients[index].copyWith(
          creditScore: newScore.toDouble(),
        );
        _applyFilters();
      }

      debugPrint(
        '[CreanceController] Score mis à jour: $clientId -> $newScore',
      );
      return {
        'success': true,
        'message': 'Score mis à jour: $newScore/10',
        'newScore': newScore,
      };
    } catch (e) {
      _lastError = 'Erreur mise à jour score: $e';
      debugPrint('[CreanceController] Erreur: $e');
      return {'success': false, 'message': _lastError};
    }
  }

  // ============ Méthodes de filtrage ============

  /// Applique les filtres aux clients en retard
  void _applyFilters() {
    var filtered = _overdueClients.toList();

    // Filtre par montant
    if (_amountFilter != 'all') {
      filtered = filtered.where((client) {
        switch (_amountFilter) {
          case 'low':
            return client.currentOutstanding < 50000;
          case 'medium':
            return client.currentOutstanding >= 50000 &&
                client.currentOutstanding < 200000;
          case 'high':
            return client.currentOutstanding >= 200000;
          default:
            return true;
        }
      }).toList();
    }

    // Filtre par priorité
    if (_priorityFilter != 'all') {
      filtered = filtered
          .where((client) => client.priority == _priorityFilter)
          .toList();
    }

    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'amount':
          comparison = a.currentOutstanding.compareTo(b.currentOutstanding);
          break;
        case 'score':
          comparison = a.creditScore.compareTo(b.creditScore);
          break;
        case 'days':
          // Calcul approximatif des jours de retard basé sur lastInvoiceDate
          final aDays = a.lastInvoiceDate != null
              ? DateTime.now().difference(a.lastInvoiceDate!).inDays
              : 0;
          final bDays = b.lastInvoiceDate != null
              ? DateTime.now().difference(b.lastInvoiceDate!).inDays
              : 0;
          comparison = aDays.compareTo(bDays);
          break;
        default:
          comparison = a.fullName.compareTo(b.fullName);
          break;
      }
      return _sortOrder == 'desc' ? -comparison : comparison;
    });

    _filteredOverdueClients = filtered;
    debugPrint(
      '[CreanceController] Filtres appliqués: ${filtered.length} clients',
    );
  }

  /// Applique les filtres aux factures en retard
  void _applyInvoiceFilters() {
    var filtered = _overdueInvoices.toList();

    // Filtre par montant
    if (_amountFilter != 'all') {
      filtered = filtered.where((invoice) {
        switch (_amountFilter) {
          case 'low':
            return invoice.outstandingAmount < 50000;
          case 'medium':
            return invoice.outstandingAmount >= 50000 &&
                invoice.outstandingAmount < 200000;
          case 'high':
            return invoice.outstandingAmount >= 200000;
          default:
            return true;
        }
      }).toList();
    }

    // Filtre par priorité - basé sur le score du client
    if (_priorityFilter != 'all') {
      filtered = filtered
          .where((invoice) => invoice.client.priority == _priorityFilter)
          .toList();
    }

    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'amount':
          comparison = a.outstandingAmount.compareTo(b.outstandingAmount);
          break;
        case 'score':
          comparison = a.client.creditScore.compareTo(b.client.creditScore);
          break;
        case 'days':
          comparison = a.daysOverdue.compareTo(b.daysOverdue);
          break;
        default:
          comparison = a.invoiceNumber.compareTo(b.invoiceNumber);
          break;
      }
      return _sortOrder == 'desc' ? -comparison : comparison;
    });

    _filteredOverdueInvoices = filtered;
    debugPrint(
      '[CreanceController] Filtres appliqués: ${filtered.length} factures',
    );
  }

  /// Met à jour les statistiques rapides
  void _updateQuickStats() {
    if (_overdueClients.isEmpty) {
      _quickStats = {
        'totalClients': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'criticalClients': 0,
      };
      return;
    }

    final totalAmount = _overdueClients.fold<double>(
      0,
      (sum, c) => sum + c.currentOutstanding,
    );
    final averageAmount = totalAmount / _overdueClients.length;
    final criticalClients = _overdueClients
        .where((c) => c.creditScore < 3)
        .length;

    _quickStats = {
      'totalClients': _overdueClients.length,
      'totalAmount': totalAmount,
      'averageAmount': averageAmount,
      'criticalClients': criticalClients,
    };
  }

  /// Met à jour les statistiques rapides pour les factures
  void _updateInvoiceQuickStats() {
    if (_overdueInvoices.isEmpty) {
      _quickStats = {
        'totalInvoices': 0,
        'totalAmount': 0.0,
        'averageAmount': 0.0,
        'criticalInvoices': 0,
      };
      return;
    }

    final totalAmount = _overdueInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.outstandingAmount,
    );
    final averageAmount = totalAmount / _overdueInvoices.length;
    final criticalInvoices = _overdueInvoices
        .where((invoice) => invoice.client.creditScore < 3)
        .length;

    _quickStats = {
      'totalInvoices': _overdueInvoices.length,
      'totalAmount': totalAmount,
      'averageAmount': averageAmount,
      'criticalInvoices': criticalInvoices,
    };
  }

  // ============ Méthodes de filtrage public ============

  /// Met à jour le filtre de jours
  void updateDaysFilter(int days) {
    _daysFilter = days;
    // Le rechargement sera déclenché manuellement par l'UI
  }

  /// Met à jour le filtre de montant
  void updateAmountFilter(String amount) {
    _amountFilter = amount;
    _applyInvoiceFilters();
  }

  /// Met à jour le filtre de priorité
  void updatePriorityFilter(String priority) {
    _priorityFilter = priority;
    _applyInvoiceFilters();
  }

  /// Met à jour les paramètres de tri
  void updateSort(String field, String order) {
    _sortBy = field;
    _sortOrder = order;
    _applyInvoiceFilters();
  }

  // ============ Méthodes utilitaires ============

  /// Réinitialise tous les filtres
  void clearFilters() {
    _daysFilter = 30;
    _amountFilter = 'all';
    _priorityFilter = 'all';
    _sortBy = 'amount';
    _sortOrder = 'desc';
    _applyInvoiceFilters();
  }

  /// Rafraîchit toutes les données
  Future<bool> refresh() async {
    final loadInvoicesResult = await loadOverdueInvoices(refresh: true);
    final loadAnalysisResult = await loadCreancesAnalysis(refresh: true);
    return loadInvoicesResult && loadAnalysisResult;
  }

  /// Obtient la couleur prioritaire pour une facture
  String getClientPriorityColor(model.OverdueInvoice invoice) {
    if (invoice.outstandingAmount >= 200000 || invoice.client.creditScore < 3) {
      return 'red'; // Critique
    } else if (invoice.outstandingAmount >= 50000 ||
        invoice.client.creditScore < 5) {
      return 'orange'; // Attention
    }
    return 'green'; // Normal
  }

  /// Obtient le niveau de risque d'une facture
  String getClientRiskLevelForInvoice(model.OverdueInvoice invoice) {
    if (invoice.outstandingAmount >= 200000 || invoice.client.creditScore < 3) {
      return 'Critique';
    } else if (invoice.outstandingAmount >= 50000 ||
        invoice.client.creditScore < 5) {
      return 'Élevé';
    } else if (invoice.outstandingAmount > 0) {
      return 'Modéré';
    }
    return 'Faible';
  }

  /// Obtient le niveau de risque d'un client (méthode pour compatibilité)
  String getClientRiskLevelForClient(model.Client client) {
    if (client.currentOutstanding >= 200000 || client.creditScore < 3) {
      return 'Critique';
    } else if (client.currentOutstanding >= 50000 || client.creditScore < 5) {
      return 'Élevé';
    } else if (client.currentOutstanding > 0) {
      return 'Modéré';
    }
    return 'Faible';
  }

  /// Obtient le niveau de risque (méthode surchargée pour compatibilité)
  String getClientRiskLevel(dynamic item) {
    if (item is model.OverdueInvoice) {
      return getClientRiskLevelForInvoice(item);
    } else if (item is model.Client) {
      return getClientRiskLevelForClient(item);
    }
    return 'Faible';
  }

  /// Obtient les actions recommandées pour une facture
  List<String> getRecommendedActionsForInvoice(model.OverdueInvoice invoice) {
    final actions = <String>[];

    if (invoice.outstandingAmount > invoice.client.creditLimit &&
        invoice.client.creditLimit > 0) {
      actions.add('Limite de crédit dépassée');
    }

    if (invoice.client.creditScore < 3) {
      actions.add('Score critique - Blocage recommandé');
    } else if (invoice.client.creditScore < 5) {
      actions.add('Surveillance renforcée');
    }

    if (invoice.daysOverdue > 90) {
      actions.add('Relance urgente (>90j)');
    } else if (invoice.daysOverdue > 60) {
      actions.add('Relance formelle (>60j)');
    } else if (invoice.daysOverdue > 30) {
      actions.add('Relance téléphonique');
    }

    if (invoice.outstandingAmount >= 200000) {
      actions.add('Montant élevé - Négociation');
    }

    return actions;
  }

  /// Obtient les actions recommandées pour un client (méthode pour compatibilité)
  List<String> getRecommendedActionsForClient(model.Client client) {
    final actions = <String>[];

    if (client.currentOutstanding > client.creditLimit &&
        client.creditLimit > 0) {
      actions.add('Limite de crédit dépassée');
    }

    if (client.creditScore < 3) {
      actions.add('Score critique - Blocage recommandé');
    } else if (client.creditScore < 5) {
      actions.add('Surveillance renforcée');
    }

    final overdueDays = getApproximateOverdueDaysForClient(client);
    if (overdueDays > 90) {
      actions.add('Relance urgente (>90j)');
    } else if (overdueDays > 60) {
      actions.add('Relance formelle (>60j)');
    } else if (overdueDays > 30) {
      actions.add('Relance téléphonique');
    }

    if (client.currentOutstanding >= 200000) {
      actions.add('Montant élevé - Négociation');
    }

    return actions;
  }

  /// Calcule les jours de retard approximatifs pour un client
  int getApproximateOverdueDaysForClient(model.Client client) {
    if (client.lastInvoiceDate == null) return 0;
    final daysSinceLastInvoice = DateTime.now()
        .difference(client.lastInvoiceDate!)
        .inDays;
    return daysSinceLastInvoice > client.paymentTerms
        ? daysSinceLastInvoice - client.paymentTerms
        : 0;
  }

  /// Calcule les jours de retard approximatifs (méthode surchargée pour compatibilité)
  int getApproximateOverdueDays(dynamic item) {
    if (item is model.OverdueInvoice) {
      return getApproximateOverdueDaysForInvoice(item);
    } else if (item is model.Client) {
      return getApproximateOverdueDaysForClient(item);
    }
    return 0;
  }

  /// Calcule les jours de retard approximatifs pour une facture
  int getApproximateOverdueDaysForInvoice(model.OverdueInvoice invoice) {
    return invoice.daysOverdue;
  }

  /// Obtient les actions recommandées (méthode surchargée pour compatibilité)
  List<String> getRecommendedActions(dynamic item) {
    if (item is model.OverdueInvoice) {
      return getRecommendedActionsForInvoice(item);
    } else if (item is model.Client) {
      return getRecommendedActionsForClient(item);
    }
    return [];
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
}
