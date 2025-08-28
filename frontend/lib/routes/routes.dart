import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/user_management_screen.dart';
import '../screens/new_sale_screen.dart';
import '../screens/managementInvoice/invoices_list_screen.dart';
import '../screens/managementInvoice/invoice_detail_screen.dart';
import '../screens/products_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stock/stocks_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/creances_screen.dart';
import '../layout/main_layout.dart';

class AppRoutes {
  static const String invoiceDetail = '/invoice-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case invoiceDetail:
        final invoiceId = settings.arguments as String?;
        if (invoiceId != null) {
          return MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoiceId),
            settings: settings, // Pass settings for route name matching
          );
        }
        return _errorRoute('ID de facture manquant pour la route ${settings.name}');

      // Routes statiques existantes
      case '/':
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/user-management':
        return MaterialPageRoute(builder: (_) => const UserManagementScreen());
      case '/new-sale':
        return MaterialPageRoute(builder: (_) => const NewSaleScreen());
      case '/invoices':
        return MaterialPageRoute(builder: (_) => const InvoicesListScreen());
      case '/products':
        return MaterialPageRoute(builder: (_) => const ProductsScreen());
      case '/reports':
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/stocks':
         return MaterialPageRoute(builder: (_) => MainLayout(
            currentRoute: '/stocks',
            pageTitle: '📦 Stocks',
            child: Container(), // Le layout gère l'affichage de StocksScreen dynamiquement
          ));
      case '/clients':
        return MaterialPageRoute(builder: (_) => const ClientsScreen());
      case '/creances':
        return MaterialPageRoute(builder: (_) => const CreancesScreen());
        
      default:
        return _errorRoute('Page non trouvée: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Erreur de Navigation'),
          ),
          body: Center(
            child: Text(message),
          ),
        );
      },
    );
  }

  // La map de routes n'est plus utilisée par MaterialApp mais peut servir de référence.
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
          Container(),
    ),
    '/clients': (context) => const ClientsScreen(),
    '/creances': (context) => const CreancesScreen(),
  };
}
