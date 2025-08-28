// widgets/invoice_filters/period_filter_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../managementInvoice/period_filter_dialog.dart';

class PeriodFilterButton extends StatelessWidget {
  final InvoiceProvider provider;
  final double? width;

  const PeriodFilterButton({
    Key? key,
    required this.provider,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget button = OutlinedButton.icon(
      onPressed: () => _showPeriodDialog(context),
      icon: const Icon(Icons.calendar_today),
      label: Text(provider.periodFilterText),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: const BorderSide(color: Colors.deepPurple),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }

  void _showPeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: const PeriodFilterDialog(),
        );
      },
    );
  }
}