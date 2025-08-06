import 'package:flutter/material.dart';
import '../../widgets/sale/catalog_panel.dart';
import '../../widgets/sale/cart_panel.dart';
import '../../widgets/sale/client_payment_panel.dart';
import '../../widgets/sale/sale_action_bar.dart';
import '../../widgets/store_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/store.dart';

class SaleDesktopView extends StatefulWidget {
  const SaleDesktopView({Key? key}) : super(key: key);

  @override
  State<SaleDesktopView> createState() => _SaleDesktopViewState();
}

class _SaleDesktopViewState extends State<SaleDesktopView> {
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    // Load selected storeId from SharedPreferences if available
    _loadSelectedStoreId();
  }

  Future<void> _loadSelectedStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedStoreId = prefs.getString('selected_store_id');
    });
  }

  void _onStoreChanged(Store store) async {
    setState(() {
      _selectedStoreId = store.id;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_store_id', store.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // StoreSelector intégré en haut
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: StoreSelector(
            onStoreChanged: _onStoreChanged,
            currentStore:
                null, // Optionnel: peut être reconstruit pour afficher le store courant
          ),
        ),
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
                      child: CatalogPanel(key: ValueKey<String?>(_selectedStoreId), storeId: _selectedStoreId),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: CartPanel(storeId: _selectedStoreId),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: ClientPaymentPanel(
                        isTablet: true,
                        storeId: _selectedStoreId,
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
                      child: CatalogPanel(key: ValueKey<String?>(_selectedStoreId), storeId: _selectedStoreId),
                    ),
                    VerticalDivider(width: 1),
                    Expanded(
                      flex: 4,
                      child: CartPanel(storeId: _selectedStoreId),
                    ),
                    VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: ClientPaymentPanel(storeId: _selectedStoreId),
                    ),
                  ],
                );
              }
            },
          ),
        ),
        SaleActionBar(storeId: _selectedStoreId),
      ],
    );
  }
}
