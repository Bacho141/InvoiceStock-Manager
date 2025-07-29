import 'package:flutter/material.dart';

class StockHistoryCard extends StatelessWidget {
  final String type;
  final String date;
  final String quantite;
  final String utilisateur;
  final String raison;
  final String stockResultant;
  const StockHistoryCard({
    required this.type,
    required this.date,
    required this.quantite,
    required this.utilisateur,
    required this.raison,
    required this.stockResultant,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case 'entrée':
        icon = Icons.arrow_upward;
        color = Colors.green;
        break;
      case 'sortie':
        icon = Icons.arrow_downward;
        color = Colors.red;
        break;
      case 'correction':
        icon = Icons.edit;
        color = Colors.orange;
        break;
      default:
        icon = Icons.swap_horiz;
        color = Colors.blueGrey;
    }
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text('$type  $quantite', style: TextStyle(color: color)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Le $date'),
            Text('Stock: $stockResultant'),
            Text('Par: $utilisateur'),
            Text('Raison: $raison'),
          ],
        ),
      ),
    );
  }
}
