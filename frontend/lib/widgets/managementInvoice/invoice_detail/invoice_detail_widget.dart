import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './payment_dialog.dart';
import '../../../models/invoice.dart';
import '../../../services/invoice_service.dart';
import '../../../layout/invoice_a5_layout.dart'; // Import the layout
import '../invoice_common/invoice_status_badge.dart';
import '../payment/payment_history_safe.dart';
import '../mobile/mobile_detail_layout.dart';

class InvoiceDetailWidget extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onInvoiceUpdated;

  const InvoiceDetailWidget({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _DesktopDetailView(
            invoice: invoice,
            onInvoiceUpdated: onInvoiceUpdated,
          );
        } else {
          return _MobileDetailContent(
            invoice: invoice,
            onInvoiceUpdated: onInvoiceUpdated,
          );
        }
      },
    );
  }
}

// ================== Desktop Layout ==================
class _DesktopDetailView extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onInvoiceUpdated;

  const _DesktopDetailView({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: InvoiceA5Layout(
                  facture: invoice.toJson(),
                  showAppBar: false,
                  isCentered: false,
                  showSaleActions: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  PaymentHistoryWidget(
                    invoice: invoice,
                    onPaymentUpdated: onInvoiceUpdated,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd/MM/yyyy').format(invoice.date);
    final remainingAmount = invoice.total - invoice.montantPaye;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations Générales', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _infoRow(
              'Client:',
              invoice.client.fullName.isNotEmpty
                  ? invoice.client.fullName
                  : 'N/A',
            ),
            _infoRow('Date d\'émission:', formattedDate),
            _infoRow(
              'Statut:',
              '',
              widget: InvoiceStatusBadge(status: invoice.status),
            ),
            const Divider(height: 32),
            _infoRow(
              'Total TTC:',
              '${invoice.total.toStringAsFixed(2)} F',
              isAmount: true,
              isBold: true,
            ),
            _infoRow(
              'Remise:',
              '- ${invoice.discountTotal.toStringAsFixed(2)} F',
              isAmount: true,
              color: Colors.green[700],
            ),
            _infoRow(
              'Montant Payé:',
              '${invoice.montantPaye.toStringAsFixed(2)} F',
              isAmount: true,
            ),
            _infoRow(
              'Reste à Payer:',
              '${remainingAmount.toStringAsFixed(2)} F',
              isAmount: true,
              isBold: true,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
    bool isAmount = false,
    Widget? widget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          widget ??
              Text(
                value,
                textAlign: isAmount ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: 16,
                ),
              ),
        ],
      ),
    );
  }
}

// ================== Mobile Content ==================
class _MobileDetailContent extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onInvoiceUpdated;

  const _MobileDetailContent({
    Key? key,
    required this.invoice,
    required this.onInvoiceUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Afficher seulement les détails sans TabBar pour éviter la duplication
    // Le TabBar est géré par MobileDetailLayout
    return _buildDetailsTab(context);
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('dd/MM/yyyy').format(invoice.date);
    final remainingAmount = invoice.total - invoice.montantPaye;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client: ${invoice.client.fullName.isNotEmpty ? invoice.client.fullName : 'N/A'}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Date: $formattedDate', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Statut: '),
              InvoiceStatusBadge(status: invoice.status),
            ],
          ),
          const Divider(height: 32),
          _buildMobileInfoRow(
            'Total TTC:',
            '${invoice.total.toStringAsFixed(2)} F',
            theme,
          ),
          _buildMobileInfoRow(
            'Remise:',
            '- ${invoice.discountTotal.toStringAsFixed(2)} F',
            theme,
            color: Colors.green[700],
          ),
          _buildMobileInfoRow(
            'Montant Payé:',
            '${invoice.montantPaye.toStringAsFixed(2)} F',
            theme,
          ),
          _buildMobileInfoRow(
            'Reste à Payer:',
            '${remainingAmount.toStringAsFixed(2)} F',
            theme,
            isBold: true,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      child: InvoiceA5Layout(
        facture: invoice.toJson(),
        showAppBar: false,
        isCentered: false,
        showSaleActions: false,
      ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: PaymentHistoryWidget(
        invoice: invoice,
        onPaymentUpdated: onInvoiceUpdated,
      ),
    );
  }
}
