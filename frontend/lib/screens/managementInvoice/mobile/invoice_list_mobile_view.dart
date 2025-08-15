import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../widgets/managementInvoice/mobile/invoice_card_mobile.dart';
// import '../../../widgets/managementInvoice/period_filter_dialog.dart';

class InvoiceListMobileView extends StatelessWidget {
  final InvoiceProvider provider;

  const InvoiceListMobileView({Key? key, required this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildContent(context, provider);
  }


  Widget _buildContent(BuildContext context, InvoiceProvider provider) {
    if (provider.isLoading && provider.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    if (provider.invoices.isEmpty) {
      return const Center(child: Text('Aucune facture trouvée.'));
    }

    return ListView.builder(
      itemCount: provider.invoices.length,
      itemBuilder: (context, index) {
        final invoice = provider.invoices[index];
        return InvoiceCardMobile(invoice: invoice);
      },
    );
  }
}
