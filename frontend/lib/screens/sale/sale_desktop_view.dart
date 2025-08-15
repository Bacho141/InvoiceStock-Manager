import 'package:flutter/material.dart';
import '../../widgets/sale/catalog_panel.dart';
import '../../widgets/sale/cart_panel.dart';
import '../../widgets/sale/client_payment_panel.dart';
import '../../widgets/sale/sale_action_bar.dart';
import '../../models/store.dart';

class SaleDesktopView extends StatelessWidget {
  final Store? currentStore;

  const SaleDesktopView({Key? key, this.currentStore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final selectedStoreId = currentStore?.id;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth < 1100;
              if (isTablet) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(
                      height: 320,
                      child: CatalogPanel(key: ValueKey<String?>(selectedStoreId), storeId: selectedStoreId),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: CartPanel(storeId: selectedStoreId),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: ClientPaymentPanel(
                        isTablet: true,
                        storeId: selectedStoreId,
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: CatalogPanel(key: ValueKey<String?>(selectedStoreId), storeId: selectedStoreId),
                    ),
                    VerticalDivider(width: 1),
                    Expanded(
                      flex: 4,
                      child: CartPanel(storeId: selectedStoreId),
                    ),
                    VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: ClientPaymentPanel(storeId: selectedStoreId),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        SaleActionBar(storeId: selectedStoreId),
      ],
    );
  }
}
