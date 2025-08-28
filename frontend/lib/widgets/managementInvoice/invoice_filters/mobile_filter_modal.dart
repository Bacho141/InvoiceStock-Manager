// widgets/invoice_filters/mobile_filter_modal.dart
import 'package:flutter/material.dart';
import '../../../providers/invoice_provider.dart';
import 'status_dropdown_filter.dart';
import 'period_filter_button.dart';

class MobileFilterModal extends StatelessWidget {
  final InvoiceProvider provider;

  const MobileFilterModal({
    Key? key,
    required this.provider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filtres',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          StatusDropdownFilter(
            value: provider.statusFilter,
            onChanged: (value) => provider.setStatusFilter(value),
            isDense: false,
          ),
          const SizedBox(height: 16),
          PeriodFilterButton(provider: provider),
        ],
      ),
    );
  }
}