import 'package:flutter/material.dart';
import '../custom_button.dart';
// import '../store_selector.dart'; // Retiré du header

class ProductHeader extends StatelessWidget {
  final VoidCallback onAddProduct;

  const ProductHeader({super.key, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 900;
    return Container(
      padding: EdgeInsets.all(isNarrow ? 10 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text(
                      'Catalogue Produits :',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomButton(
                    onPressed: onAddProduct,
                    text: '➕ Ajouter un produit',
                    icon: Icons.add,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                const Text(
                  'Catalogue Produits :',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const Spacer(),
                CustomButton(
                  onPressed: onAddProduct,
                  text: '➕ Ajouter un produit',
                  icon: Icons.add,
                ),
              ],
            ),
    );
  }
}
