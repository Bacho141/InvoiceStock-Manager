import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/client_service.dart';

/// Contrôleur principal pour la gestion des clients
/// Selon le plan Sprint 2 - Frontend Core
class ClientController {
  final ClientService _clientService = ClientService();

  // Cache local pour optimiser les performances
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Client? _selectedClient;
  String _lastError = '';

  // Paramètres de filtrage et tri
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  // Getters
  List<Client> get clients => List.unmodifiable(_clients);
  List<Client> get filteredClients => List.unmodifiable(_filteredClients);
  Client? get selectedClient => _selectedClient;
  String get lastError => _lastError;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get categoryFilter => _categoryFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // ============ Méthodes CRUD ============

  /// Charge la liste des clients
  Future<bool> loadClients({bool refresh = false}) async {
    try {
      debugPrint('[ClientController] Chargement clients...');
      _lastError = '';

      final clientsData = await _clientService.getClients();

      _clients = clientsData
          .map((clientData) => Client.fromJson(clientData))
          .toList();

      _applyFilters();

      debugPrint('[ClientController] ${_clients.length} clients chargés');
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement clients: $e';
      debugPrint('[ClientController] Erreur: $e');
      return false;
    }
  }

  /// Crée un nouveau client
  Future<Map<String, dynamic>> createClient(
    Map<String, dynamic> clientData,
  ) async {
    try {
      debugPrint(
        '[ClientController] Création client: ${clientData['firstName']} ${clientData['lastName']}',
      );
      _lastError = '';

      final response = await _clientService.createClient(clientData);
      final newClient = Client.fromJson(response['data']);

      _clients.add(newClient);
      _applyFilters();

      debugPrint('[ClientController] Client créé: ${newClient.id}');
      return {
        'success': true,
        'message': 'Client créé avec succès',
        'client': newClient,
      };
    } catch (e) {
      _lastError = 'Erreur création client: $e';
      debugPrint('[ClientController] Erreur création: $e');
      return {'success': false, 'message': _lastError};
    }
  }

