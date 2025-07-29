import 'package:flutter/foundation.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String? logoUrl;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.name,
    required this.address,
    this.logoUrl,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    debugPrint('[STORE][fromJson] json: $json');
    // Gestion robuste du champ _id
    String id;
    if (json['_id'] is Map) {
      id = json['_id']['_id']?.toString() ?? json['_id'].toString();
    } else {
      id = json['_id']?.toString() ?? '';
    }

    // Gestion robuste du champ createdBy
    String createdBy;
    if (json['createdBy'] is Map) {
      createdBy = json['createdBy']['username']?.toString() ?? '';
    } else {
      createdBy = json['createdBy']?.toString() ?? '';
    }

    return Store(
      id: id,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      isActive: json['isActive'] ?? true,
      createdBy: createdBy,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'address': address,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Store(id: $id, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
