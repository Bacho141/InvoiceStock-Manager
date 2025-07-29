class Stock {
  final String id;
  final String productId;
  final String storeId;
  final int quantity;
  final int minQuantity;
  final bool isActive;
  final DateTime lastUpdated;
  final String? description;
  final String? storeName;

  Stock({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.quantity,
    required this.minQuantity,
    required this.isActive,
    required this.lastUpdated,
    this.description,
    this.storeName,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    final product = json['productId'];
    final store = json['storeId'];
    return Stock(
      id: json['_id'] is Map
          ? json['_id']['\$oid'] ?? json['_id'].toString()
          : json['_id'].toString(),
      productId: product is Map
          ? product['_id']?.toString() ?? product.toString()
          : product.toString(),
      storeId: store is Map
          ? store['_id']?.toString() ?? store.toString()
          : store.toString(),
      quantity: json['quantity'] ?? 0,
      minQuantity: json['minQuantity'] ?? 0,
      isActive: json['isActive'] ?? true,
      lastUpdated:
          DateTime.tryParse(json['lastUpdated'] ?? json['updatedAt'] ?? '') ??
          DateTime.now(),
      description: product is Map ? product['description']?.toString() : null,
      storeName: store is Map ? store['name']?.toString() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'productId': productId,
    'storeId': storeId,
    'quantity': quantity,
    'minQuantity': minQuantity,
    'isActive': isActive,
    'lastUpdated': lastUpdated.toIso8601String(),
    'description': description,
    'storeName': storeName,
  };

  String get productName => description ?? productId;
}
