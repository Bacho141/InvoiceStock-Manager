// widgets/invoice_filters/status_dropdown_filter.dart
import 'package:flutter/material.dart';

class StatusDropdownFilter extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String hint;
  final double? width;
  final bool isDense;

  static const Map<String, String> statusItems = {
    '': 'Tous',
    'payee': 'Payée',
    'reste_a_payer': 'Reste à payer',
    'en_attente': 'En attente',
    'annulee': 'Annulée',
  };

  const StatusDropdownFilter({
    Key? key,
    required this.value,
    required this.onChanged,
    this.hint = 'Statut',
    this.width,
    this.isDense = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget dropdown = DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: isDense,
      ),
      items: statusItems.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: dropdown,
      );
    }

    return dropdown;
  }
}