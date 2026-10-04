import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/invoice_history_entry.dart';
import '../models/invoice_model.dart';
import 'invoice_history_service.dart';
import '../ui/invoice_preview_page.dart';

class InvoiceService {
  const InvoiceService();

  String buildInvoiceNumber({DateTime? now}) {
    final DateTime date = now ?? DateTime.now();
    final String stamp = DateFormat('yyyyMMdd-HHmmss').format(date);
    return 'FAC-$stamp';
  }

  Future<Uint8List> generateInvoice(
    InvoiceModel invoice, {
    InvoicePaperFormat format = InvoicePaperFormat.ticket80mm,
  }) async {
    late final pw.Document pdf;
    try {
      final pw.Font baseFont = format == InvoicePaperFormat.ticket80mm 
          ? pw.Font.courier() 
          : await PdfGoogleFonts.notoSansRegular();
      final pw.Font boldFont = format == InvoicePaperFormat.ticket80mm 
          ? pw.Font.courierBold() 
          : await PdfGoogleFonts.notoSansBold();
      pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
      );
    } catch (_) {
      pdf = pw.Document();
    }
    final Uint8List? logoBytes = await _loadLogo(invoice.shop.logoAssetPath);
    final String invoiceNumber =
        invoice.invoiceNumber ?? buildInvoiceNumber(now: invoice.createdAt);
    final bool compact = format != InvoicePaperFormat.a4;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pageFormat(format),
        margin: pw.EdgeInsets.all(format == InvoicePaperFormat.ticket80mm ? 10 : (compact ? 12 : 24)),
        build: (pw.Context context) {
          if (format == InvoicePaperFormat.ticket80mm) {
            return <pw.Widget>[
              _buildTicketLayout(
                invoice,
                invoiceNumber,
                pdf.theme!.defaultTextStyle.font ?? pw.Font.courier(),
                pdf.theme!.defaultTextStyle.fontBold ?? pw.Font.courierBold(),
              ),
            ];
          }
          return <pw.Widget>[
            _buildHeader(invoice, invoiceNumber, logoBytes, compact),
            pw.SizedBox(height: compact ? 10 : 18),
            _buildClientBlock(invoice, compact),
            pw.SizedBox(height: compact ? 10 : 18),
            _buildItemsTable(invoice, compact),
            pw.SizedBox(height: compact ? 10 : 16),
            _buildTotals(invoice, compact),
            pw.SizedBox(height: compact ? 12 : 20),
            _buildFooterMessage(invoice, compact),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<File> saveInvoice(
    InvoiceModel invoice, {
    required String adminId,
    Uint8List? bytes,
    bool preferDownloads = true,
    InvoicePaperFormat format = InvoicePaperFormat.a4,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Enregistrement local non disponible sur Web');
    }

    final Uint8List data =
        bytes ?? await generateInvoice(invoice, format: format);
    final String invoiceNumber =
        invoice.invoiceNumber ?? buildInvoiceNumber(now: invoice.createdAt);
    final String filename = '${invoiceNumber}_${format.fileSuffix}.pdf';
    final List<Directory> candidates = <Directory>[
      await _resolveSaveDirectory(preferDownloads: preferDownloads),
    ];
    final Directory documents = await getApplicationDocumentsDirectory();
    if (!candidates.any((Directory item) => item.path == documents.path)) {
      candidates.add(documents);
    }

    Object? lastError;
    for (final Directory directory in candidates) {
      try {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final File file = File(
          '${directory.path}${Platform.pathSeparator}$filename',
        );
        final File written = await file.writeAsBytes(data, flush: true);

        await InvoiceHistoryService(adminId: adminId).addOrUpdate(
          InvoiceHistoryEntry(
            id: '$invoiceNumber-${format.code}',
            adminId: adminId,
            invoiceNumber: invoiceNumber,
            filePath: written.path,
            createdAt: invoice.createdAt,
            format: format,
            total: invoice.grandTotal,
            currency: invoice.currency,
            paymentStatus: _statusFromInvoice(invoice),
            dueAt: invoice.dueAt,
            clientName: invoice.clientName,
          ),
        );

        return written;
      } catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Impossible d\'enregistrer la facture sur cet appareil: $lastError',
    );
  }

  Future<void> printInvoice(
    InvoiceModel invoice, {
    Uint8List? bytes,
    InvoicePaperFormat format = InvoicePaperFormat.a4,
  }) async {
    final Uint8List data =
        bytes ?? await generateInvoice(invoice, format: format);
    final String invoiceNumber =
        invoice.invoiceNumber ?? buildInvoiceNumber(now: invoice.createdAt);

    await Printing.layoutPdf(
      name: '${invoiceNumber}_${format.fileSuffix}.pdf',
      format: _pageFormat(format),
      onLayout: (PdfPageFormat format) async => data,
    );
  }

  Future<void> shareInvoice(
    InvoiceModel invoice, {
    Uint8List? bytes,
    InvoicePaperFormat format = InvoicePaperFormat.a4,
  }) async {
    final Uint8List data =
        bytes ?? await generateInvoice(invoice, format: format);
    final String invoiceNumber =
        invoice.invoiceNumber ?? buildInvoiceNumber(now: invoice.createdAt);

    final XFile file = XFile.fromData(
      data,
      mimeType: 'application/pdf',
      name: '${invoiceNumber}_${format.fileSuffix}.pdf',
    );

    await Share.shareXFiles(
      <XFile>[file],
      subject: 'Facture $invoiceNumber',
      text: 'Veuillez trouver ci-joint votre facture $invoiceNumber.',
    );
  }

  Future<void> previewInvoice(
    BuildContext context,
    InvoiceModel invoice, {
    Uint8List? bytes,
    InvoicePaperFormat format = InvoicePaperFormat.a4,
  }) async {
    final Uint8List data =
        bytes ?? await generateInvoice(invoice, format: format);
    final String invoiceNumber =
        invoice.invoiceNumber ?? buildInvoiceNumber(now: invoice.createdAt);

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoicePreviewPage(
          bytes: data,
          title: 'Prévisualisation $invoiceNumber (${format.label})',
        ),
      ),
    );
  }

