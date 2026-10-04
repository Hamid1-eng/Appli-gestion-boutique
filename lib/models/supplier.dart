class Supplier {
  Supplier({
    required this.id,
    required this.adminId,
    required this.name,
    required this.category,
    required this.currentDebt,
    this.phone,
    this.email,
    this.activeOrders = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String adminId;
  final String name;
  final String category;
  final double currentDebt;
  final String? phone;
  final String? email;
  final int activeOrders;
  final DateTime createdAt;

  String get badgeText {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    final String source = name.trim();
    if (source.isEmpty) {
      return 'SP';
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  Supplier copyWith({
    String? id,
    String? adminId,
    String? name,
    String? category,
    double? currentDebt,
    String? phone,
    String? email,
    int? activeOrders,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      category: category ?? this.category,
      currentDebt: currentDebt ?? this.currentDebt,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      activeOrders: activeOrders ?? this.activeOrders,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'name': name,
      'category': category,
      'currentDebt': currentDebt,
      'phone': phone,
      'email': email,
      'activeOrders': activeOrders,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      currentDebt: (json['currentDebt'] as num?)?.toDouble() ?? 0,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      activeOrders: (json['activeOrders'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
