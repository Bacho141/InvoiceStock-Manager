
class InvoiceLine {
  final String product;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double totalLine;

  InvoiceLine({
    required this.product,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.totalLine,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      product: json['product'],
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      discount: json['discount'].toDouble(),
      totalLine: json['totalLine'].toDouble(),
    );
  }
}
