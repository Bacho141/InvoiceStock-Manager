// screens/invoices/invoice_list_screen.dart (NOUVEAU - SIMPLIFIÉ)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/invoice_provider.dart';
import '../../services/invoice_service.dart';
import '../../layout/main_layout.dart';

// Widgets refactorisés
import '../../widgets/managementInvoice/invoice_filters/invoice_filters.dart';
import '../../widgets/managementInvoice/invoice_content/invoice_content_widget.dart';
import './mobile/invoice_list_mobile_view.dart';

class InvoicesListScreen extends StatelessWidget {
  const InvoicesListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceProvider(InvoiceService()),
      child: Consumer<InvoiceProvider>(
        builder: (context, provider, child) {
          return MainLayout(
            currentRoute: '/invoices',
            pageTitle: '📄 Gestion des Factures',
            child: LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth > 800
                    ? _DesktopLayout(provider: provider)
                    : _MobileLayout(provider: provider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final InvoiceProvider provider;

  const _DesktopLayout({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopFilterBar(provider: provider),
        const SizedBox(height: 16),
        Expanded(
          child: InvoiceContentWidget(provider: provider),
        ),
      ],
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final InvoiceProvider provider;

  const _MobileLayout({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _buildMobileFilterBar(context, provider),
        const SizedBox(height: 8),
        Expanded(
          child: InvoiceListMobileView(provider: provider),
        ),
      ],
    );
  }

  Widget _buildMobileFilterBar(BuildContext context, InvoiceProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SearchTextField(
              onChanged: (value) => provider.setSearchTerm(value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showMobileFilterModal(context, provider),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
    );
  }

  void _showMobileFilterModal(BuildContext context, InvoiceProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: MobileFilterModal(provider: provider),
        );
      },
    );
  }
}