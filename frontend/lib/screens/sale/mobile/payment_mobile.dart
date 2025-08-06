import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controllers/cart_controller.dart';
import '../../../layout/invoice_pos_mobile_layout.dart';
import '../../../services/client_service.dart';
import '../../../services/invoice_service.dart';
import '../../../utiles/number_to_words_fr.dart';
import '../../../widgets/sale/add_client_modal.dart';
import '../receipt_format_selector.dart';
import 'invoice_a5_mobile_preview.dart';

class PaymentMobile extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onAddClient;
  const PaymentMobile({
    Key? key,
    required this.onBack,
    required this.onAddClient,
  }) : super(key: key);

  @override
  State<PaymentMobile> createState() => _PaymentMobileState();
}

class _PaymentMobileState extends State<PaymentMobile> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = 'especes';
  final ClientService _clientService = ClientService();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<Map<String, dynamic>> _clients = [];
  String? _selectedClientId;
  bool _loadingClients = false;

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    setState(() => _loadingClients = true);
    try {
      final data = await _clientService.getClients();
      if (!mounted) return;
      setState(() {
        _clients = data;
        _selectedClientId = _clients.isNotEmpty ? _clients.first['_id'] : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _clients = []);
    } finally {
      if (!mounted) return;
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
            if (!mounted) return;
            Navigator.of(context).pop();
            await _fetchClients();
            setState(() {
              _selectedClientId = client['data']['_id'];
            });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Client créé avec succès')),
            );
          } catch (e) {
            if (!mounted) return;
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
    final cart = CartController();
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Material(
              elevation: 3,
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 12,
                  top: 2,
                  bottom: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF7717E8),
                            size: 22,
                          ),
                          onPressed: widget.onBack,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.payments_outlined,
                          color: Color(0xFF7717E8),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Client & Paiement',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Container(
                          height: 3,
                          width: 34,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: cart,
            builder: (context, _) {
              final total = cart.total;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        // Section client
                        const Text(
                          'Client',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF3F0FA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _loadingClients
                                    ? const Center(child: CircularProgressIndicator())
                                    : DropdownButtonFormField<String>(
                                        value: _selectedClientId,
                                        items: _clients
                                            .map<DropdownMenuItem<String>>(
                                              (c) => DropdownMenuItem<String>(
                                                value: c['_id'] as String,
                                                child: Text(
                                                  ((c['firstName'] ?? '') +
                                                          ' ' +
                                                          (c['lastName'] ?? ''))
                                                      .trim(),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _selectedClientId = v),
                                        decoration: const InputDecoration(
                                          labelText: 'Sélectionner un client',
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 12,
                                          ),
                                          filled: true,
                                          fillColor: Color(0xFFF7F7FA),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _showAddClientModal,
                                icon: const Icon(
                                  Icons.person_add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Ajouter',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7717E8),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Section total de la facture
                        const SizedBox(height: 8),
                        const Text(
                          'Total de la facture',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF3F0FA)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Montant à payer',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(0)} F',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF7717E8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Section montant payé
                        const Text(
                          'Montant payé',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Montant payé',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF7F7FA),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 22),
                        // Section méthode de paiement
                        const Text(
                          'Méthode de paiement',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFF3F0FA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedMethod,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'especes',
                                      child: Text('Espèces'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'carte',
                                      child: Text('Carte'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _selectedMethod = v!),
                                  decoration: const InputDecoration(
                                    labelText: 'Sélectionner une méthode de paiement',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFF7F7FA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final currentUserId = prefs.getString('user_id');
                            final selectedStoreId = prefs.getString('selected_store_id');
                            debugPrint('[PAYMENT_MOBILE] LECTURE DEPUIS PREFS: selected_store_id = $selectedStoreId');
                            if (selectedStoreId == null || selectedStoreId == 'all') {
                              debugPrint('[UI] Erreur : Aucun magasin valide sélectionné');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Aucun magasin valide sélectionné. Veuillez sélectionner un magasin.',
                                  ),
                                ),
                              );
                              return;
                            }
                            final amountPaid = double.tryParse(_amountController.text) ?? 0;
                            if (_selectedClientId == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez sélectionner un client.'),
                                ),
                              );
                              return;
                            }
                            if (currentUserId == null) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Utilisateur ou magasin non trouvé.'),
                                ),
                              );
                              return;
                            }
                            final payload = {
                              "client": _selectedClientId,
                              "store": selectedStoreId,
                              "user": currentUserId,
                              "lines": cart.items.map((item) => {
                                "product": item.product.id,
                                "productName": item.product.name,
                                "quantity": item.quantity,
                                "unitPrice": item.product.sellingPrice,
                                "discount": item.discount ?? 0,
                                "totalLine": item.total,
                              }).toList(),
                              "total": cart.total,
                              "totalInWords": numberToWordsFr(cart.total.toInt()),
                              "discountTotal": cart.totalDiscount,
                              "status": amountPaid >= cart.total ? "payee" : "reste_a_payer",
                              "format": "A5", // Le format sera choisi après
                              "montantPaye": amountPaid,
                            };
                            try {
  final response = await InvoiceService().createInvoice(payload);
  final newFacture = response['data'];

  if (!mounted) return;

  try {
    // Appel de validation transactionnelle (stock, statut, etc.)
    final selectedStoreId = prefs.getString('selected_store_id');
    debugPrint('[PAYMENT_MOBILE] Préparation de la validation. Facture ID: ${newFacture['_id']}, Store ID: $selectedStoreId');
    if (selectedStoreId == null || selectedStoreId == 'all') {
        debugPrint('[PAYMENT_MOBILE] ERREUR: Tentative de validation avec un storeId invalide.');
        throw Exception('Tentative de validation avec un storeId invalide.');
    }
    await InvoiceService().validateInvoice(newFacture['_id'] ?? newFacture['id'], selectedStoreId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Facture créée et validée avec succès !'),
        duration: Duration(seconds: 1),
      ),
    );
    cart.clear();

    // Afficher le sélecteur de format
    final format = await showReceiptFormatSelector(context: context);

    if (format == null) return; // L'utilisateur a fermé la modale

    if (!mounted) return;

    // Naviguer vers l'aperçu correspondant
    if (format == ReceiptFormat.a5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoiceA5MobilePreview(facture: newFacture),
        ),
      );
    } else if (format == ReceiptFormat.pos) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InvoicePOSMobileLayout(facture: newFacture),
        ),
      );
    }
  } catch (e) {
    if (!mounted) return;
    // Ici, la facture a été créée mais la validation (stock, transaction) a échoué : rollback effectué côté backend
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur validation facture : $e'),
        duration: const Duration(seconds: 4),
      ),
    );
    // Ne pas vider le panier, ne pas afficher le reçu
    return;
  }
} catch (e) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur création facture : $e'),
    ),
  );
}
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                            minimumSize: const Size(double.infinity, 50), // Hauteur minimale fixe
                          ),
                          icon: const Icon(Icons.check_circle, color: Colors.white),
                          label: const Text(
                            'Valider la facture',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}