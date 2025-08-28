import 'dart:convert';
import 'package:flutter/foundation.dart';
import './client.dart';
import './store.dart';
import './user.dart';

class PaymentHistory {
  final DateTime date;
  final double amount;
  final String method;
  final String userId;

  PaymentHistory({
    required this.date,
    required this.amount,
    required this.method,
    required this.userId,
  });

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
    return PaymentHistory(
      date: DateTime.parse(json['date']),
      amount: (json['amount'] as num).toDouble(),
      method: json['method'],
      userId: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'method': method,
      'user': userId,
    };
  }
}

class Invoice {
  final String id;
  final String number;
  final DateTime date;
  final Client client;
  final Store store;
  final User user;
  final List<InvoiceItem> lines;
  final double total;
  final double montantPaye;
  final double discountTotal;
  final String status;
  final List<PaymentHistory> paymentHistory;
  final String? notes;

  Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.client,
    required this.store,
    required this.user,
    required this.lines,
    required this.total,
    required this.montantPaye,
    required this.discountTotal,
    required this.status,
    required this.paymentHistory,
    this.notes,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {

    return Invoice(
      id: json['_id'] ?? '',
      number: json['number'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      client: Client.fromJson(json['client'] ?? {}),
      store: Store.fromJson(json['store'] ?? {}),
      user: User.fromJson(json['user'] ?? {}),
      lines: (json['lines'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      total: (json['total'] ?? 0).toDouble(),
      montantPaye: (json['montantPaye'] ?? 0).toDouble(),
      discountTotal: (json['discountTotal'] ?? 0).toDouble(),
      status: json['status'] ?? 'reste_a_payer',
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
              ?.map((item) => PaymentHistory.fromJson(item))
              .toList() ??
          [],
      notes: json['notes'],
    );
  }

   Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'number': number,
      'date': date.toIso8601String(),
      'client': client.toJson(),
      'store': store.toJson(),
      'user': user.toJson(),
      'lines': lines.map((item) => item.toJson()).toList(),
      'total': total,
      'montantPaye': montantPaye,
      'discountTotal': discountTotal,
      'status': status,
      'paymentHistory': paymentHistory.map((item) => item.toJson()).toList(),
      'notes': notes,
    };
  }
}

class InvoiceItem {
  final String id;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalLine;

  InvoiceItem({
    required this.id,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalLine,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['_id'] ?? json['id'] ?? '',
      productName: json['productName'] ?? 'Produit sans nom',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toInt(),
      totalLine: (json['totalLine'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'totalLine': totalLine,
    };
  }
}