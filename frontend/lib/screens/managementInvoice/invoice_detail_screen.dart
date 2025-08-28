
import 'package:flutter/material.dart';
import '../../models/invoice.dart';
import '../../services/invoice_service.dart';
import '../../widgets/managementInvoice/invoice_detail/desktop_detail_layout.dart';
import '../../widgets/managementInvoice/mobile/mobile_detail_layout.dart';
import '../../layout/main_layout.dart';


class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({Key? key, required this.invoiceId}) : super(key: key);

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late Future<Invoice> _invoiceFuture;
  final InvoiceService _invoiceService = InvoiceService();

  @override
  void initState() {
    super.initState();
    _invoiceFuture = _fetchInvoiceDetails();
  }

  Future<Invoice> _fetchInvoiceDetails() async {
    try {
      final responseData = await _invoiceService.getInvoiceById(widget.invoiceId);
      if (responseData.containsKey('data')) {
        return Invoice.fromJson(responseData['data']);
      } else {
        throw Exception('JSON response does not contain a \'data\' key.');
      }
    } catch (e) {
      throw Exception('Failed to load invoice details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentRoute: '/invoices',
      pageTitle: 'Détail de la Facture', // The title in MainLayout might not be visible depending on its internal logic
      showStoreSelector: false, // Hide the store selector as requested
      child: FutureBuilder<Invoice>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            );
          }
          if (snapshot.hasData) {
            final invoice = snapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return DesktopDetailLayout(invoice: invoice, onInvoiceUpdated: () {
                    setState(() {
                      _invoiceFuture = _fetchInvoiceDetails();
                    });
                  });
                } else {
                  return MobileDetailLayout(invoice: invoice, onInvoiceUpdated: () {
                    setState(() {
                      _invoiceFuture = _fetchInvoiceDetails();
                    });
                  });
                }
              },
            );
          }
          return const Center(child: Text('Aucune donnée de facture disponible.'));
        },
      ),
    );
  }
}



