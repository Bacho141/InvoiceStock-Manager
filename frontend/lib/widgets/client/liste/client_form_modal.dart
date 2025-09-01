import 'package:flutter/material.dart';
import '../../../controllers/client_controller.dart';
import '../../../models/client.dart';

/// Widget modal pour créer un nouveau client avec design moderne
class ClientFormModal extends StatefulWidget {
  final VoidCallback onSaved;
  final VoidCallback onCancel;
  final Client? client;

  const ClientFormModal({
    Key? key,
    required this.onSaved,
    required this.onCancel,
    this.client,
  }) : super(key: key);

  @override
  State<ClientFormModal> createState() => _ClientFormModalState();
}

class _ClientFormModalState extends State<ClientFormModal> {
  final _formKey = GlobalKey<FormState>();
  final ClientController _clientController = ClientController();

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();

  // Form values
  String _customerType = 'particulier';
  String _category = 'particulier';
  String _priority = 'bas';
  bool _isLoading = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _initializeForm();
    }
  }

  void _initializeForm() {
    final client = widget.client!;
    _firstNameController.text = client.firstName;
    _lastNameController.text = client.lastName;
    _phoneController.text = client.phone ?? '';
    _emailController.text = client.email ?? '';
    _addressController.text = client.address ?? '';
    _companyController.text = client.company ?? '';
    _customerType = client.customerType;
    _category = client.category;
    _priority = client.priority;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'email': _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        'address': _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        'company': _companyController.text.trim().isNotEmpty
            ? _companyController.text.trim()
            : null,
        'customerType': _customerType,
        'category': _category,
        'priority': _priority,
        'status': 'active',
        'creditLimit': 0.0,
        'paymentTerms': 30,
        'alertsEnabled': true,
        'creditLimitAlerts': true,
        'emailInvoices': false,
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
          widget.onSaved();
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
    return Column(
      children: [
        _buildModalHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPersonalInfoSection(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
                  const SizedBox(height: 24),
                  _buildBusinessSection(),
                ],
              ),
            ),
          ),
        ),
        _buildModalFooter(),
      ],
    );
  }

  Widget _buildModalHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7717E8), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isEditing ? Icons.edit : Icons.person_add,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Modifier Client' : 'Nouveau Client',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Modifiez les informations du client'
                      : 'Ajoutez un nouveau client à votre base',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection('Informations personnelles', Icons.person, [
      Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _firstNameController,
              label: 'Prénom',
              icon: Icons.person_outline,
              isRequired: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernTextField(
              controller: _lastNameController,
              label: 'Nom',
              icon: Icons.person_outline,
              isRequired: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildModernTextField(
        controller: _companyController,
        label: 'Entreprise (optionnel)',
        icon: Icons.business,
      ),
    ]);
  }

  Widget _buildContactSection() {
    return _buildSection('Contact', Icons.contact_phone, [
      Row(
        children: [
          Expanded(
            child: _buildModernTextField(
              controller: _phoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildModernTextField(
        controller: _addressController,
        label: 'Adresse',
        icon: Icons.location_on,
        maxLines: 2,
      ),
    ]);
  }

  Widget _buildBusinessSection() {
    return _buildSection('Informations commerciales', Icons.business_center, [
      Row(
        children: [
          Expanded(
            child: _buildModernDropdown(
              value: _customerType,
              label: 'Type de client',
              icon: Icons.category,
              items: const [
                {'value': 'particulier', 'label': 'Particulier'},
                {'value': 'entreprise', 'label': 'Entreprise'},
                {'value': 'administration', 'label': 'Administration'},
              ],
              onChanged: (value) => setState(() => _customerType = value!),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModernDropdown(
              value: _category,
              label: 'Catégorie',
              icon: Icons.label,
              items: const [
                {'value': 'particulier', 'label': 'Particulier'},
                {'value': 'grossiste', 'label': 'Grossiste'},
                {'value': 'detaillant', 'label': 'Détaillant'},
                {'value': 'vip', 'label': 'VIP'},
              ],
              onChanged: (value) => setState(() => _category = value!),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildModernDropdown(
        value: _priority,
        label: 'Priorité',
        icon: Icons.priority_high,
        items: const [
          {'value': 'bas', 'label': 'Faible'},
          {'value': 'normal', 'label': 'Normale'},
          {'value': 'haut', 'label': 'Élevée'},
        ],
        onChanged: (value) => setState(() => _priority = value!),
      ),
    ]);
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7717E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF7717E8), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: const Color(0xFF7717E8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7717E8), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: isRequired
          ? (value) =>
                value?.trim().isEmpty == true ? '$label est requis' : null
          : null,
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7717E8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7717E8), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModalFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : widget.onCancel,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7717E8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
                  : Text(
                      _isEditing ? 'Modifier' : 'Créer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}