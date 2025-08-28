import 'package:flutter/material.dart';
import '../../../models/invoice.dart';
import './invoice_detail_widget.dart';
import './custom_detail_header.dart';

class DesktopDetailLayout extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onInvoiceUpdated;

  const DesktopDetailLayout({Key? key, required this.invoice, required this.onInvoiceUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomDetailHeader(invoice: invoice, onInvoiceUpdated: onInvoiceUpdated),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: InvoiceDetailWidget(invoice: invoice, onInvoiceUpdated: onInvoiceUpdated),
          ),
        ),
      ],
    );
  }
}
