class Product {
  Product({
    required this.id,
    required this.adminId,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.stock,
    required this.alertThreshold,
    this.supplier = '-- Sans Fournisseur --',
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String adminId;
  final String name;
  final String category;
  final double purchasePrice;
  final double salePrice;
  final int stock;
  final int alertThreshold;
  final String supplier;
  final String? imageUrl;
  final DateTime createdAt;

  bool get isLowStock => stock <= alertThreshold;

  Product copyWith({
    String? id,
    String? adminId,
    String? name,
    String? category,
    double? purchasePrice,
    double? salePrice,
    int? stock,
    int? alertThreshold,
    String? supplier,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stock: stock ?? this.stock,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      supplier: supplier ?? this.supplier,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stock': stock,
      'alertThreshold': alertThreshold,
      'supplier': supplier,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      alertThreshold: (json['alertThreshold'] as num?)?.toInt() ?? 0,
      supplier: (json['supplier'] ?? '-- Sans Fournisseur --').toString(),
      imageUrl: json['imageUrl']?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
