import 'package:flutter/material.dart';
import 'dart:math' as math;

class Client {
  // Propriétés existantes
  final String id;
  final String firstName;
  final String lastName;

  // Nouvelles propriétés de contact
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String customerType;
  final String? city;
  final String? region;

  // Configuration commerciale
  final String? assignedStore;
  final double creditLimit;
  final int paymentTerms;
  final String category;
  final String priority;
  final String? assignedSalesperson;
  final String? preferredPaymentMethod;

  // Alertes et notifications
  final bool alertsEnabled;
  final bool creditLimitAlerts;
  final bool emailInvoices;

  // Métriques calculées
  final double totalRevenue;
  final int invoiceCount;
  final DateTime? lastInvoiceDate;
  final int averagePaymentDelay;
  final double creditScore;
  final double currentOutstanding;

  // Notes et communications
  final String? notes;
  final List<Communication> communicationHistory;

  // Statut
  final String status;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.company,
    this.customerType = 'particulier',
    this.city,
    this.region,
    this.assignedStore,
    this.creditLimit = 0.0,
    this.paymentTerms = 30,
    this.category = 'particulier',
    this.priority = 'normal',
    this.assignedSalesperson,
    this.preferredPaymentMethod,
    this.alertsEnabled = true,
    this.creditLimitAlerts = true,
    this.emailInvoices = false,
    this.totalRevenue = 0.0,
    this.invoiceCount = 0,
    this.lastInvoiceDate,
    this.averagePaymentDelay = 0,
    this.creditScore = 5.0,
    this.currentOutstanding = 0.0,
    this.notes,
    this.communicationHistory = const [],
    this.status = 'active',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  }) {
    // Vérifications pour débogage
    print('Client créé: ID=$id, Nom=$firstName $lastName');
    print('customerType: $customerType');
    print('category: $category');
    print('priority: $priority');
    print('status: $status');
  }

  String get fullName => '$firstName $lastName'.trim();

  // Getters calculés
  String get displayName {
    if (company != null && company!.isNotEmpty) {
      return '$fullName - $company';
    }
    return fullName;
  }

  String get customerTypeDisplay {
    switch (customerType) {
      case 'particulier':
        return 'Particulier';
      case 'entreprise':
        return 'Entreprise';
      default:
        return customerType;
    }
  }

  String get categoryDisplay {
    switch (category) {
      case 'grossiste':
        return 'Grossiste';
      case 'detaillant':
        return 'Détaillant';
      case 'particulier':
        return 'Particulier';
      default:
        return category;
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case 'bas':
        return 'Basse';
      case 'normal':
        return 'Normale';
      case 'haut':
        return 'Haute';
      default:
        return priority;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'blocked':
        return 'Bloqué';
      default:
        return status;
    }
  }

  // Méthodes utilitaires
  bool get hasOutstandingBalance => currentOutstanding > 0;
  bool get isOverCreditLimit =>
      currentOutstanding > creditLimit && creditLimit > 0;
  bool get isLowCreditScore => creditScore < 3.0;
  bool get hasRecentActivity =>
      lastInvoiceDate != null &&
      DateTime.now().difference(lastInvoiceDate!).inDays <= 30;

  double get creditUtilizationRate {
    if (creditLimit <= 0) return 0.0;
    return (currentOutstanding / creditLimit * 100).clamp(0.0, 100.0);
  }

  String get creditScoreLevel {
    if (creditScore >= 8) return 'Excellent';
    if (creditScore >= 6) return 'Bon';
    if (creditScore >= 4) return 'Moyen';
    return 'Faible';
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      company: json['company'],
      customerType: json['customerType'] ?? 'particulier',
      city: json['city'],
      region: json['region'],
      assignedStore: json['assignedStore'],
      creditLimit: (json['creditLimit'] ?? 0.0).toDouble(),
      paymentTerms: json['paymentTerms'] ?? 30,
      category: json['category'] ?? 'particulier',
      priority: json['priority'] ?? 'normal',
      assignedSalesperson: json['assignedSalesperson'],
      preferredPaymentMethod: json['preferredPaymentMethod'],
      alertsEnabled: json['alertsEnabled'] ?? true,
      creditLimitAlerts: json['creditLimitAlerts'] ?? true,
      emailInvoices: json['emailInvoices'] ?? false,
      totalRevenue: (json['totalRevenue'] ?? 0.0).toDouble(),
      invoiceCount: json['invoiceCount'] ?? 0,
      lastInvoiceDate: json['lastInvoiceDate'] != null
          ? DateTime.parse(json['lastInvoiceDate'])
          : null,
      averagePaymentDelay: json['averagePaymentDelay'] ?? 0,
      creditScore: (json['creditScore'] ?? 5.0).toDouble(),
      currentOutstanding: (json['currentOutstanding'] ?? 0.0).toDouble(),
      notes: json['notes'],
      communicationHistory:
          (json['communicationHistory'] as List<dynamic>? ?? [])
              .map((comm) => Communication.fromJson(comm))
              .toList(),
      status: json['status'] ?? 'active',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'company': company,
      'customerType': customerType,
      'city': city,
      'region': region,
      'assignedStore': assignedStore,
      'creditLimit': creditLimit,
      'paymentTerms': paymentTerms,
      'category': category,
      'priority': priority,
      'assignedSalesperson': assignedSalesperson,
      'preferredPaymentMethod': preferredPaymentMethod,
      'alertsEnabled': alertsEnabled,
      'creditLimitAlerts': creditLimitAlerts,
      'emailInvoices': emailInvoices,
      'totalRevenue': totalRevenue,
      'invoiceCount': invoiceCount,
      'lastInvoiceDate': lastInvoiceDate?.toIso8601String(),
      'averagePaymentDelay': averagePaymentDelay,
      'creditScore': creditScore,
      'currentOutstanding': currentOutstanding,
      'notes': notes,
      'communicationHistory': communicationHistory
          .map((comm) => comm.toJson())
          .toList(),
      'status': status,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Méthode de copie avec modifications
  Client copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? address,
    String? company,
    String? customerType,
    String? city,
    String? region,
    String? assignedStore,
    double? creditLimit,
    int? paymentTerms,
    String? category,
    String? priority,
    String? assignedSalesperson,
    String? preferredPaymentMethod,
    bool? alertsEnabled,
    bool? creditLimitAlerts,
    bool? emailInvoices,
    double? totalRevenue,
    int? invoiceCount,
    DateTime? lastInvoiceDate,
    int? averagePaymentDelay,
    double? creditScore,
    double? currentOutstanding,
    String? notes,
    List<Communication>? communicationHistory,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      company: company ?? this.company,
      customerType: customerType ?? this.customerType,
      city: city ?? this.city,
      region: region ?? this.region,
      assignedStore: assignedStore ?? this.assignedStore,
      creditLimit: creditLimit ?? this.creditLimit,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      assignedSalesperson: assignedSalesperson ?? this.assignedSalesperson,
      preferredPaymentMethod:
          preferredPaymentMethod ?? this.preferredPaymentMethod,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      creditLimitAlerts: creditLimitAlerts ?? this.creditLimitAlerts,
      emailInvoices: emailInvoices ?? this.emailInvoices,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      invoiceCount: invoiceCount ?? this.invoiceCount,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      averagePaymentDelay: averagePaymentDelay ?? this.averagePaymentDelay,
      creditScore: creditScore ?? this.creditScore,
      currentOutstanding: currentOutstanding ?? this.currentOutstanding,
      notes: notes ?? this.notes,
      communicationHistory: communicationHistory ?? this.communicationHistory,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Modèle pour l'historique des communications
class Communication {
  final DateTime date;
  final String type;
  final String? subject;
  final String? content;
  final String? userId;

  Communication({
    required this.date,
    required this.type,
    this.subject,
    this.content,
    this.userId,
  });

  String get typeDisplay {
    switch (type) {
      case 'email':
        return 'Email';
      case 'phone':
        return 'Téléphone';
      case 'meeting':
        return 'Réunion';
      case 'other':
        return 'Autre';
      default:
        return type;
    }
  }

  factory Communication.fromJson(Map<String, dynamic> json) {
    return Communication(
      date: DateTime.parse(json['date']),
      type: json['type'],
      subject: json['subject'],
      content: json['content'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'type': type,
      'subject': subject,
      'content': content,
      'userId': userId,
    };
  }
}

// Nouveau modèle pour les factures en retard
class OverdueInvoice {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final double outstandingAmount;
  final int daysOverdue;
  final double totalAmount;
  final double paidAmount;
  final Client client;

  OverdueInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.outstandingAmount,
    required this.daysOverdue,
    required this.totalAmount,
    required this.paidAmount,
    required this.client,
  });

  factory OverdueInvoice.fromJson(Map<String, dynamic> json) {
    return OverdueInvoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'])
          : DateTime.now(),
      outstandingAmount: (json['outstandingAmount'] ?? 0.0).toDouble(),
      daysOverdue: json['daysOverdue'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0.0).toDouble(),
      client: json['client'] != null
          ? Client.fromJson(json['client'])
          : Client(
              id: '',
              firstName: '',
              lastName: '',
              customerType: 'particulier',
              category: 'particulier',
              priority: 'normal',
              status: 'active',
              creditLimit: 0.0,
              paymentTerms: 30,
              invoiceCount: 0,
              averagePaymentDelay: 0,
              creditScore: 5.0,
              currentOutstanding: 0.0,
              communicationHistory: const [],
              isActive: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'outstandingAmount': outstandingAmount,
      'daysOverdue': daysOverdue,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'client': client.toJson(),
    };
  }
}

// Nouveau modèle pour les créances regroupées par client
class ClientOverdueSummary {
  final Client client;
  final List<OverdueInvoice> overdueInvoices;
  final double totalOutstanding;
  final int totalInvoices;

  ClientOverdueSummary({
    required this.client,
    required this.overdueInvoices,
    required this.totalOutstanding,
    required this.totalInvoices,
  });

  // Calcul du nombre de jours de retard maximum
  int get maxDaysOverdue {
    if (overdueInvoices.isEmpty) return 0;
    return overdueInvoices.map((i) => i.daysOverdue).reduce(math.max);
  }

  // Calcul du niveau de risque
  String get riskLevel {
    if (totalOutstanding >= 200000 || client.creditScore < 3) {
      return 'Critique';
    } else if (totalOutstanding >= 50000 || client.creditScore < 5) {
      return 'Élevé';
    } else if (totalOutstanding > 0) {
      return 'Modéré';
    }
    return 'Faible';
  }

  // Couleur associée au niveau de risque
  Color get riskColor {
    switch (riskLevel) {
      case 'Critique':
        return Colors.red;
      case 'Élevé':
        return Colors.orange;
      case 'Modéré':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }
}
