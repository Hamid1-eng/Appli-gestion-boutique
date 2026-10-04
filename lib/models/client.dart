class Client {
  Client({
    required this.id,
    required this.adminId,
    required this.name,
    required this.phone,
    this.creditBalance = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String adminId;
  final String name;
  final String phone;
  final double creditBalance;
  final DateTime createdAt;

  Client copyWith({
    String? id,
    String? adminId,
    String? name,
    String? phone,
    double? creditBalance,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      creditBalance: creditBalance ?? this.creditBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'name': name,
      'phone': phone,
      'creditBalance': creditBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      creditBalance: (json['creditBalance'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
