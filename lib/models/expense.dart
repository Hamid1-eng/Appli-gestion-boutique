class Expense {
  Expense({
    required this.id,
    required this.adminId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String adminId;
  final String type;
  final double amount;
  final DateTime date;
  final String? note;

  Expense copyWith({
    String? id,
    String? adminId,
    String? type,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date:
          DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
      note: json['note']?.toString(),
    );
  }
}
