class ShopInfo {
  const ShopInfo({
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.logoAssetPath,
  });

  final String name;
  final String address;
  final String phone;
  final String? email;
  final String? logoAssetPath;
}

class ProductModel {
  const ProductModel({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

typedef InvoiceItem = ProductModel;

enum InvoicePaperFormat { a4, thermalA5, ticket80mm }

extension InvoicePaperFormatX on InvoicePaperFormat {
  String get code {
    switch (this) {
      case InvoicePaperFormat.a4:
        return 'a4';
      case InvoicePaperFormat.thermalA5:
        return 'a5_thermal';
      case InvoicePaperFormat.ticket80mm:
        return 'ticket_80mm';
    }
  }

  String get label {
    switch (this) {
      case InvoicePaperFormat.a4:
        return 'A4';
      case InvoicePaperFormat.thermalA5:
        return 'A5 thermique';
      case InvoicePaperFormat.ticket80mm:
        return 'Ticket 80mm';
    }
  }

  String get fileSuffix {
    switch (this) {
      case InvoicePaperFormat.a4:
        return 'A4';
      case InvoicePaperFormat.thermalA5:
        return 'A5';
      case InvoicePaperFormat.ticket80mm:
        return 'TICKET80';
    }
  }

  static InvoicePaperFormat fromCode(String? code) {
    if (code == InvoicePaperFormat.thermalA5.code) {
      return InvoicePaperFormat.thermalA5;
    }
    if (code == InvoicePaperFormat.ticket80mm.code) {
      return InvoicePaperFormat.ticket80mm;
    }
    return InvoicePaperFormat.a4;
  }
}

class InvoiceModel {
  const InvoiceModel({
    required this.shop,
    required this.items,
    required this.createdAt,
    this.invoiceNumber,
    this.clientName,
    this.clientPhone,
    this.clientAddress,
    this.notes,
    this.dueAt,
    this.currency = 'GNF',
    this.taxRate = 0,
  });

  final ShopInfo shop;
  final List<ProductModel> items;
  final DateTime createdAt;
  final String? invoiceNumber;
  final String? clientName;
  final String? clientPhone;
  final String? clientAddress;
  final String? notes;
  final DateTime? dueAt;
  final String currency;

  // Tax rate in percent. Example: 18 means 18%.
  final double taxRate;

  double get subTotal {
    return items.fold<double>(0, (double sum, ProductModel item) {
      return sum + item.lineTotal;
    });
  }

  double get taxAmount => subTotal * (taxRate / 100);

  double get grandTotal => subTotal + taxAmount;
}
