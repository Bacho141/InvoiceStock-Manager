import 'store.dart';

class User {
  final String id;
  final String username;
  final String role; // 'super-admin', 'gestionnaire', 'caissier'
  final List<Store> assignedStores; // NOUVEAU
  final bool isActive;
  final DateTime createdAt;
  final bool
  hasTempPassword; // NOUVEAU - Indique si un mot de passe temporaire existe

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.assignedStores, // NOUVEAU
    required this.isActive,
    required this.createdAt,
    required this.hasTempPassword, // NOUVEAU
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Debug: afficher la structure des données
    print('[MODEL][User] Parsing JSON: ${json.toString()}');

    List<Store> assignedStores = [];
    if (json['assignedStores'] != null) {
      try {
        final storesList = json['assignedStores'] as List;
        assignedStores = storesList
            .map((storeData) {
              // Si c'est juste un ID (string), on crée un Store minimal
              if (storeData is String) {
                return Store(
                  id: storeData,
                  name: 'Magasin $storeData',
                  address: 'Adresse non disponible',
                  isActive: true,
                  createdBy: 'Système',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }
              // Si c'est un objet complet, on le parse normalement
              if (storeData is Map<String, dynamic>) {
                return Store.fromJson(storeData);
              }
              // Sinon on ignore
              return null;
            })
            .whereType<Store>()
            .toList();
      } catch (e) {
        print('[MODEL][User] Erreur parsing assignedStores: $e');
        assignedStores = [];
      }
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      assignedStores: assignedStores,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      hasTempPassword: json['hasTempPassword'] ?? false, // NOUVEAU
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'assignedStores': assignedStores
          .map((store) => store.toJson())
          .toList(), // NOUVEAU
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Méthode pour vérifier l'accès à un magasin
  bool hasAccessToStore(String storeId) {
    return role == 'super-admin' ||
        assignedStores.any((store) => store.id == storeId);
  }

  // Méthode pour vérifier si multi-magasins
  bool get isMultiStore => assignedStores.length > 1;

  // Méthode pour obtenir les IDs des magasins assignés
  List<String> get assignedStoreIds =>
      assignedStores.map((store) => store.id).toList();

  @override
  String toString() {
    return 'User(id: $id, username: $username, role: $role, stores: ${assignedStores.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
