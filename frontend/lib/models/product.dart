class Product {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? unit;
  final double purchasePrice;
  final double sellingPrice;
  final int minStockLevel;
  final int maxStockLevel;
  final String? barcode;
  final String? image;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reference;

  Product({
    required this.id,
    required this.name,
    this.reference,
    this.description,
    this.category,
    this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.minStockLevel = 0,
    this.maxStockLevel = 0,
    this.barcode,
    this.image,
    this.isActive = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'],
      reference: json['reference'],
      description: json['description'],
      category: json['category'],
      unit: json['unit'],
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      minStockLevel: json['minStockLevel'] ?? 0,
      maxStockLevel: json['maxStockLevel'] ?? 0,
      barcode: json['barcode'],
      image: json['image'],
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['_id']
          : json['createdBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Ajouté pour l'API
      'name': name,
      'reference': reference,
      'description': description,
      'category': category,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'minStockLevel': minStockLevel,
      'maxStockLevel': maxStockLevel,
      'barcode': barcode,
      'image': image,
      'isActive': isActive,
      // 'createdBy': createdBy, // Ne pas envoyer côté client
    };
  }

  // Ajout d'un getter 'reference' pour compatibilité UI
  String get ref => reference ?? barcode ?? id ?? '';

  // Ajout d'une méthode copyWith pour permettre la modification immuable
  Product copyWith({
    String? id,
    String? name,
    String? reference,
    String? description,
    String? category,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? minStockLevel,
    int? maxStockLevel,
    String? barcode,
    String? image,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      maxStockLevel: maxStockLevel ?? this.maxStockLevel,
      barcode: barcode ?? this.barcode,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
