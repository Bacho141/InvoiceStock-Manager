import 'package:flutter/material.dart';

class PaymentDialog extends StatefulWidget {
  final double initialAmount;

  const PaymentDialog({Key? key, required this.initialAmount}) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  String _paymentMethod = 'espece';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.initialAmount.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enregistrer un paiement'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'F',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un montant';
                }
                if (double.tryParse(value) == null) {
                  return 'Veuillez entrer un montant valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Méthode de paiement',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'espece',
                  child: Text('Espèce'),
                ),
                DropdownMenuItem(
                  value: 'carte',
                  child: Text('Carte de crédit'),
                ),
                DropdownMenuItem(
                  value: 'mobile',
                  child: Text('Paiement mobile'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _paymentMethod = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final result = {
                'amount': double.parse(_amountController.text),
                'method': _paymentMethod,
              };
              Navigator.of(context).pop(result);
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}