import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../../utiles/api_urls.dart';
import '../../services/invoice_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/sale/invoice_actions.dart';

class InvoicePOSLayout extends StatefulWidget {
  final Map<String, dynamic> facture;
  const InvoicePOSLayout({Key? key, required this.facture}) : super(key: key);

  @override
  State<InvoicePOSLayout> createState() => _InvoicePOSLayoutState();
}

class _InvoicePOSLayoutState extends State<InvoicePOSLayout> {
  late Map<String, dynamic> _facture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _facture = widget.facture;
  }

  Future<void> _reloadFacture() async {
    debugPrint('[POS][RELOAD] Facture avant rechargement: \n$_facture');
    setState(() {
      _loading = true;
    });
    try {
      debugPrint('[POS][RELOAD] Rechargement facture...');
      final data = await InvoiceService().getInvoiceById(
        _facture['_id'] ?? _facture['id'],
      );
      setState(() {
        _facture = data['data'];
        _loading = false;
      });
      debugPrint('[POS][RELOAD] Facture après rechargement: \n$_facture');
      debugPrint('[POS][RELOAD] Facture rechargée');
    } catch (e) {
      debugPrint('[POS][RELOAD][ERREUR] $e');
      setState(() {
        _loading = false;
      });
    }
  }

  num _parseNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  String _padRight(String s, int width) =>
      s.padRight(width).substring(0, width);

  @override
  Widget build(BuildContext context) {
    final facture = _facture;
    final client = facture['client'];
    final clientNom = client is Map
        ? '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'
        : client?.toString() ?? 'ID inconnu';
    final user = facture['user'];
    final caissier = user is Map
        ? (user['username'] ?? '')
        : user?.toString() ?? '';
    final lines = List<Map<String, dynamic>>.from(facture['lines'] ?? []);
    final total = _parseNum(facture['total']);
    final montantPaye = _parseNum(facture['montantPaye']);
    final resteAPayer = total - montantPaye;
    final discountTotal = _parseNum(facture['discountTotal']);
    final totalInWords = facture['totalInWords'] ?? '';
    final number = facture['number'] ?? '';
    final date = facture['date'] != null
        ? DateTime.tryParse(facture['date'])
        : null;
    final modePaiement = facture['modePaiement'] ?? 'Espèces';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7717E8),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ticket POS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 380, // 80mm à 300dpi ≈ 945px, mais 380px pour écran
          margin: const EdgeInsets.symmetric(vertical: 18),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              const Text(
                '=======================================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                '       =======================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const Text(
                '        ETS SAdISSOU ET FILS ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF7717E8),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'NIF : ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '122524/P',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ADRESSE : ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '17 Porte',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tél : ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '96521292/96970680',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ],
              ),
              const Text(
                '       =======================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const Text(
                '=======================================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date :',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    date != null
                        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                        : '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Reçu N° :',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$number',
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
                  Text(
                    'Caissier :',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$caissier',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Client :',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      '$clientNom',
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
              // Tableau produits avec lignes verticales
              Container(
                width: double.infinity,
                child: Column(
                  children: [
                    // En-tête colonnes avec séparateurs
                    Row(
                      children: const [
                        Text(
                          '|',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
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
                        Text(
                          '|',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'PU',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '|',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            'Qté',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '|',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            'Mt',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '|',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Ligne horizontale alignée
                    Row(
                      children: [
                        for (int i = 0; i < 8; i++)
                          Expanded(
                            child: Container(
                              height: 1.2,
                              color: Color(0xFFBDBDBD),
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                            ),
                          ),
                      ],
                    ),
                    // Lignes produits
                    ...lines.map((line) {
                      final name = line['productName'] ?? '';
                      final qte = _parseNum(line['quantity']);
                      final pu = _parseNum(line['unitPrice']);
                      final mt = _parseNum(line['totalLine']);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '|',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${pu.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${qte.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${mt.toStringAsFixed(0)} F',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            '|',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              // Ligne horizontale alignée sous le tableau
              Row(
                children: [
                  for (int i = 0; i < 8; i++)
                    Expanded(
                      child: Container(
                        height: 1.2,
                        color: Color(0xFFBDBDBD),
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                      ),
                    ),
                ],
              ),
              // Totaux
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SOUS-TOTAL :',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'REMISE :',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${discountTotal.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL :',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MONTANT PAYÉ :',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${montantPaye.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RESTE À PAYER :',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${resteAPayer.toStringAsFixed(0)} F',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Arrêté la présente facture à la somme de : $totalInWords',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const Text(
                '=======================================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                '     Merci de votre confiance !',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const Text(
                '=======================================',
                style: TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Boutons action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
