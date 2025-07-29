import 'package:flutter/material.dart';
import '../../../controllers/cart_controller.dart';

class CartMobile extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  CartMobile({Key? key, required this.onBack, required this.onNext})
    : super(key: key);
  final cart = CartController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Material(
              elevation: 3,
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.only(
                  left: 4,
                  right: 12,
                  top: 2,
                  bottom: 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF7717E8),
                            size: 22,
                          ),
                          onPressed: onBack,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.shopping_basket_outlined,
                          color: Color(0xFF7717E8),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Panier',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Container(
                          height: 3,
                          width: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7717E8),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7717E8,
                                ).withOpacity(0.18),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: AnimatedBuilder(
          animation: cart,
          builder: (context, _) {
            final items = cart.items;
            final subtotal = cart.subtotal;
            final totalDiscount = cart.totalDiscount;
            final total = cart.total;
            return ListView.separated(
              itemCount: items.length + 2, // produits + totaux + bouton
              separatorBuilder: (_, i) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                if (index < items.length) {
                  final item = items[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF7717E8,
                          ).withOpacity(0.10),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Color(0xFF7717E8),
                          ),
                        ),
                        title: Text(
                          item.product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${item.product.sellingPrice.toStringAsFixed(0)} F',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Color(0xFF7717E8),
                              ),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  cart.updateQuantity(
                                    item.product.id ?? '',
                                    item.quantity - 1,
                                  );
                                }
                              },
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFF7717E8),
                              ),
                              onPressed: () {
                                cart.updateQuantity(
                                  item.product.id ?? '',
                                  item.quantity + 1,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                cart.removeProduct(item.product.id ?? '');
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (index == items.length) {
                  // Section totaux
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 10, top: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FA),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Sous-total: ${subtotal.toStringAsFixed(0)} F',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Remise totale: ${totalDiscount.toStringAsFixed(0)} F',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Divider(),
                        Text(
                          'TOTAL: ${total.toStringAsFixed(0)} F',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF7717E8),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Bouton principal
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onNext,
                          icon: const Icon(Icons.payment, color: Colors.white),
                          label: const Text(
                            'Procéder au paiement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7717E8),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18), // Espace en bas
                    ],
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
