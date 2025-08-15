import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/new_sale_screen.dart';
import '../screens/managementInvoice/invoices_list_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stock/stocks_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/creances_screen.dart';
import '../layout/main_layout.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const WelcomeScreen(),
    '/login': (context) => const LoginScreen(),
    '/dashboard': (context) => const DashboardScreen(),
    '/user-management': (context) => const UserManagementScreen(),
    '/new-sale': (context) => const NewSaleScreen(),
    '/invoices': (context) => const InvoicesListScreen(),
    '/products': (context) => const ProductsScreen(),
    '/reports': (context) => const ReportsScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/stocks': (context) => MainLayout(
      currentRoute: '/stocks',
      pageTitle: '📦 Stocks',
      child:
          Container(), // Le layout gère l'affichage de StocksScreen dynamiquement
    ),
    '/clients': (context) => const ClientsScreen(),
    '/creances': (context) => const CreancesScreen(),
  };
}
