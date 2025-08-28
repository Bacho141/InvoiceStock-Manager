// widgets/invoice_content/invoice_content_widget.dart
import 'package:flutter/material.dart';
import '../../../providers/invoice_provider.dart';
import '../invoice_states/invoice_states.dart';
import '../invoice_table/paginated_invoices_table.dart';
import './mobile/invoice_list_mobile_view.dart';

class InvoiceContentWidget extends StatelessWidget {
  final InvoiceProvider provider;

  const InvoiceContentWidget({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // État de chargement
    if (provider.isLoading && provider.invoices.isEmpty) {
      return const LoadingStateWidget();
    }

    // État d'erreur
    if (provider.error != null) {
      return ErrorStateWidget(
        error: provider.error!,
        onRetry: () => provider.loadInvoices(),
        onGetHelp: () {
          // TODO: Ouvrir support ou aide
        },
      );
    }

    // État vide
    if (provider.invoices.isEmpty) {
      return EmptyStateWidget(
        onCreateInvoice: () => Navigator.of(context).pushNamed('/new-sale'),
        onClearFilters: () => provider.clearFilters(),
      );
    }

    // Contenu avec données
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return PaginatedInvoicesTable(provider: provider);
        } else {
          return SimplifiedMobileInvoiceList(provider: provider);
        }
      },
    );
  }
}