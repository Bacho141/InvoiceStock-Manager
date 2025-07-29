import 'package:flutter/material.dart';
import 'sale/sale_desktop_view.dart';
import 'sale/sale_mobile_view.dart';
import '../layout/main_layout.dart';

class NewSaleScreen extends StatelessWidget {
  const NewSaleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    Widget content;
    if (width < 700) {
      // Mobile
      content = const SaleMobileView();
    } else {
      // Tablette ou desktop
      content = const SaleDesktopView();
    }
    return MainLayout(
      currentRoute: '/new-sale',
      pageTitle: '🛒 Vente',
      child: content,
    );
  }
}
