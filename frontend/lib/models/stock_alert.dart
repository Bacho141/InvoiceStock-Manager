class StockAlert {
  final String id;
  final String storeId;
  final String productId;
  final String type;
  final String message;
  final bool isRead;
  final bool isResolved;
  final DateTime createdAt;

  StockAlert({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.isResolved,
    required this.createdAt,
  });

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      id: json['_id'] is Map
          ? json['_id']['\$oid'] ?? json['_id'].toString()
          : json['_id'].toString(),
      storeId: json['storeId'] is Map
          ? json['storeId']['_id']?.toString() ?? json['storeId'].toString()
          : json['storeId'].toString(),
      productId: json['productId'] is Map
          ? json['productId']['_id']?.toString() ?? json['productId'].toString()
          : json['productId'].toString(),
      type: json['type']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] ?? false,
      isResolved: json['isResolved'] ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'storeId': storeId,
    'productId': productId,
    'type': type,
    'message': message,
    'isRead': isRead,
    'isResolved': isResolved,
    'createdAt': createdAt.toIso8601String(),
  };
}
