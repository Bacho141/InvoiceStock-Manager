import 'package:flutter/material.dart';
import '../../controllers/cart_controller.dart';
import '../../models/user.dart';
import 'add_client_modal.dart';
import '../../services/client_service.dart';

class ClientPaymentPanel extends StatefulWidget {
  final bool isTablet;
  const ClientPaymentPanel({Key? key, this.isTablet = false}) : super(key: key);

  @override
  State<ClientPaymentPanel> createState() => _ClientPaymentPanelState();
}

class _ClientPaymentPanelState extends State<ClientPaymentPanel> {
  final cart = CartController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final _clientService = ClientService();
  final _amountController = TextEditingController();

  List<User> _clients = [];
  User? _selectedClient;
  bool _loadingClients = false;

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _amountController.text = cart.total > 0 ? cart.total.toStringAsFixed(0) : '';
    cart.setAmountPaid(cart.total);

    _amountController.addListener(() {
      final amount = double.tryParse(_amountController.text) ?? 0;
      cart.setAmountPaid(amount);
    });
  }

  Future<void> _fetchClients() async {
    setState(() => _loadingClients = true);
    try {
      final data = await _clientService.getClients();
      setState(() {
        _clients = data
            .map<User>(
              (c) => User(
                id: c['_id'] ?? '',
                username: ((c['firstName'] ?? '') + ' ' + (c['lastName'] ?? ''))
                    .trim(),
                role: 'client',
                assignedStores: const [],
                isActive: true,
                createdAt:
                    DateTime.tryParse(c['createdAt'] ?? '') ?? DateTime.now(),
                hasTempPassword: false,
              ),
            )
            .toList();
        _selectedClient =
            cart.client ?? (_clients.isNotEmpty ? _clients.first : null);
      });
    } catch (e) {
      setState(() => _clients = []);
    } finally {
      setState(() => _loadingClients = false);
    }
  }

  void _showAddClientModal() {
    showDialog(
      context: context,
      builder: (context) => AddClientModal(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        phoneController: _phoneController,
        onCancel: () {
          Navigator.of(context).pop();
        },
        onSave: () async {
          final data = {
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'phone': _phoneController.text,
          };
          try {
            final client = await _clientService.createClient(data);
            Navigator.of(context).pop();
            await _fetchClients();
            setState(() {
              final newClient = _clients.firstWhere(
                (u) => u.id == client['data']['_id'],
                orElse: () => _clients.last,
              );
              _selectedClient = newClient;
              cart.setClient(newClient);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client créé avec succès')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur création client: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        final total = cart.total;
        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(20),
            child: ListView(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre avec indicateur
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.person, color: Color(0xFF7717E8)),
                          SizedBox(width: 8),
                          Text(
                            'Client & Paiement',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 3,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7717E8),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7717E8).withOpacity(0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Sélection/ajout client
                Row(
                  children: [
                    Expanded(
                      child: _loadingClients
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<User>(
                              value: _selectedClient,
                              decoration: const InputDecoration(
                                labelText: 'Client',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Color(0xFFF7F7FA),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                              ),
                              items: _clients
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.username),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedClient = v;
                                  cart.setClient(v);
                                });
                              },
                            ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _showAddClientModal,
                      icon: const Icon(Icons.person_add),
                      label: const Text(
                        'Créer client',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7717E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Totaux (amélioré, sans TVA)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL: ${total.toStringAsFixed(0)} F',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF7717E8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Saisie montant payé
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Montant versé *',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF7F7FA),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),
                // Méthode de paiement
                const Text(
                  'Méthode de Paiement',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPaymentMethodRadio('especes', 'Espèces'),
                    _buildPaymentMethodRadio('cheque', 'Chèque'),
                    _buildPaymentMethodRadio('virement', 'Virement'),
                  ],
                ),
                const SizedBox(height: 12),
                // Reste à payer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reste à Payer :',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${cart.dueAmount.toStringAsFixed(0)} F',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodRadio(String value, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: cart.paymentMethod,
          onChanged: (v) {
            if (v != null) cart.setPaymentMethod(v);
          },
        ),
        Text(title),
      ],
    );
  }
}
