class ApiUrls {
  // static const String baseUrl = 'http://192.168.43.97:5000/api';
  static const String baseUrl = 'http://10.10.10.5:5000/api';
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String verifySession = '$baseUrl/auth/verify';
  static const String sessionInfo = '$baseUrl/auth/session-info';
  static const String users = '$baseUrl/users';
  static const String stores = '$baseUrl/stores';
  static const String products = '$baseUrl/products';
  static const String invoices = '$baseUrl/invoices';
  static const String clients = '$baseUrl/clients';

  // Stocks par magasin (préfixe /api/stocks)
  static String stocksByStore(String storeId) => '$baseUrl/stocks/$storeId';
  static String adjustStock(String storeId) =>
      '$baseUrl/stocks/$storeId/adjust';
  static String stockMovements(String storeId) =>
      '$baseUrl/stocks/$storeId/movements';
  static String productMovements(String storeId, String productId) =>
      '$baseUrl/stocks/$storeId/$productId/movements';
  static String stockAlerts(String storeId) =>
      '$baseUrl/stocks/$storeId/alerts';
  static const String transferStock = '$baseUrl/stocks/transfer';
  static const String listStocks = '$baseUrl/stocks';
  static String stockIndicators(String storeId) =>
      '$baseUrl/stocks/$storeId/indicators';

  static String invoicesRemoveLine(String invoiceId) => '$invoices/$invoiceId/remove-line';
}
