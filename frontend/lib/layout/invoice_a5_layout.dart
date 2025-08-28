import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/sale/invoice_actions.dart';
import '../../utiles/store_helper.dart';
import '../services/invoice_service.dart';

class InvoiceA5Layout extends StatefulWidget {
  final Map<String, dynamic> facture;
  final bool showAppBar;
  final bool isCentered;
  final bool showSaleActions;

  const InvoiceA5Layout({
    Key? key,
    required this.facture,
    this.showAppBar = true,
    this.isCentered = true,
    this.showSaleActions = true,
  }) : super(key: key);

  @override
  State<InvoiceA5Layout> createState() => _InvoiceA5LayoutState();
}

class _InvoiceA5LayoutState extends State<InvoiceA5Layout> {
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
    debugPrint('[A5][parseNum] value=$value type=${value.runtimeType}');
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  String _getField(dynamic obj, String field, {String fallback = ''}) {
    if (obj is Map && obj[field] != null) return obj[field].toString();
    if (obj is String) return obj;
    return fallback;
  }

  Widget _buildInvoiceContent(BuildContext context, String? storeId) {
    debugPrint('[A5] facture: $_facture');
    
    // --- Affichage client ---
    final client = _facture['client'];
    final clientNom = client is Map
        ? '${_getField(client, 'firstName')} ${_getField(client, 'lastName')}'
        : client?.toString() ?? 'ID inconnu';
    final clientAdresse = client is Map ? _getField(client, 'address') : '';
    final clientPhone = client is Map ? _getField(client, 'phone') : '';
    
    // --- Affichage magasin ---
    final store = _facture['store'];
    final storeNom = store is Map
        ? _getField(store, 'name')
        : store?.toString() ?? 'ID inconnu';
    final storeNif = store is Map ? _getField(store, 'nif') : '';
    final storeRccm = store is Map ? _getField(store, 'rccm') : '';
    final storeAdresse = store is Map ? _getField(store, 'address') : '';
    final storeLogo = store is Map ? _getField(store, 'logoUrl') : null;
    
    // --- Affichage user ---
    final user = _facture['user'];
    final caissier = user is Map
        ? _getField(user, 'username')
        : user?.toString() ?? 'ID inconnu';
    
    final linesRaw = _facture['lines'] ?? [];
    final lines = List<Map<String, dynamic>>.from(linesRaw);
    final total = _parseNum(_facture['total']);
    final totalInWords = _facture['totalInWords'] ?? '';
    final number = _facture['number'] ?? '';
    final date = _facture['date'] != null
        ? DateTime.tryParse(_facture['date'])
        : null;
    final montantPaye = _parseNum(_facture['montantPaye']);
    final resteAPayer = total - montantPaye;
    final modePaiement = _facture['modePaiement'] ?? 'Espèces';

    Widget invoiceContainer = Container(
      width: 595,
      height: 842,
      margin: widget.isCentered ? const EdgeInsets.symmetric(vertical: 24) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: widget.isCentered ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // === EN-TÊTE : Logo + Infos Magasin ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Icône du magasin à gauche
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF7717E8).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.store,
                      size: 32,
                      color: Color(0xFF7717E8),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'LOGO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7717E8),
                      ),
                    ),
                    Text(
                      'MAGASIN',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF7717E8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Informations du magasin à droite du logo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ETS SADISSOU ET FILS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7717E8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'NIF : 122524/R',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RCCM : ABCDE125-45',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ADRESSE : 17 Porte',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tel : 96521292/96970680',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // === SÉPARATEUR ===
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          
          // === SECTION FACTURÉ À + NUMÉRO/DATE ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Facturé à (gauche)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FACTURÉ À :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clientNom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (clientAdresse.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        clientAdresse,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (clientPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tél: $clientPhone',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Numéro et date (droite)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Facture N° : $number',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Date : ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // === SÉPARATEUR ===
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 18),
          
          // === TABLEAU PRODUITS ===
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.5),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.3),
                },
                border: const TableBorder.symmetric(
                  inside: BorderSide(color: Color(0xFFF3F0FA)),
                ),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F0FA),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Désignation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Qté',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'P.U.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...lines.map(
                    (line) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            line['productName'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            '${_parseNum(line['quantity'])}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            '${_parseNum(line['unitPrice']).toStringAsFixed(0)} F',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          child: Text(
                            '${_parseNum(line['totalLine']).toStringAsFixed(0)} F',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // === SÉPARATEUR ===
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 12),
          
          // === TOTAL PRINCIPAL ===
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'TOTAL : ${total.toStringAsFixed(0)} F',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF7717E8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // === RESTE À PAYER + MONTANT PAYÉ ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reste à payer : ${resteAPayer.toStringAsFixed(0)} F',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              Text(
                'Montant Payé : ${montantPaye.toStringAsFixed(0)} F',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF43A047),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // === TOTAL EN LETTRES ===
          Text(
            'Total en lettres : $totalInWords',
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          
          // === SÉPARATEUR ===
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 12),
          
          // === CAISSIER + MODE DE PAIEMENT ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caissier : $caissier',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'Mode de paiement : $modePaiement',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // === MENTIONS LÉGALES ===
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Termes de paiement : Payable immédiatement.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 4),
              Text(
                'Merci de votre confiance !',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // === ACTIONS ===
          if (widget.showSaleActions)
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                return InvoiceActions(
                  facture: _facture,
                  onReload: _reloadFacture,
                  cartProvider: cartProvider,
                  isMobile: false,
                  storeId: storeId,
                );
              },
            ),
        ],
      ),
    );

    if (widget.isCentered) {
      return Center(child: invoiceContainer);
    }
    return invoiceContainer;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: getSelectedStoreId(context: context),
      builder: (context, snapshot) {
        final storeId = snapshot.data;
        if (widget.showAppBar) {
          return Scaffold(
            backgroundColor: Colors.grey[100],
            appBar: AppBar(
              backgroundColor: const Color(0xFF7717E8),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Aperçu Facture (A5)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            body: _buildInvoiceContent(context, storeId),
          );
        }
        return _buildInvoiceContent(context, storeId);
      },
    );
  }
}