  /// Met à jour un client existant
  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    try {
      debugPrint('[ClientController] Mise à jour client: $clientId');
      _lastError = '';

      final response = await _clientService.updateClient(clientId, clientData);
      final updatedClient = Client.fromJson(response['data']);

      final index = _clients.indexWhere((c) => c.id == clientId);
      if (index != -1) {
        _clients[index] = updatedClient;
        _applyFilters();
      }

      // Mettre à jour le client sélectionné si c'est le même
      if (_selectedClient?.id == clientId) {
        _selectedClient = updatedClient;
      }

      debugPrint('[ClientController] Client mis à jour: $clientId');
      return {
        'success': true,
        'message': 'Client mis à jour avec succès',
        'client': updatedClient,
      };
    } catch (e) {
      _lastError = 'Erreur mise à jour client: $e';
      debugPrint('[ClientController] Erreur mise à jour: $e');
      return {'success': false, 'message': _lastError};
    }
  }

  /// Supprime un client
  Future<Map<String, dynamic>> deleteClient(String clientId) async {
    try {
      debugPrint('[ClientController] Suppression client: $clientId');
      _lastError = '';

      await _clientService.deleteClient(clientId);

      _clients.removeWhere((c) => c.id == clientId);
      _applyFilters();

      // Désélectionner si c'est le client supprimé
      if (_selectedClient?.id == clientId) {
        _selectedClient = null;
      }

      debugPrint('[ClientController] Client supprimé: $clientId');
      return {'success': true, 'message': 'Client supprimé avec succès'};
    } catch (e) {
      _lastError = 'Erreur suppression client: $e';
      debugPrint('[ClientController] Erreur suppression: $e');
      return {'success': false, 'message': _lastError};
    }
  }

  /// Sélectionne un client et charge ses détails
  Future<bool> selectClient(String clientId) async {
    try {
      debugPrint('[ClientController] Sélection client: $clientId');
      _lastError = '';

      final response = await _clientService.getClientById(clientId);
      _selectedClient = Client.fromJson(response['data']);

      debugPrint(
        '[ClientController] Client sélectionné: ${_selectedClient!.fullName}',
      );
      return true;
    } catch (e) {
      _lastError = 'Erreur chargement client: $e';
      debugPrint('[ClientController] Erreur sélection: $e');
      return false;
    }
  }

  // ============ Méthodes de filtrage et recherche ============

  /// Applique les filtres et la recherche
  void _applyFilters() {
    var filtered = _clients.toList();

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((client) {
        return client.fullName.toLowerCase().contains(query) ||
            client.phone?.toLowerCase().contains(query) == true ||
            client.email?.toLowerCase().contains(query) == true ||
            client.company?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Filtre par statut
    if (_statusFilter != 'all') {
      filtered = filtered
          .where((client) => client.status == _statusFilter)
          .toList();
    }

    // Filtre par catégorie
    if (_categoryFilter != 'all') {
      filtered = filtered
          .where((client) => client.category == _categoryFilter)
          .toList();
    }

    // Tri
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'totalRevenue':
          comparison = a.totalRevenue.compareTo(b.totalRevenue);
          break;
        case 'creditScore':
          comparison = a.creditScore.compareTo(b.creditScore);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortOrder == 'desc' ? -comparison : comparison;
    });

    _filteredClients = filtered;
    debugPrint(
      '[ClientController] Filtres appliqués: ${filtered.length} clients',
    );
  }

  /// Met à jour la requête de recherche
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Met à jour le filtre de statut
  void updateStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  /// Met à jour le filtre de catégorie
  void updateCategoryFilter(String category) {
    _categoryFilter = category;
    _applyFilters();
  }

  /// Met à jour les paramètres de tri
  void updateSort(String field, String order) {
    _sortBy = field;
    _sortOrder = order;
    _applyFilters();
  }

  // ============ Méthodes utilitaires ============

  /// Réinitialise tous les filtres
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = 'all';
    _categoryFilter = 'all';
    _sortBy = 'createdAt';
    _sortOrder = 'desc';
    _applyFilters();
  }

  /// Obtient un client par son ID
  Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un client existe déjà (par téléphone)
  bool clientExists(String phone) {
    return _clients.any((client) => client.phone == phone);
  }

  /// Obtient les statistiques rapides
  Map<String, dynamic> getQuickStats() {
    final activeClients = _clients.where((c) => c.status == 'active').length;
    final totalRevenue = _clients.fold<double>(
      0,
      (sum, c) => sum + c.totalRevenue,
    );
    final totalOutstanding = _clients.fold<double>(
      0,
      (sum, c) => sum + c.currentOutstanding,
    );
    final averageScore = _clients.isNotEmpty
        ? _clients.fold<double>(0, (sum, c) => sum + c.creditScore) /
              _clients.length
        : 0.0;

    return {
      'totalClients': _clients.length,
      'activeClients': activeClients,
      'totalRevenue': totalRevenue,
      'totalOutstanding': totalOutstanding,
      'averageScore': averageScore,
    };
  }

  /// Rafraîchit les données
  Future<bool> refresh() async {
    return await loadClients(refresh: true);
  }

  /// Désélectionne le client actuel
  void clearSelection() {
    _selectedClient = null;
  }

  /// Recherche de clients avec filtres avancés
  Future<List<Client>> searchClients({
    String? search,
    String? status,
    String? category,
    String? assignedStore,
    String? sortBy = 'createdAt',
    String? sortOrder = 'desc',
  }) async {
    try {
      debugPrint('[ClientController] Recherche clients avec filtres');
      _lastError = '';

      // Pour l'instant, utilisons getClients() basique et filtrons localement
      final clientsData = await _clientService.getClients();
      var clients = clientsData
          .map((clientData) => Client.fromJson(clientData))
          .toList();

      // Filtrage local
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        clients = clients.where((client) {
          return client.fullName.toLowerCase().contains(query) ||
              client.phone?.toLowerCase().contains(query) == true ||
              client.email?.toLowerCase().contains(query) == true ||
              client.company?.toLowerCase().contains(query) == true;
        }).toList();
      }

      if (status != null && status != 'all') {
        clients = clients.where((client) => client.status == status).toList();
      }

      if (category != null && category != 'all') {
        clients = clients
            .where((client) => client.category == category)
            .toList();
      }

      return clients;
    } catch (e) {
      _lastError = 'Erreur recherche clients: $e';
      debugPrint('[ClientController] Erreur recherche: $e');
      return [];
    }
  }
}
