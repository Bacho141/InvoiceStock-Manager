class StockMovement {
  final String id;
  final String productId;
  final String storeId;
  final String type;
  final int quantity;
  final int previousQuantity;
  final int newQuantity;
  final String? userId;
  final String? userName;
  final String? reason;
  final DateTime createdAt;

  StockMovement({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    this.userId,
    this.userName,
    this.reason,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    String? userName;
    // Cas 1 : userId est un objet peuplé (populate)
    if (json['userId'] is Map && json['userId'] != null) {
      userName = json['userId']['username']?.toString();
    }
    // Cas 2 : user est présent (fallback)
    if (userName == null && json['user'] is Map && json['user'] != null) {
      userName = json['user']['username']?.toString();
    }
    // Cas 3 : userName direct (rare)
    if (userName == null && json['userName'] != null) {
      userName = json['userName'].toString();
    }
    return StockMovement(
      id: json['_id'] is Map
          ? json['_id']['\$oid'] ?? json['_id'].toString()
          : json['_id'].toString(),
      productId: json['productId'] is Map
          ? json['productId']['_id']?.toString() ?? json['productId'].toString()
          : json['productId'].toString(),
      storeId: json['storeId'] is Map
          ? json['storeId']['_id']?.toString() ?? json['storeId'].toString()
          : json['storeId'].toString(),
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? 0,
      previousQuantity: json['previousQuantity'] ?? 0,
      newQuantity: json['newQuantity'] ?? 0,
      userId: json['userId'] is Map
          ? json['userId']['_id']?.toString()
          : json['userId']?.toString() ?? (json['user']?['_id']?.toString()),
      userName: userName,
      reason: json['reason']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'productId': productId,
    'storeId': storeId,
    'type': type,
    'quantity': quantity,
    'previousQuantity': previousQuantity,
    'newQuantity': newQuantity,
    'userId': userId,
    'userName': userName,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };
}
