import 'package:flutter/material.dart';
import '../../controllers/client_controller.dart';
import '../../models/client.dart';

/// Écran de formulaire pour créer ou modifier un client
/// Selon le plan Sprint 2 - Frontend Core
class ClientFormScreen extends StatefulWidget {
  final Client? client; // null pour création, rempli pour modification

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen>
    with SingleTickerProviderStateMixin {
  final ClientController _clientController = ClientController();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers pour les champs du formulaire
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _assignedSalespersonController = TextEditingController();

  // Variables pour les dropdowns et checkboxes
  String _customerType = 'particulier';
  String _category = 'particulier';
  String _priority = 'normal';
  String _status = 'active';
  String? _assignedStore;
  String? _preferredPaymentMethod;
  bool _alertsEnabled = true;
  bool _creditLimitAlerts = true;
  bool _emailInvoices = false;

  bool _isLoading = false;
  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    print('Initialisation de ClientFormScreen');

    // Code de débogage déplacé du constructeur
    if (widget.client != null) {
      print('ClientFormScreen initialisé avec un client:');
      print('ID: ${widget.client!.id}');
      print('Nom: ${widget.client!.firstName} ${widget.client!.lastName}');
    } else {
      print('ClientFormScreen initialisé en mode création');
    }

    try {
      _tabController = TabController(length: 3, vsync: this);
      print('TabController initialisé avec succès');
      _initializeForm();
    } catch (e, stackTrace) {
      print('Erreur lors de l\'initialisation: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _creditLimitController.dispose();
    _paymentTermsController.dispose();
    _assignedSalespersonController.dispose();
  }

  void _initializeForm() {
    print('Initialisation du formulaire. Mode édition: $_isEditing');
    if (_isEditing) {
      final client = widget.client!;
      print(
        'Client reçu: ID=${client.id}, Nom=${client.firstName} ${client.lastName}',
      );

      // Vérification des propriétés obligatoires
      try {
        _firstNameController.text = client.firstName ?? '';
        _lastNameController.text = client.lastName ?? '';
        _phoneController.text = client.phone ?? '';
        _emailController.text = client.email ?? '';
        _addressController.text = client.address ?? '';
        _companyController.text = client.company ?? '';
        _cityController.text = client.city ?? '';
        _regionController.text = client.region ?? '';
        _creditLimitController.text = (client.creditLimit ?? 0.0).toString();
        _paymentTermsController.text = (client.paymentTerms ?? 30).toString();
        _assignedSalespersonController.text = client.assignedSalesperson ?? '';

        // Gestion des valeurs par défaut pour les dropdowns
        _customerType = client.customerType ?? 'particulier';
        _category = client.category ?? 'particulier';
        _priority = client.priority ?? 'normal';
        _status = client.status ?? 'active';
        _assignedStore = client.assignedStore;

        // Correction de la valeur de preferredPaymentMethod
        _preferredPaymentMethod = _correctPaymentMethodValue(
          client.preferredPaymentMethod,
        );

        _alertsEnabled = client.alertsEnabled ?? true;
        _creditLimitAlerts = client.creditLimitAlerts ?? true;
        _emailInvoices = client.emailInvoices ?? false;

        print('Formulaire initialisé avec succès');
        print('preferredPaymentMethod corrigé: $_preferredPaymentMethod');
      } catch (e, stackTrace) {
        print('Erreur lors de l\'initialisation du formulaire: $e');
        print('Stack trace: $stackTrace');
        // Valeurs par défaut en cas d'erreur
        _customerType = 'particulier';
        _category = 'particulier';
        _priority = 'normal';
        _status = 'active';
        _preferredPaymentMethod = null;
        _paymentTermsController.text = '30';
        _creditLimitController.text = '0';
        rethrow;
      }
    } else {
      // Valeurs par défaut pour nouveau client
      _paymentTermsController.text = '30';
      _creditLimitController.text = '0';
      print('Formulaire initialisé en mode création');
    }
  }

  // Méthode pour corriger les valeurs incompatibles de preferredPaymentMethod
  String? _correctPaymentMethodValue(String? value) {
    if (value == null) return null;

    // Mapping des anciennes valeurs vers les nouvelles
    switch (value.toLowerCase()) {
      case 'especes':
      case 'cash':
        return 'cash';
      case 'virement':
      case 'bank_transfer':
        return 'bank_transfer';
      case 'cheque':
      case 'check':
        return 'check';
      case 'mobile':
      case 'mobile_money':
        return 'mobile_money';
      case 'carte':
      case 'card':
        return 'card';
      default:
        // Si la valeur n'est pas reconnue, on retourne null
        return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'company': _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        'city': _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        'region': _regionController.text.trim().isEmpty
            ? null
            : _regionController.text.trim(),
        'customerType': _customerType,
        'category': _category,
        'priority': _priority,
        'status': _status,
        'assignedStore': _assignedStore,
        'creditLimit': double.tryParse(_creditLimitController.text) ?? 0,
        'paymentTerms': int.tryParse(_paymentTermsController.text) ?? 30,
        'assignedSalesperson':
            _assignedSalespersonController.text.trim().isEmpty
            ? null
            : _assignedSalespersonController.text.trim(),
        'preferredPaymentMethod': _preferredPaymentMethod,
        'alertsEnabled': _alertsEnabled,
        'creditLimitAlerts': _creditLimitAlerts,
        'emailInvoices': _emailInvoices,
      };

      final result = _isEditing
          ? await _clientController.updateClient(widget.client!.id, data)
          : await _clientController.createClient(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        if (result['success']) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier Client' : 'Nouveau Client'),
        backgroundColor: const Color(0xFF7717E8),
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _submitForm,
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(child: _buildTabBarView()),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF7717E8),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF7717E8),
      tabs: const [
        Tab(icon: Icon(Icons.person), text: 'Identité'),
        Tab(icon: Icon(Icons.business), text: 'Commercial'),
        Tab(icon: Icon(Icons.settings), text: 'Configuration'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return Form(
      key: _formKey,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildIdentityTab(),
          _buildCommercialTab(),
          _buildConfigurationTab(),
        ],
      ),
    );
  }

  Widget _buildIdentityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Le prénom est requis'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true
                      ? 'Le nom est requis'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isNotEmpty == true && !value!.contains('@')) {
                return 'Format email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Entreprise',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _regionController,
                  decoration: const InputDecoration(
                    labelText: 'Région',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommercialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _customerType,
            decoration: const InputDecoration(
              labelText: 'Type de client',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'particulier',
                child: Text('Particulier'),
              ),
              DropdownMenuItem(value: 'entreprise', child: Text('Entreprise')),
              DropdownMenuItem(
                value: 'administration',
                child: Text('Administration'),
              ),
            ],
            onChanged: (value) => setState(() => _customerType = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'particulier',
                child: Text('Particulier'),
              ),
              DropdownMenuItem(value: 'grossiste', child: Text('Grossiste')),
              DropdownMenuItem(value: 'detaillant', child: Text('Détaillant')),
              DropdownMenuItem(value: 'vip', child: Text('VIP')),
            ],
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Priorité',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Faible')),
              DropdownMenuItem(value: 'normal', child: Text('Normale')),
              DropdownMenuItem(value: 'high', child: Text('Élevée')),
              DropdownMenuItem(value: 'critical', child: Text('Critique')),
            ],
            onChanged: (value) => setState(() => _priority = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Statut',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'active', child: Text('Actif')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
              DropdownMenuItem(value: 'blocked', child: Text('Bloqué')),
            ],
            onChanged: (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _assignedStore,
            decoration: const InputDecoration(
              labelText: 'Magasin assigné',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Aucun')),
              DropdownMenuItem(
                value: 'store1',
                child: Text('Magasin Principal'),
              ),
              DropdownMenuItem(
                value: 'store2',
                child: Text('Magasin Secondaire'),
              ),
              DropdownMenuItem(value: 'warehouse', child: Text('Entrepôt')),
            ],
            onChanged: (value) => setState(() => _assignedStore = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _assignedSalespersonController,
            decoration: const InputDecoration(
              labelText: 'Commercial assigné',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            controller: _creditLimitController,
            decoration: const InputDecoration(
              labelText: 'Limite de crédit (F)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.account_balance_wallet),
              helperText: '0 = aucune limite',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              final amount = double.tryParse(value ?? '');
              if (amount == null || amount < 0) {
                return 'Montant invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentTermsController,
            decoration: const InputDecoration(
              labelText: 'Délai de paiement (jours)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              final days = int.tryParse(value ?? '');
              if (days == null || days < 0) {
                return 'Nombre de jours invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            value: _preferredPaymentMethod,
            decoration: const InputDecoration(
              labelText: 'Mode de paiement préféré',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('Aucune préférence')),
              DropdownMenuItem(value: 'cash', child: Text('Espèces')),
              DropdownMenuItem(
                value: 'bank_transfer',
                child: Text('Virement bancaire'),
              ),
              DropdownMenuItem(value: 'check', child: Text('Chèque')),
              DropdownMenuItem(
                value: 'mobile_money',
                child: Text('Mobile Money'),
              ),
              DropdownMenuItem(value: 'card', child: Text('Carte bancaire')),
            ],
            onChanged: (value) =>
                setState(() => _preferredPaymentMethod = value),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications et alertes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _alertsEnabled,
                    onChanged: (value) =>
                        setState(() => _alertsEnabled = value),
                    title: const Text('Alertes activées'),
                    subtitle: const Text(
                      'Recevoir des notifications sur ce client',
                    ),
                  ),
                  SwitchListTile(
                    value: _creditLimitAlerts,
                    onChanged: (value) =>
                        setState(() => _creditLimitAlerts = value),
                    title: const Text('Alertes limite de crédit'),
                    subtitle: const Text('Alerter en cas de dépassement'),
                  ),
                  SwitchListTile(
                    value: _emailInvoices,
                    onChanged: (value) =>
                        setState(() => _emailInvoices = value),
                    title: const Text('Envoi factures par email'),
                    subtitle: const Text(
                      'Envoyer automatiquement les factures',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7717E8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_isEditing ? 'Modifier' : 'Créer'),
            ),
          ),
        ],
      ),
    );
  }
}
