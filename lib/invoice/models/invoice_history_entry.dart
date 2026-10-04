import 'invoice_model.dart';

enum InvoicePaymentStatus { paid, pending, late }

extension InvoicePaymentStatusX on InvoicePaymentStatus {
  String get code {
    switch (this) {
      case InvoicePaymentStatus.paid:
        return 'paid';
      case InvoicePaymentStatus.pending:
        return 'pending';
      case InvoicePaymentStatus.late:
        return 'late';
    }
  }

  static InvoicePaymentStatus fromCode(String? code) {
    switch (code) {
      case 'pending':
        return InvoicePaymentStatus.pending;
      case 'late':
        return InvoicePaymentStatus.late;
      default:
        return InvoicePaymentStatus.paid;
    }
  }
}

class InvoiceHistoryEntry {
  const InvoiceHistoryEntry({
    required this.id,
    required this.adminId,
    required this.invoiceNumber,
    required this.filePath,
    required this.createdAt,
    required this.format,
    required this.total,
    required this.currency,
    required this.paymentStatus,
    this.dueAt,
    this.clientName,
  });

  final String id;
  final String adminId;
  final String invoiceNumber;
  final String filePath;
  final DateTime createdAt;
  final InvoicePaperFormat format;
  final double total;
  final String currency;
  final InvoicePaymentStatus paymentStatus;
  final DateTime? dueAt;
  final String? clientName;

  InvoicePaymentStatus statusAt(DateTime when) {
    if (paymentStatus == InvoicePaymentStatus.paid) {
      return InvoicePaymentStatus.paid;
    }

    if (dueAt != null) {
      final DateTime cutoff = DateTime(
        dueAt!.year,
        dueAt!.month,
        dueAt!.day,
        23,
        59,
        59,
        999,
      );
      if (when.isAfter(cutoff)) {
        return InvoicePaymentStatus.late;
      }
    }

    if (paymentStatus == InvoicePaymentStatus.late) {
      return InvoicePaymentStatus.late;
    }

    return InvoicePaymentStatus.pending;
  }

  InvoicePaymentStatus get currentStatus => statusAt(DateTime.now());

  InvoiceHistoryEntry copyWith({
    String? id,
    String? adminId,
    String? invoiceNumber,
    String? filePath,
    DateTime? createdAt,
    InvoicePaperFormat? format,
    double? total,
    String? currency,
    InvoicePaymentStatus? paymentStatus,
    DateTime? dueAt,
    String? clientName,
  }) {
    return InvoiceHistoryEntry(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      format: format ?? this.format,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      dueAt: dueAt ?? this.dueAt,
      clientName: clientName ?? this.clientName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'adminId': adminId,
      'invoiceNumber': invoiceNumber,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'format': format.code,
      'total': total,
      'currency': currency,
      'paymentStatus': paymentStatus.code,
      'dueAt': dueAt?.toIso8601String(),
      'clientName': clientName,
    };
  }

  factory InvoiceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InvoiceHistoryEntry(
      id: (json['id'] ?? '').toString(),
      adminId: (json['adminId'] ?? '').toString(),
      invoiceNumber: (json['invoiceNumber'] ?? '').toString(),
      filePath: (json['filePath'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      format: InvoicePaperFormatX.fromCode(json['format']?.toString()),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'GNF').toString(),
      paymentStatus: InvoicePaymentStatusX.fromCode(
        json['paymentStatus']?.toString(),
      ),
      dueAt: DateTime.tryParse((json['dueAt'] ?? '').toString()),
      clientName: json['clientName']?.toString(),
    );
  }
}
