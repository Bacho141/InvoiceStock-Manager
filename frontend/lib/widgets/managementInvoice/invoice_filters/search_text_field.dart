// widgets/invoice_filters/search_text_field.dart
import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? width;
  final bool isDense;

  const SearchTextField({
    Key? key,
    this.hintText = '🔍 Recherche...',
    this.onChanged,
    this.onSubmitted,
    this.width,
    this.isDense = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget textField = TextField(
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: isDense,
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: textField,
      );
    }

    return textField;
  }
}