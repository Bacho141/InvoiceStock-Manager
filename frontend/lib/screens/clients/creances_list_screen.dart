import 'package:flutter/material.dart';
import '../../controllers/creance_controller.dart';
import '../../models/client.dart' as model;
import 'client_detail_screen.dart';

import '../../widgets/creance_card.dart';

/// Écran de liste des créances avec filtres avancés
/// Selon le plan Sprint 2 - Frontend Core
class CreancesListScreen extends StatefulWidget {
  const CreancesListScreen({Key? key}) : super(key: key);

  @override
  State<CreancesListScreen> createState() => _CreancesListScreenState();
}

class _CreancesListScreenState extends State<CreancesListScreen> {
  final CreanceController _creanceController = CreanceController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCreances();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // La recherche sera implémentée si nécessaire
    setState(() {});
  }

  Future<void> _loadCreances() async {
    setState(() => _isLoading = true);
    final success = await _creanceController
        .loadOverdueInvoices(); // Changement ici
    if (!success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_creanceController.lastError)));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _refreshCreances() async {
    await _creanceController.refresh();
    setState(() {});
  }

  void _onDaysFilterChanged(int days) {
    _creanceController.updateDaysFilter(days);
    _loadCreances();
  }

  void _onAmountFilterChanged(String? value) {
    if (value != null) {
      _creanceController.updateAmountFilter(value);
      setState(() {});
    }
  }

  void _onPriorityFilterChanged(String? value) {
    if (value != null) {
      _creanceController.updatePriorityFilter(value);
      setState(() {});
    }
  }

  void _onSortChanged(String field, String order) {
    _creanceController.updateSort(field, order);
    setState(() {});
  }

  void _clearFilters() {
    _creanceController.clearFilters();
    _searchController.clear();
    setState(() {});
  }

  void _navigateToClientDetail(model.OverdueInvoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(clientId: invoice.client.id),
      ),
    ).then((_) => _refreshCreances());
  }

  Future<void> _addCommunication(model.OverdueInvoice invoice) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CommunicationDialog(),
    );

    if (result != null) {
      final response = await _creanceController.addCommunication(
        invoice.client.id,
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
          _refreshCreances();
        }
      }
    }
  }

  Future<void> _updateClientScore(model.OverdueInvoice invoice) async {
    final response = await _creanceController.updateClientScore(
      invoice.client.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );
      if (response['success']) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          _buildStats(),
          _buildCreancesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un client...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _refreshCreances,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _creanceController.amountFilter,
                        decoration: InputDecoration(
                          labelText: 'Montant',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tous montants'),
                          ),
                          DropdownMenuItem(
                            value: 'low',
                            child: Text('< 50K F'),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('50K - 200K F'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('> 200K F'),
                          ),
                        ],
                        onChanged: _onAmountFilterChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _creanceController.priorityFilter,
                        decoration: InputDecoration(
                          labelText: 'Priorité',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Toutes')),
                          DropdownMenuItem(value: 'low', child: Text('Faible')),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('Normale'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('Élevée'),
                          ),
                          DropdownMenuItem(
                            value: 'critical',
                            child: Text('Critique'),
                          ),
                        ],
                        onChanged: _onPriorityFilterChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Jours de retard minimum: ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _creanceController.daysFilter.toDouble(),
                        min: 1,
                        max: 180,
                        divisions: 17,
                        label: '${_creanceController.daysFilter} jours',
                        onChanged: (value) =>
                            _onDaysFilterChanged(value.toInt()),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7717E8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_creanceController.daysFilter}j',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7717E8),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value:
                            '${_creanceController.sortBy}-${_creanceController.sortOrder}',
                        items: const [
                          DropdownMenuItem(
                            value: 'amount-desc',
                            child: Text('Montant décroissant'),
                          ),
                          DropdownMenuItem(
                            value: 'amount-asc',
                            child: Text('Montant croissant'),
                          ),
                          DropdownMenuItem(
                            value: 'days-desc',
                            child: Text('Plus de retard'),
                          ),
                          DropdownMenuItem(
                            value: 'days-asc',
                            child: Text('Moins de retard'),
                          ),
                          DropdownMenuItem(
                            value: 'score-asc',
                            child: Text('Score faible'),
                          ),
                          DropdownMenuItem(
                            value: 'score-desc',
                            child: Text('Score élevé'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            final parts = value.split('-');
                            _onSortChanged(parts[0], parts[1]);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Effacer filtres'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final stats = _creanceController.quickStats;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7717E8).withOpacity(0.1),
            const Color(0xFF9C27B0).withOpacity(0.1),
          ],
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildModernStatItem(
            'Factures',
            '${stats['totalInvoices'] ?? 0}',
            Icons.receipt,
            Colors.blue,
          ),
          _buildModernStatItem(
            'Total',
            _creanceController.formatCurrency(stats['totalAmount']?.toDouble() ?? 0),
            Icons.account_balance_wallet,
            Colors.red,
          ),
          _buildModernStatItem(
            'Moyenne',
            _creanceController.formatCurrency(stats['averageAmount']?.toDouble() ?? 0),
            Icons.calculate,
            Colors.orange,
          ),
          _buildModernStatItem(
            'Critiques',
            '${stats['criticalInvoices'] ?? 0}',
            Icons.warning,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCreancesList() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final invoices = _creanceController.filteredOverdueInvoices;

    if (invoices.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune créance trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajustez vos filtres ou félicitations !',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Regroupement des factures par client en utilisant l'ID du client comme clé
    final Map<String, List<model.OverdueInvoice>> groupedById = {};
    for (var invoice in invoices) {
      if (groupedById.containsKey(invoice.client.id)) {
        groupedById[invoice.client.id]!.add(invoice);
      } else {
        groupedById[invoice.client.id] = [invoice];
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: groupedById.entries.map((entry) {
          // Le client est le même pour toutes les factures de la liste
          final client = entry.value.first.client;
          final clientInvoices = entry.value;
          return _buildClientGroupCard(client, clientInvoices);
        }).toList(),
      ),
    );
  }

  Widget _buildClientGroupCard(model.Client client, List<model.OverdueInvoice> invoices) {
    // Calculer le montant total pour le client
    final double totalAmount = invoices.fold(0.0, (sum, item) => sum + item.outstandingAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF7717E8).withOpacity(0.1),
          child: Text(
            client.fullName.isNotEmpty ? client.fullName[0].toUpperCase() : 'C',
            style: const TextStyle(color: Color(0xFF7717E8), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          client.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748)),
        ),
        subtitle: Text(
          '${invoices.length} facture(s) en retard',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _creanceController.formatCurrency(totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            Text(
              'Total Dû',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        children: invoices.map((invoice) => CreanceCard(
          invoice: invoice,
          controller: _creanceController,
          onNavigateToDetail: () => _navigateToClientDetail(invoice),
          onAddCommunication: () => _addCommunication(invoice),
          onUpdateScore: () => _updateClientScore(invoice),
        )).toList(),
      ),
    );
  }

  
}

/// Dialog pour ajouter une communication
class _CommunicationDialog extends StatefulWidget {
  @override
  State<_CommunicationDialog> createState() => _CommunicationDialogState();
}

class _CommunicationDialogState extends State<_CommunicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'call';

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une communication'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'call',
                  child: Text('Appel téléphonique'),
                ),
                DropdownMenuItem(value: 'email', child: Text('Email')),
                DropdownMenuItem(value: 'meeting', child: Text('Rendez-vous')),
                DropdownMenuItem(value: 'letter', child: Text('Courrier')),
              ],
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Sujet'),
              validator: (value) =>
                  value?.isEmpty == true ? 'Le sujet est requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Contenu'),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty == true ? 'Le contenu est requis' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'type': _selectedType,
                'subject': _subjectController.text,
                'content': _contentController.text,
              });
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
