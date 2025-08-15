
class Store {
  final String id;
  final String name;
  final String address;
  final String? logoUrl;
  final bool isActive;
  final String createdBy;

  Store({
    required this.id,
    required this.name,
    required this.address,
    this.logoUrl,
    required this.isActive,
    required this.createdBy,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      logoUrl: json['logoUrl'],
      isActive: json['isActive'],
      createdBy: json['createdBy'],
    );
  }
}
