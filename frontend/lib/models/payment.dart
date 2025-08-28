import 'package:flutter/foundation.dart';
import './user.dart';

/// Modèle pour les méthodes de paiement disponibles
enum PaymentMethod {
  especes('Espèces', '💰'),
  carte('Carte bancaire', '💳'),
  mobileMoney('Mobile Money', '📱'),
  cheque('Chèque', '📝'),
  virement('Virement', '🏦'),
  autre('Autre', '📄');

  const PaymentMethod(this.label, this.icon);
  final String label;
  final String icon;

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'especes':
      case 'espèces':
      case 'cash':
        return PaymentMethod.especes;
      case 'carte':
      case 'carte_bancaire':
      case 'card':
        return PaymentMethod.carte;
      case 'mobile_money':
      case 'mobilemoney':
      case 'mobile money':
        return PaymentMethod.mobileMoney;
      case 'cheque':
      case 'chèque':
      case 'check':
        return PaymentMethod.cheque;
      case 'virement':
      case 'transfer':
        return PaymentMethod.virement;
      default:
        return PaymentMethod.autre;
    }
  }

  String get value => name;
}

/// Statut d'un paiement
enum PaymentStatus {
  pending('En attente', '⏳'),
  confirmed('Confirmé', '✅'),
  cancelled('Annulé', '❌'),
  refunded('Remboursé', '↩️');

  const PaymentStatus(this.label, this.icon);
  final String label;
  final String icon;

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'en_attente':
        return PaymentStatus.pending;
      case 'confirmed':
      case 'confirmé':
      case 'confirme':
        return PaymentStatus.confirmed;
      case 'cancelled':
      case 'annulé':
      case 'annule':
        return PaymentStatus.cancelled;
      case 'refunded':
      case 'remboursé':
      case 'rembourse':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.confirmed;
    }
  }
}

/// Modèle complet pour un paiement
class Payment {
  final String id;
  final DateTime createdAt;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? reference;
  final String? notes;
  final User? processedBy;
  final DateTime? confirmedAt;
  final String? receiptNumber;

  Payment({
    required this.id,
    required this.createdAt,
    required this.amount,
    required this.method,
    this.status = PaymentStatus.confirmed,
    this.reference,
    this.notes,
    this.processedBy,
    this.confirmedAt,
    this.receiptNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] ?? json['id'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['date'] != null
                ? DateTime.parse(json['date'])
                : DateTime.now()),
      amount: (json['amount'] ?? 0).toDouble(),
      method: PaymentMethod.fromString(json['method'] ?? 'especes'),
      status: PaymentStatus.fromString(json['status'] ?? 'confirmed'),
      reference: json['reference'],
      notes: json['notes'],
      processedBy: json['processedBy'] != null
          ? User.fromJson(json['processedBy'])
          : null,
      confirmedAt: json['confirmedAt'] != null
          ? DateTime.parse(json['confirmedAt'])
          : null,
      receiptNumber: json['receiptNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'amount': amount,
      'method': method.value,
      'status': status.name,
      'reference': reference,
      'notes': notes,
      'processedBy': processedBy?.toJson(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'receiptNumber': receiptNumber,
    };
  }

  /// Formatage du montant en devise locale
  String get formattedAmount {
    return '${amount.toStringAsFixed(0)} FCFA';
  }

  /// Formatage de la date en format court
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  /// Copie avec modifications
  Payment copyWith({
    String? id,
    DateTime? createdAt,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? reference,
    String? notes,
    User? processedBy,
    DateTime? confirmedAt,
    String? receiptNumber,
  }) {
    return Payment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      processedBy: processedBy ?? this.processedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }
}

/// Extension pour les calculs sur liste de paiements
extension PaymentListExtension on List<Payment> {
  /// Montant total des paiements confirmés
  double get totalConfirmed {
    return where(
      (p) => p.status == PaymentStatus.confirmed,
    ).fold(0.0, (sum, payment) => sum + payment.amount);
  }

  /// Montant total en attente
  double get totalPending {
    return where(
      (p) => p.status == PaymentStatus.pending,
    ).fold(0.0, (sum, payment) => sum + payment.amount);
  }

  /// Grouper par méthode de paiement
  Map<PaymentMethod, List<Payment>> groupByMethod() {
    final grouped = <PaymentMethod, List<Payment>>{};
    for (final payment in this) {
      grouped.putIfAbsent(payment.method, () => []).add(payment);
    }
    return grouped;
  }

  /// Trier par date décroissante
  List<Payment> sortByDateDesc() {
    final sorted = List<Payment>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}
