import 'package:flutter/foundation.dart';
import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  double? discount; // remise en valeur, optionnelle

  CartItem({required this.product, this.quantity = 1, this.discount});

  double get total => (product.sellingPrice * quantity) - (discount ?? 0);
}
