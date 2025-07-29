class Invoice {
  final String id;
  final String invoiceNumber;
  final DateTime date;
  final String customerName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? notes;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerName,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.notes,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      customerName: json['customerName'] ?? 'Client non spécifié',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'Espèces',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}

class InvoiceItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final double total;

  InvoiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    double? total,
  }) : total = total ?? price * quantity;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Produit sans nom',
      price: (json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 1).toInt(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
    };
  }
}
