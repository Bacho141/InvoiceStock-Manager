import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/invoice_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/sale/invoice_actions.dart';

class InvoicePOSMobileLayout extends StatefulWidget {
  final Map<String, dynamic> facture;

  const InvoicePOSMobileLayout({Key? key, required this.facture})
    : super(key: key);

  @override
  State<InvoicePOSMobileLayout> createState() => _InvoicePOSMobileLayoutState();
}

class _InvoicePOSMobileLayoutState extends State<InvoicePOSMobileLayout> {
  late Map<String, dynamic> _facture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _facture = widget.facture;
  }

  Future<void> _reloadFacture() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await InvoiceService().getInvoiceById(_facture['_id']);
      if (mounted) {
        setState(() {
          _facture = data['data'];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error reloading invoice: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildSeparator() {
    const String separator =
        '==================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================================';
    return const Text(
      separator,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = List<Map<String, dynamic>>.from(_facture['lines'] ?? []);
    final client = _facture['client'] ?? {};
    final user = _facture['user'] ?? {};

    final number = _facture['number']?.toString() ?? 'N/A';
    final clientNom = client['firstName'] != null && client['lastName'] != null
        ? '${client['firstName']} ${client['lastName']}'
        : 'Client au comptant';
    final caissier = user['name'] ?? 'Inconnu';
    final total = _parseNum(_facture['total']);
    final discountTotal = _parseNum(_facture['discountTotal']);
    final montantPaye = _parseNum(_facture['montantPaye']);
    final resteAPayer = total - montantPaye;
    final totalInWords = _facture['totalInWords'] ?? '';
    final date = _facture['date'] != null
        ? DateTime.tryParse(_facture['date'])
        : null;

    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    final dateFormat = date != null
        ? DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(date)
        : '';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reçu N° $number'),
        backgroundColor: const Color(0xFF7717E8),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reloadFacture,
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSeparator(),
                const Text(
                  'ETS SALLISSOU ET FILS',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF7717E8),
                  ),
                ),
                const Text(
                  'NIF : 12345/P',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                const Text(
                  'ADRESSE : 17 Porte',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                const Text(
                  'Tél : 96000000/97000000',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
                _buildSeparator(),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Date :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      dateFormat,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reçu N° :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      number,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Caissier :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      caissier,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Client :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        clientNom,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _buildSeparator(),
                // Table Header
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Désignation',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        'PU',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        'Qté',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Table Rows
                ...lines.map((line) {
                  final name = line['productName'] ?? '';
                  final qte = _parseNum(line['quantity']);
                  final pu = _parseNum(line['unitPrice']);
                  final mt = _parseNum(line['totalLine']);
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Text(
                          currencyFormat
                              .format(pu)
                              .replaceAll('FCFA', '')
                              .trim(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          qte.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          currencyFormat
                              .format(mt)
                              .replaceAll('FCFA', '')
                              .trim(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                _buildSeparator(),
                // Totals
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total HT :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormat.format(total),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Remise :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormat.format(discountTotal),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant Payé :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormat.format(montantPaye),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Reste à Payer :',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      currencyFormat.format(resteAPayer),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                _buildSeparator(),
                // Total in words
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Arrêté la présente facture à la somme de : $totalInWords',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                _buildSeparator(),
                const Text(
                  'MERCI DE VOTRE VISITE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF7717E8),
                  ),
                ),
                _buildSeparator(),
                const SizedBox(height: 12),
                // Action Buttons
                Consumer<CartProvider>(
                  builder: (context, cartProvider, _) {
                    return InvoiceActions(
                      facture: _facture,
                      onReload: _reloadFacture,
                      cartProvider: cartProvider,
                      isMobile: true,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