  Future<void> previewPdfBytes(
    BuildContext context, {
    required Uint8List bytes,
    required String title,
  }) async {
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvoicePreviewPage(bytes: bytes, title: title),
      ),
    );
  }

  Future<void> printSavedInvoice(InvoiceHistoryEntry entry) async {
    final File file = File(entry.filePath);
    if (!await file.exists()) {
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    await Printing.layoutPdf(
      name: '${entry.invoiceNumber}_${entry.format.fileSuffix}.pdf',
      format: _pageFormat(entry.format),
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }

  Future<void> shareSavedInvoice(InvoiceHistoryEntry entry) async {
    final File file = File(entry.filePath);
    if (!await file.exists()) {
      return;
    }

    await Share.shareXFiles(
      <XFile>[XFile(file.path)],
      subject: 'Facture ${entry.invoiceNumber}',
      text: 'Veuillez trouver ci-joint votre facture ${entry.invoiceNumber}.',
    );
  }

  PdfPageFormat _pageFormat(InvoicePaperFormat format) {
    switch (format) {
      case InvoicePaperFormat.a4:
        return PdfPageFormat.a4;
      case InvoicePaperFormat.thermalA5:
        return PdfPageFormat.a5;
      case InvoicePaperFormat.ticket80mm:
        // 80mm thermal ticket format (80mm x 200mm)
        return PdfPageFormat(226.77, 566.93);
    }
  }

  Future<Directory> _resolveSaveDirectory({
    required bool preferDownloads,
  }) async {
    if (kIsWeb) {
      return getApplicationDocumentsDirectory();
    }

    if (Platform.isAndroid && preferDownloads) {
      final Directory downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return downloads;
      }
    }

    if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }

    if (Platform.isAndroid) {
      final Directory? external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }

    return getApplicationDocumentsDirectory();
  }

  Future<Uint8List?> _loadLogo(String? assetPath) async {
    if (assetPath == null || assetPath.trim().isEmpty) {
      return null;
    }

    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildHeader(
    InvoiceModel invoice,
    String invoiceNumber,
    Uint8List? logoBytes,
    bool compact,
  ) {
    final String dateText = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(invoice.createdAt);

    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 10 : 16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(compact ? 8 : 12),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (logoBytes != null)
            pw.Container(
              width: 56,
              height: 56,
              margin: pw.EdgeInsets.only(right: compact ? 8 : 12),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            )
          else
            pw.Container(
              width: 56,
              height: 56,
              margin: pw.EdgeInsets.only(right: compact ? 8 : 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                invoice.shop.name.isNotEmpty
                    ? invoice.shop.name.substring(0, 1).toUpperCase()
                    : 'B',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  invoice.shop.name,
                  style: pw.TextStyle(
                    fontSize: compact ? 13 : 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.SizedBox(height: compact ? 2 : 4),
                pw.Text(
                  invoice.shop.address,
                  style: pw.TextStyle(fontSize: compact ? 8 : 10),
                ),
                pw.Text(
                  'Tel: ${invoice.shop.phone}',
                  style: pw.TextStyle(fontSize: compact ? 8 : 10),
                ),
                if (invoice.shop.email != null)
                  pw.Text(
                    'Email: ${invoice.shop.email}',
                    style: pw.TextStyle(fontSize: compact ? 8 : 10),
                  ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: <pw.Widget>[
              pw.Text(
                'FACTURE',
                style: pw.TextStyle(
                  fontSize: compact ? 11 : 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              pw.SizedBox(height: compact ? 3 : 6),
              pw.Text(
                'No: $invoiceNumber',
                style: pw.TextStyle(fontSize: compact ? 8 : 10),
              ),
              pw.Text(
                'Date: $dateText',
                style: pw.TextStyle(fontSize: compact ? 8 : 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildClientBlock(InvoiceModel invoice, bool compact) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.all(compact ? 8 : 12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(compact ? 6 : 8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Client',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: compact ? 9 : 11,
            ),
          ),
          pw.SizedBox(height: compact ? 2 : 4),
          pw.Text(
            invoice.clientName ?? 'Client comptant',
            style: pw.TextStyle(fontSize: compact ? 8 : 10),
          ),
          if ((invoice.clientPhone ?? '').isNotEmpty)
            pw.Text(
              'Tel: ${invoice.clientPhone}',
              style: pw.TextStyle(fontSize: compact ? 8 : 10),
            ),
          if ((invoice.clientAddress ?? '').isNotEmpty)
            pw.Text(
              'Adresse: ${invoice.clientAddress}',
              style: pw.TextStyle(fontSize: compact ? 8 : 10),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(InvoiceModel invoice, bool compact) {
    final List<List<String>> rows = invoice.items.map((InvoiceItem item) {
      return <String>[
        item.name,
        item.quantity.toString(),
        _money(item.unitPrice, invoice.currency),
        _money(item.lineTotal, invoice.currency),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: const <String>['Produit', 'Qte', 'PU', 'Total'],
      data: rows,
      border: null,
      cellAlignment: pw.Alignment.centerLeft,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: compact ? 8 : 10,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: pw.TextStyle(fontSize: compact ? 8 : 10),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      headerAlignments: <int, pw.Alignment>{
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      cellAlignments: <int, pw.Alignment>{
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _buildTotals(InvoiceModel invoice, bool compact) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: compact ? 170 : 220,
        padding: pw.EdgeInsets.all(compact ? 8 : 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(compact ? 6 : 8),
        ),
        child: pw.Column(
          children: <pw.Widget>[
            _totalRow(
              'Sous-total',
              _money(invoice.subTotal, invoice.currency),
              compact: compact,
            ),
            if (invoice.taxRate > 0)
              _totalRow(
                'Taxe (${invoice.taxRate.toStringAsFixed(0)}%)',
                _money(invoice.taxAmount, invoice.currency),
                compact: compact,
              ),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              'Total general',
              _money(invoice.grandTotal, invoice.currency),
              compact: compact,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    bool compact = false,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: compact ? 1 : 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: compact ? 8 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: compact ? 8 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooterMessage(InvoiceModel invoice, bool compact) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(
        vertical: compact ? 8 : 10,
        horizontal: compact ? 8 : 12,
      ),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(compact ? 6 : 8),
        color: PdfColors.indigo50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Merci pour votre confiance.',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
              fontSize: compact ? 8 : 10,
            ),
          ),
          if ((invoice.notes ?? '').isNotEmpty)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: compact ? 2 : 4),
              child: pw.Text(
                invoice.notes!,
                style: pw.TextStyle(fontSize: compact ? 7 : 9),
              ),
            ),
          if (invoice.dueAt != null)
            pw.Padding(
              padding: pw.EdgeInsets.only(top: compact ? 2 : 4),
              child: pw.Text(
                'Echeance: ${DateFormat('dd/MM/yyyy').format(invoice.dueAt!)}',
                style: pw.TextStyle(fontSize: compact ? 7 : 9),
              ),
            ),
        ],
      ),
    );
  }

  String _money(double value, String currency) {
    final NumberFormat formatter = NumberFormat('#,##0', 'fr_FR');
    return '${formatter.format(value)} $currency';
  }

  InvoicePaymentStatus _statusFromInvoice(InvoiceModel invoice) {
    if (invoice.dueAt != null) {
      final DateTime now = DateTime.now();
      final DateTime cutoff = DateTime(
        invoice.dueAt!.year,
        invoice.dueAt!.month,
        invoice.dueAt!.day,
        23,
        59,
        59,
        999,
      );
      return now.isAfter(cutoff)
          ? InvoicePaymentStatus.late
          : InvoicePaymentStatus.pending;
    }

    final String notes = (invoice.notes ?? '').toLowerCase();
    if (notes.contains('reste à payer') || notes.contains('reste a payer')) {
      return InvoicePaymentStatus.pending;
    }

    return InvoicePaymentStatus.paid;
  }

  pw.Widget _buildTicketLayout(
    InvoiceModel invoice,
    String invoiceNumber,
    pw.Font baseFont,
    pw.Font boldFont,
  ) {
    final String dateText =
        DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt);
    final String paymentStatus =
        invoice.dueAt == null ? 'COMPTANT' : 'CREDIT_CLIENT';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.Text(
          invoice.shop.name.toUpperCase(),
          style: pw.TextStyle(font: boldFont, fontSize: 16),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          "L'excellence au quotidien",
          style: pw.TextStyle(font: baseFont, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Tel: ${invoice.shop.phone}',
          style: pw.TextStyle(font: baseFont, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),

        // Dashed line 1
        _buildDashedLine(),
        pw.SizedBox(height: 8),

        // Info Block
        _ticketRow('FAC N° :', invoiceNumber, baseFont),
        _ticketRow('Date :', dateText, baseFont),
        _ticketRow('Caissier :', 'Caissier', baseFont), // Hardcoded or generic as requested
        _ticketRow('Paiement :', paymentStatus, baseFont),

        pw.SizedBox(height: 8),
        _buildDashedLine(),
        pw.SizedBox(height: 8),

        // Header Table
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Expanded(
              flex: 3,
              child: pw.Text(
                'Article',
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                'Qté',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Prix',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(font: boldFont, fontSize: 10),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),

        // Items
        ...invoice.items.map((InvoiceItem item) {
          final NumberFormat formatter = NumberFormat('#,##0', 'fr_FR');
          final String itemTotal = formatter.format(item.lineTotal);

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    item.name,
                    style: pw.TextStyle(font: baseFont, fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    item.quantity.toString(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: baseFont, fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    itemTotal,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(font: baseFont, fontSize: 10),
                  ),
                ),
              ],
            ),
          );
        }),

        pw.SizedBox(height: 8),
        _buildDashedLine(),
        pw.SizedBox(height: 8),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'TOTAL A PAYER :',
              style: pw.TextStyle(font: boldFont, fontSize: 11),
            ),
            pw.Text(
              '${NumberFormat('#,##0', 'fr_FR').format(invoice.grandTotal)} ${invoice.currency}',
              style: pw.TextStyle(font: boldFont, fontSize: 12),
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Text(
          'Merci de votre visite et à très bientôt !',
          style: pw.TextStyle(font: baseFont, fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        pw.Text('***', style: pw.TextStyle(font: baseFont, fontSize: 10)),
      ],
    );
  }

  pw.Widget _ticketRow(String label, String value, pw.Font font) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDashedLine() {
    return pw.Divider(
      color: PdfColors.black,
      borderStyle: pw.BorderStyle.dashed,
      thickness: 1,
    );
  }
}
