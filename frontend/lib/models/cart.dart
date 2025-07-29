import 'cart_item.dart';
import 'user.dart';

class Cart {
  final List<CartItem> items;
  User? client;

  Cart({List<CartItem>? items, this.client}) : items = items ?? [];

  double get subtotal => items.fold(
    0,
    (sum, item) => sum + (item.product.sellingPrice * item.quantity),
  );
  double get totalDiscount =>
      items.fold(0, (sum, item) => sum + (item.discount ?? 0));
  double get total => subtotal - totalDiscount;

  void clear() {
    items.clear();
    client = null;
  }
}
