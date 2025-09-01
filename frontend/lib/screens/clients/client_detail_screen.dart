// lib/screens/client/client_detail_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/creance_controller.dart';
import '../../models/client.dart';
import '../../layout/main_layout.dart';
import '../../widgets/client/detail/client_detail_header.dart';
import '../../widgets/client/detail/client_detail_tabs.dart';
import '../../widgets/client/liste/client_form_modal.dart';
import '../../widgets/client/detail/communication_dialog.dart';

/// Écran de détails complets d'un client
/// Selon le plan Sprint 2 - Frontend Core
class ClientDetailScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailScreen({Key? key, required this.clientId})
    : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  final ClientController _clientController = ClientController();
  final CreanceController _creanceController = CreanceController();
  late TabController _tabController;

  Client? _client;
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClientDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClientDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final success = await _clientController.selectClient(widget.clientId);
      if (success) {
        setState(() {
          _client = _clientController.selectedClient;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Client non trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur chargement client: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadClientDetails();
  }

  void _navigateToEdit() {
    if (_client != null) {
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
              client: _client,
              onSaved: () {
                Navigator.pop(context);
                _refreshData();
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteClient() async {
    if (_client == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${_client!.fullName} ?',
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
      final result = await _clientController.deleteClient(_client!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _addCommunication() async {
    if (_client == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CommunicationDialog(),
    );

    if (result != null) {
      final response = await _creanceController.addCommunication(
        _client!.id,
        type: result['type']!,
        subject: result['subject']!,
        content: result['content']!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          _refreshData();
        }
      }
    }
  }

  Future<void> _updateScore() async {
    if (_client == null) return;

    final response = await _creanceController.updateClientScore(_client!.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );
      if (response['success']) {
        _refreshData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/clients/detail',
      pageTitle: _client?.fullName ?? 'Détails Client',
      showStoreSelector: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_client?.fullName ?? 'Détails Client'),
          backgroundColor: const Color(0xFF7717E8),
          foregroundColor: Colors.white,
          actions: [
            if (_client != null) ...[
              IconButton(
                onPressed: _navigateToEdit,
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
              ),
              IconButton(
                onPressed: _addCommunication,
                icon: const Icon(Icons.message),
                tooltip: 'Ajouter communication',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'update_score':
                      _updateScore();
                      break;
                    case 'delete':
                      _deleteClient();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'update_score',
                    child: Text('Recalculer score'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer client'),
                  ),
                ],
              ),
            ],
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClientDetails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_client == null) {
      return const Center(child: Text('Client non trouvé'));
    }

    return Column(
      children: [
        ClientDetailHeader(client: _client!),
        ClientDetailTabs(
          client: _client!,
          clientController: _clientController,
          creanceController: _creanceController,
          tabController: _tabController,
          onRefresh: _refreshData,
        ),
      ],
    );
  }
}