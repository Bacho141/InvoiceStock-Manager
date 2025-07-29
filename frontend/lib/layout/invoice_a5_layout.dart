import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/sale/invoice_actions.dart';
import '../services/invoice_service.dart';

class InvoiceA5Layout extends StatefulWidget {
  final Map<String, dynamic> facture;
  const InvoiceA5Layout({Key? key, required this.facture}) : super(key: key);

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

  // Utilitaire pour extraire une info d'un champ qui peut être un String (ID) ou un Map (objet)
  String _getField(dynamic obj, String field, {String fallback = ''}) {
    if (obj is Map && obj[field] != null) return obj[field].toString();
    if (obj is String) return obj; // ID
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
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
    debugPrint('[A5] lines raw: $linesRaw type=${linesRaw.runtimeType}');
    final lines = List<Map<String, dynamic>>.from(linesRaw);
    for (var i = 0; i < lines.length; i++) {
      debugPrint('[A5] line[$i]: ${lines[i]} type=${lines[i].runtimeType}');
    }
    final total = _parseNum(_facture['total']);
    debugPrint('[A5] total: $total type=${total.runtimeType}');
    final totalInWords = _facture['totalInWords'] ?? '';
    final number = _facture['number'] ?? '';
    final date = _facture['date'] != null
        ? DateTime.tryParse(_facture['date'])
        : null;
    final montantPaye = _parseNum(_facture['montantPaye']);
    debugPrint(
      '[A5] montantPaye: $montantPaye type=${montantPaye.runtimeType}',
    );
    final resteAPayer = total - montantPaye;
    debugPrint(
      '[A5] resteAPayer: $resteAPayer type=${resteAPayer.runtimeType}',
    );
    final modePaiement = _facture['modePaiement'] ?? 'Espèces';

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
      body: Center(
        child: Container(
          // Format A5 réel : 595x842 px (portrait)
          width: 595,
          height: 842,
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- En-tête : icône + infos magasin ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône à gauche
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Color(0xFF7717E8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Infos fixes magasin à droite (conformément à la doc)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ETS SADISSOU ET FILS',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7717E8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text('NIF : 122425/R', style: TextStyle(fontSize: 14)),
                        SizedBox(height: 2),
                        Text(
                          'ADRESSE : 17 Porte',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Téléphone : 96521292/96970680',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // --- Séparateur ---
              Container(height: 2, color: Colors.grey[200]),
              const SizedBox(height: 18),
              // --- Section client à gauche, numéro/date à droite ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos client à gauche
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FACTURÉ À :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(clientNom),
                        if (clientAdresse.isNotEmpty) Text(clientAdresse),
                        if (clientPhone.isNotEmpty) Text('Tél: $clientPhone'),
                      ],
                    ),
                  ),
                  // Numéro/date à droite
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Facture N° : $number',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (date != null)
                        Text(
                          'Date : ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // --- Séparateur ---
              Container(height: 2, color: Colors.grey[200]),
              const SizedBox(height: 18),
              // --- Tableau produits élargi ---
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.3),
                    },
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Color(0xFFF3F0FA)),
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3F0FA),
                        ),
                        children: const [
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
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                line['productName'] ?? '',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '${_parseNum(line['quantity'])}',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                '${_parseNum(line['unitPrice']).toStringAsFixed(0)} F',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
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
              // --- Séparateur ---
              Container(height: 2, color: Colors.grey[200]),
              const SizedBox(height: 8),
              // --- TOTAL en chiffre juste après le séparateur ---
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
              const SizedBox(height: 4),
              // --- Totaux et paiement ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reste à payer : ${resteAPayer.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Montant Payé : ${montantPaye.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF43A047),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // --- Total en lettres sous les totaux ---
              Text(
                'Total en lettres : $totalInWords',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              // --- Caissier et mode de paiement ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Caissier : $caissier'),
                  Text('Mode de paiement : $modePaiement'),
                ],
              ),
              const SizedBox(height: 8),
              // --- Mentions légales ---
              const Text('Merci de votre confiance !'),
              const SizedBox(height: 16),
              // --- Actions ---
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  return InvoiceActions(
                    facture: _facture,
                    onReload: _reloadFacture,
                    cartProvider: cartProvider,
                    isMobile: false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
