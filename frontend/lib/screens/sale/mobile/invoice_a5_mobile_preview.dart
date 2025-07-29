import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../widgets/sale/invoice_actions.dart';
import '../../../services/invoice_service.dart';

class InvoiceA5MobilePreview extends StatefulWidget {
  final Map<String, dynamic> facture;
  const InvoiceA5MobilePreview({Key? key, required this.facture})
    : super(key: key);

  @override
  State<InvoiceA5MobilePreview> createState() => _InvoiceA5MobilePreviewState();
}

class _InvoiceA5MobilePreviewState extends State<InvoiceA5MobilePreview> {
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

  @override
  Widget build(BuildContext context) {
    final client = _facture['client'];
    final clientNom = client is Map
        ? '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'
        : client?.toString() ?? 'ID inconnu';
    final clientAdresse = client is Map ? (client['address'] ?? '') : '';
    final clientPhone = client is Map ? (client['phone'] ?? '') : '';
    final user = _facture['user'];
    final caissier = user is Map
        ? (user['username'] ?? '')
        : user?.toString() ?? '';
    final lines = List<Map<String, dynamic>>.from(_facture['lines'] ?? []);
    final total = _parseNum(_facture['total']);
    final montantPaye = _parseNum(_facture['montantPaye']);
    final resteAPayer = total - montantPaye;
    final totalInWords = _facture['totalInWords'] ?? '';
    final number = _facture['number'] ?? '';
    final date = _facture['date'] != null
        ? DateTime.tryParse(_facture['date'])
        : null;
    final modePaiement = _facture['modePaiement'] ?? 'Espèces';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7717E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Aperçu Facture',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.receipt_long,
                          size: 28,
                          color: Color(0xFF7717E8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'ETS SALLISSOU ET FILS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7717E8),
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text('NIF : 12345/P', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 2),
                          Text(
                            'ADRESSE : 17 Porte',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Téléphone : 96000000/97000000',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[200], thickness: 1.2),
                const SizedBox(height: 10),
                // Infos client + numéro/date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FACTURÉ À :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(clientNom, style: const TextStyle(fontSize: 13)),
                          if (clientAdresse.isNotEmpty)
                            Text(
                              clientAdresse,
                              style: const TextStyle(fontSize: 12),
                            ),
                          if (clientPhone.isNotEmpty)
                            Text(
                              'Tél: $clientPhone',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Facture N° : $number',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (date != null)
                          Text(
                            'Date : ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[200], thickness: 1.2),
                const SizedBox(height: 10),
                // Tableau produits
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.3),
                  },
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xFFF3F0FA)),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF3F0FA)),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Désignation',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Qté',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'P.U.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...lines.map(
                      (line) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              line['productName'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${_parseNum(line['quantity'])}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${_parseNum(line['unitPrice']).toStringAsFixed(0)} F',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '${_parseNum(line['totalLine']).toStringAsFixed(0)} F',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[200], thickness: 1.2),
                const SizedBox(height: 8),
                // TOTAL en chiffre
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'TOTAL : ${total.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF7717E8),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Totaux
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reste à payer : ${resteAPayer.toStringAsFixed(0)} F',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Montant Payé : ${montantPaye.toStringAsFixed(0)} F',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43A047),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Total en lettres
                Text(
                  'Total en lettres : $totalInWords',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Caissier et mode de paiement
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Caissier : $caissier',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Mode de paiement : $modePaiement',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Mention finale
                const Text(
                  'Merci de votre confiance !',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                // Actions
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
