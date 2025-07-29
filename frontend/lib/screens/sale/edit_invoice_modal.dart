import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utiles/api_urls.dart';
import '../../services/client_service.dart';

class EditInvoiceModal extends StatefulWidget {
  final Map<String, dynamic> facture;
  final VoidCallback onInvoiceUpdated;
  
  const EditInvoiceModal({
    Key? key,
    required this.facture,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  State<EditInvoiceModal> createState() => _EditInvoiceModalState();
}

class _EditInvoiceModalState extends State<EditInvoiceModal> {
  late List<Map<String, dynamic>> _lines;
  late TextEditingController _remiseController;
  late TextEditingController _montantPayeController;
  
  // Client info controllers
  late TextEditingController _clientFirstNameController;
  late TextEditingController _clientLastNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientEmailController;
  late TextEditingController _clientAddressController;
  
  String? _clientId;
  String? _clientName;
  bool _saving = false;
  bool _editingClient = false;
  String? _error;
  String? _successMessage;
  
  final ClientService _clientService = ClientService();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _remiseController.dispose();
    _montantPayeController.dispose();
    _clientFirstNameController.dispose();
    _clientLastNameController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final facture = widget.facture;
    _lines = List<Map<String, dynamic>>.from(facture['lines'] ?? []);
    
    _remiseController = TextEditingController(
      text: (facture['discountTotal'] ?? 0).toString(),
    );
    _montantPayeController = TextEditingController(
      text: (facture['montantPaye'] ?? 0).toString(),
    );
    
    // Initialize client data and controllers
    final client = facture['client'];
    if (client is Map) {
      _clientId = client['_id']?.toString();
      _clientName = '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim();
      
      // Initialize client editing controllers
      _clientFirstNameController = TextEditingController(
        text: client['firstName']?.toString() ?? '',
      );
      _clientLastNameController = TextEditingController(
        text: client['lastName']?.toString() ?? '',
      );
      _clientPhoneController = TextEditingController(
        text: client['phone']?.toString() ?? '',
      );
      _clientEmailController = TextEditingController(
        text: client['email']?.toString() ?? '',
      );
      _clientAddressController = TextEditingController(
        text: client['address']?.toString() ?? '',
      );
    } else {
      _clientId = client?.toString();
      _clientName = client?.toString() ?? 'Client inconnu';
      
      // Initialize empty controllers for unknown client
      _clientFirstNameController = TextEditingController();
      _clientLastNameController = TextEditingController();
      _clientPhoneController = TextEditingController();
      _clientEmailController = TextEditingController();
      _clientAddressController = TextEditingController();
    }
  }

  num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  num get _subtotal {
    num subtotal = 0;
    for (final line in _lines) {
      final unitPrice = _parseNum(line['unitPrice']);
      final quantity = _parseNum(line['quantity']);
      final discount = _parseNum(line['discount'] ?? 0);
      subtotal += (unitPrice * quantity) - discount;
    }
    return subtotal;
  }

  num get _totalWithGlobalDiscount {
    final globalDiscount = _parseNum(_remiseController.text);
    return _subtotal - globalDiscount;
  }

  bool _validateData() {
    // Validation des quantités
    for (final line in _lines) {
      final quantity = _parseNum(line['quantity']);
      final unitPrice = _parseNum(line['unitPrice']);
      
      if (quantity <= 0) {
        _setError('Quantité invalide pour ${line['productName'] ?? 'un produit'}');
        return false;
      }
      
      if (unitPrice < 0) {
        _setError('Prix unitaire invalide pour ${line['productName'] ?? 'un produit'}');
        return false;
      }
    }

    // Validation de la remise globale
    final globalDiscount = _parseNum(_remiseController.text);
    if (globalDiscount < 0) {
      _setError('La remise ne peut pas être négative');
      return false;
    }
    
    if (globalDiscount > _subtotal) {
      _setError('La remise ne peut pas dépasser le sous-total');
      return false;
    }

    // Validation du montant payé
    final montantPaye = _parseNum(_montantPayeController.text);
    final totalFinal = _totalWithGlobalDiscount;
    
    if (montantPaye < 0) {
      _setError('Le montant payé ne peut pas être négatif');
      return false;
    }
    
    if (montantPaye > totalFinal) {
      _setError('Le montant payé ne peut pas dépasser le total');
      return false;
    }

    return true;
  }

  void _setError(String message) {
    setState(() {
      _error = message;
      _successMessage = null;
    });
  }

  void _setSuccess(String message) {
    setState(() {
      _successMessage = message;
      _error = null;
    });
  }

  void _clearMessages() {
    setState(() {
      _error = null;
      _successMessage = null;
    });
  }

  void _updateQuantity(int index, String value) {
    final quantity = num.tryParse(value) ?? 0;
    setState(() {
      _lines[index]['quantity'] = quantity;
      _clearMessages();
    });
  }

  void _toggleClientEditing() {
    setState(() {
      _editingClient = !_editingClient;
      _clearMessages();
    });
  }

  Future<void> _saveClientInfo() async {
    if (_clientId == null) {
      _setError('Impossible de modifier un client non identifié');
      return;
    }

    // Validation des champs client
    if (_clientFirstNameController.text.trim().isEmpty ||
        _clientLastNameController.text.trim().isEmpty ||
        _clientPhoneController.text.trim().isEmpty) {
      _setError('Le prénom, nom et téléphone sont obligatoires');
      return;
    }

    setState(() {
      _saving = true;
      _clearMessages();
    });

    try {
      final clientData = {
        'firstName': _clientFirstNameController.text.trim(),
        'lastName': _clientLastNameController.text.trim(),
        'phone': _clientPhoneController.text.trim(),
        'email': _clientEmailController.text.trim().isEmpty 
            ? null 
            : _clientEmailController.text.trim(),
        'address': _clientAddressController.text.trim().isEmpty 
            ? null 
            : _clientAddressController.text.trim(),
      };

      await _clientService.updateClient(_clientId!, clientData);
      
      // Update local client name display
      setState(() {
        _clientName = '${_clientFirstNameController.text.trim()} ${_clientLastNameController.text.trim()}'.trim();
        _editingClient = false;
      });
      
      _setSuccess('Informations client mises à jour avec succès');
    } catch (e) {
      _setError('Erreur lors de la mise à jour du client: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_validateData()) return;

    setState(() {
      _saving = true;
      _clearMessages();
    });

    try {
      final payload = _buildPayload();
      final response = await _sendUpdateRequest(payload);
      
      if (response.statusCode == 200) {
        _setSuccess('Facture mise à jour avec succès');
        
        // Fermer le modal après un délai court pour montrer le message de succès
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onInvoiceUpdated();
            Navigator.of(context).pop();
          }
        });
      } else {
        _handleErrorResponse(response);
      }
    } catch (e) {
      _setError('Erreur de connexion: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    final globalDiscount = _parseNum(_remiseController.text);
    final montantPaye = _parseNum(_montantPayeController.text);
    
    return {
      'client': _clientId,
      'lines': _lines.map((line) {
        final unitPrice = _parseNum(line['unitPrice']);
        final quantity = _parseNum(line['quantity']);
        final discount = _parseNum(line['discount'] ?? 0);
        
        return {
          'product': line['product'],
          'productName': line['productName'],
          'quantity': quantity,
          'unitPrice': unitPrice,
          'discount': discount,
          'totalLine': (unitPrice * quantity) - discount,
        };
      }).toList(),
      'discountTotal': globalDiscount,
      'montantPaye': montantPaye,
      'total': _totalWithGlobalDiscount,
    };
  }

  Future<http.Response> _sendUpdateRequest(Map<String, dynamic> payload) async {
    final invoiceId = widget.facture['_id'] ?? widget.facture['id'];
    final url = '${ApiUrls.invoices}/$invoiceId';
    
    return await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] ?? errorData['error'] ?? 'Erreur inconnue';
      _setError('Erreur ${response.statusCode}: $errorMessage');
    } catch (e) {
      _setError('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          minWidth: 400,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1.2, color: Color(0xFFF3F0FA)),
            Expanded(child: _buildBody()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F0FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: const [
          Icon(Icons.edit, color: Color(0xFF7717E8), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Modifier le reçu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF7717E8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClientInfo(),
          const SizedBox(height: 20),
          _buildProductsList(),
          const SizedBox(height: 20),
          _buildDiscountField(),
          const SizedBox(height: 16),
          _buildPaymentField(),
          const SizedBox(height: 16),
          _buildTotalSection(),
          if (_error != null || _successMessage != null) ...[
            const SizedBox(height: 16),
            _buildMessageSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      color: const Color(0xFFF8F9FA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF7717E8), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Informations Client',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const Spacer(),
                if (!_editingClient)
                  IconButton(
                    onPressed: _clientId != null ? _toggleClientEditing : null,
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Modifier les informations client',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_editingClient) ..._buildClientEditingFields() else ..._buildClientDisplayFields(),
            if (_editingClient) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : _toggleClientEditing,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveClientInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7717E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Sauvegarder'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produits',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey[50],
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: _lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                return _buildProductLine(index, line);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductLine(int index, Map<String, dynamic> line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              line['productName'] ?? '',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextFormField(
              initialValue: line['quantity'].toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Qté',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) => _updateQuantity(index, value),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'x ${_parseNum(line['unitPrice']).toStringAsFixed(0)} F',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            '= ${(_parseNum(line['unitPrice']) * _parseNum(line['quantity'])).toStringAsFixed(0)} F',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountField() {
    return TextFormField(
      controller: _remiseController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Remise totale',
        prefixIcon: const Icon(Icons.percent, color: Color(0xFF7717E8)),
        suffixText: 'F',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) => setState(() => _clearMessages()),
    );
  }

  Widget _buildPaymentField() {
    return TextFormField(
      controller: _montantPayeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Montant payé',
        prefixIcon: const Icon(Icons.payments, color: Color(0xFF7717E8)),
        suffixText: 'F',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (_) => setState(() => _clearMessages()),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      color: const Color(0xFFF8F9FA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sous-total :', style: TextStyle(fontSize: 14)),
                Text('${_subtotal.toStringAsFixed(0)} F', style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remise :', style: TextStyle(fontSize: 14)),
                Text('-${_parseNum(_remiseController.text).toStringAsFixed(0)} F', 
                     style: const TextStyle(fontSize: 14, color: Colors.red)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_totalWithGlobalDiscount.toStringAsFixed(0)} F', 
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF7717E8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _error != null ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _error != null ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _error != null ? Icons.error_outline : Icons.check_circle_outline,
            color: _error != null ? Colors.red : Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? _successMessage ?? '',
              style: TextStyle(
                color: _error != null ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildClientDisplayFields() {
    return [
      _buildInfoRow('Nom complet', _clientName ?? 'Non défini'),
      _buildInfoRow('Téléphone', _clientPhoneController.text.isEmpty ? 'Non défini' : _clientPhoneController.text),
      if (_clientEmailController.text.isNotEmpty)
        _buildInfoRow('Email', _clientEmailController.text),
      if (_clientAddressController.text.isNotEmpty)
        _buildInfoRow('Adresse', _clientAddressController.text),
    ];
  }

  List<Widget> _buildClientEditingFields() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _clientFirstNameController,
              decoration: InputDecoration(
                labelText: 'Prénom *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _clientLastNameController,
              decoration: InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _clientPhoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          labelText: 'Téléphone *',
          prefixIcon: const Icon(Icons.phone, color: Color(0xFF7717E8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _clientEmailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Email',
          prefixIcon: const Icon(Icons.email, color: Color(0xFF7717E8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _clientAddressController,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: 'Adresse',
          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF7717E8)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ];
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7717E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
