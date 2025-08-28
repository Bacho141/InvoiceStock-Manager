class ApiUrls {
  static const String baseUrl = 'http://192.168.3.26:5000/api';
  // static const String baseUrl = 'http://10.10.10.31:5000/api';
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

  // Nouvelles URLs pour synchronisation vente-stock
  static String checkStockAvailability(String storeId, String productId) =>
      '$baseUrl/stocks/$storeId/$productId/availability';
  static String reserveStock(String storeId) =>
      '$baseUrl/stocks/$storeId/reserve';
  static String releaseReservation(String storeId) =>
      '$baseUrl/stocks/$storeId/release';
  static String recordSaleMovement(String storeId) =>
      '$baseUrl/stocks/$storeId/sale-movement';
  static String getProductStock(String storeId, String productId) =>
      '$baseUrl/stocks/$storeId/$productId';

  static String invoicesRemoveLine(String invoiceId) =>
      '$invoices/$invoiceId/remove-line';
  static String invoicesValidate(String invoiceId, String storeId) =>
      '$invoices/$invoiceId/validate/$storeId';

  // URLs pour la gestion des paiements
  static String invoicePayments(String invoiceId) =>
      '$invoices/$invoiceId/payments';
  static String invoicePayment(String invoiceId, String paymentId) =>
      '$invoices/$invoiceId/payments/$paymentId';
  static String confirmPayment(String invoiceId, String paymentId) =>
      '$invoices/$invoiceId/payments/$paymentId/confirm';
  static String paymentReceipt(String invoiceId, String paymentId) =>
      '$invoices/$invoiceId/payments/$paymentId/receipt';

  // URL pour générer le PDF d'une facture
  static String invoicePDF(String invoiceId) => '$invoices/$invoiceId/pdf';
}
