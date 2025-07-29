import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'routes/routes.dart';
import 'utiles/app_theme.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const InvoiceStockApp());
}

class InvoiceStockApp extends StatelessWidget {
  const InvoiceStockApp({Key? key}) : super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'InvoiceStock Manager',
        theme: AppTheme.themeData,
        initialRoute: '/',
        routes: AppRoutes.routes,
      ),
    );
  }
}
