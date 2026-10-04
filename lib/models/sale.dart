class Sale {
  Sale({
    required this.id,
    required this.adminId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPurchasePrice,
    required this.unitSalePrice,
    required this.paidAmount,
    required this.date,
    this.clientId,
    this.client,
  });

  final String id;
  final String adminId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPurchasePrice;
  final double unitSalePrice;
  final double paidAmount;
  final DateTime date;
  final String? clientId;
  final String? client;

  double get amount => unitSalePrice * quantity;
  double get cost => unitPurchasePrice * quantity;
  double get profit => amount - cost;
  double get creditAmount => amount - paidAmount;
  bool get isCredit => creditAmount > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPurchasePrice': unitPurchasePrice,
      'unitSalePrice': unitSalePrice,
      'paidAmount': paidAmount,
      'date': date.toIso8601String(),
      'clientId': clientId,
      'client': client,
    };
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPurchasePrice: (json['unitPurchasePrice'] as num?)?.toDouble() ?? 0,
      unitSalePrice: (json['unitSalePrice'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      clientId: json['clientId']?.toString(),
      client: json['client']?.toString(),
    );
  }
}
