import 'package:flutter/material.dart';
import '../layout/main_layout.dart';
import 'product/product_desktop_view.dart';
import 'product/product_mobile_view.dart';
import 'product/product_tablet_view.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  Widget build(BuildContext context) {
    debugPrint('[SCREEN][ProductsScreen] Construction de l\'écran produits');

    return MainLayout(
      currentRoute: '/products',
      pageTitle: 'Catalogue Produits',
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1024) {
            return const ProductDesktopView();
          } else if (constraints.maxWidth > 600) {
            return const ProductTabletView();
          } else {
            return const ProductMobileView();
          }
        },
      ),
    );
  }
}
