import 'package:flutter/material.dart';

class StockActions extends StatelessWidget {
  final VoidCallback? onAjustement;
  final VoidCallback? onExport;
  const StockActions({Key? key, this.onAjustement, this.onExport})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: onAjustement ?? () {},
          icon: Icon(Icons.edit),
          label: Text('Nouvel Ajustement'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onExport ?? () {},
          icon: Icon(Icons.download),
          label: Text('Export'),
        ),
      ],
    );
  }
}
