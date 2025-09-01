import 'package:flutter/material.dart';
import '../../controllers/client_controller.dart';
import '../../models/client.dart';
import '../../widgets/client/liste/client_header_widget.dart';
import '../../widgets/client/liste/client_filters_widget.dart';
import '../../widgets/client/liste/client_stats_widget.dart';
import '../../widgets/client/liste/client_list_widget.dart';
import '../../widgets/client/liste/client_form_modal.dart';
import 'client_detail_screen.dart';

/// Écran de liste des clients avec filtres et recherche
/// Selon le plan Sprint 2 - Frontend Core
class ClientListScreen extends StatefulWidget {
  const ClientListScreen({Key? key}) : super(key: key);

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final ClientController _clientController = ClientController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _clientController.updateSearchQuery(_searchController.text);
    setState(() {});
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    final success = await _clientController.loadClients();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_clientController.lastError)),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refreshClients() async {
    await _clientController.refresh();
    setState(() {});
  }

  void _onStatusFilterChanged(String? value) {
    if (value != null) {
      setState(() => _selectedStatus = value);
      _clientController.updateStatusFilter(value);
    }
  }

  void _onCategoryFilterChanged(String? value) {
    if (value != null) {
      setState(() => _selectedCategory = value);
      _clientController.updateCategoryFilter(value);
    }
  }

  void _onSortChanged(String field, String order) {
    setState(() {
      _sortBy = field;
      _sortOrder = order;
    });
    _clientController.updateSort(field, order);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedCategory = 'all';
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
    });
    _searchController.clear();
    _clientController.clearFilters();
  }

  void _navigateToClientDetail(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(clientId: client.id),
      ),
    ).then((_) => _refreshClients());
  }

  void _navigateToCreateClient() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClientFormModal(
            onSaved: () {
              Navigator.pop(context);
              _refreshClients();
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  void _navigateToEditClient(Client client) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClientFormModal(
            client: client,
            onSaved: () {
              Navigator.pop(context);
              _refreshClients();
            },
            onCancel: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${client.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _clientController.deleteClient(client.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          setState(() {});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ClientHeaderWidget(
            searchController: _searchController,
            onCreateClient: _navigateToCreateClient,
            onRefresh: _refreshClients,
          ),
          ClientFiltersWidget(
            selectedStatus: _selectedStatus,
            selectedCategory: _selectedCategory,
            sortBy: _sortBy,
            sortOrder: _sortOrder,
            onStatusChanged: _onStatusFilterChanged,
            onCategoryChanged: _onCategoryFilterChanged,
            onSortChanged: _onSortChanged,
            onClearFilters: _clearFilters,
          ),
          ClientStatsWidget(
            stats: _clientController.getQuickStats(),
          ),
          ClientListWidget(
            clients: _clientController.filteredClients,
            isLoading: _isLoading,
            onClientTap: _navigateToClientDetail,
            onEditClient: _navigateToEditClient,
            onDeleteClient: _deleteClient,
          ),
        ],
      ),
    );
  }
}