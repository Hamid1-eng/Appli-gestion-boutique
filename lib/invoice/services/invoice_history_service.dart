import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/invoice_history_entry.dart';

class InvoiceHistoryService {
  InvoiceHistoryService({required this.adminId});

  static const Duration _legacyDefaultCreditTerm = Duration(days: 30);
  final String adminId;

  Future<List<InvoiceHistoryEntry>> getHistory() async {
    final File file = await _historyFile();
    if (!await file.exists()) {
      final File legacy = await _legacyHistoryFile();
      if (!await legacy.exists()) {
        return <InvoiceHistoryEntry>[];
      }

      final List<InvoiceHistoryEntry> legacyEntries = await _readFile(legacy);
      if (legacyEntries.isEmpty) {
        return <InvoiceHistoryEntry>[];
      }

      final List<InvoiceHistoryEntry> migrated = legacyEntries
          .map((InvoiceHistoryEntry entry) => entry.copyWith(adminId: adminId))
          .toList();
      migrated.sort(
        (InvoiceHistoryEntry a, InvoiceHistoryEntry b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      await _writeAll(migrated);
      await legacy.delete();
      return migrated;
    }

    try {
      final List<InvoiceHistoryEntry> entries = await _readFile(file);

      final List<InvoiceHistoryEntry> migrated = _migrateLegacyEntries(entries);

      migrated.sort(
        (InvoiceHistoryEntry a, InvoiceHistoryEntry b) =>
            b.createdAt.compareTo(a.createdAt),
      );
      if (_hasDifference(entries, migrated)) {
        await _writeAll(migrated);
      }

      return migrated;
    } catch (_) {
      return <InvoiceHistoryEntry>[];
    }
  }

  List<InvoiceHistoryEntry> _migrateLegacyEntries(
    List<InvoiceHistoryEntry> source,
  ) {
    return source.map((InvoiceHistoryEntry entry) {
      final bool isUnpaid = entry.paymentStatus != InvoicePaymentStatus.paid;
      if (!isUnpaid || entry.dueAt != null) {
        return entry;
      }

      return entry.copyWith(
        dueAt: entry.createdAt.add(_legacyDefaultCreditTerm),
      );
    }).toList();
  }

  bool _hasDifference(
    List<InvoiceHistoryEntry> before,
    List<InvoiceHistoryEntry> after,
  ) {
    if (before.length != after.length) {
      return true;
    }

    for (int i = 0; i < before.length; i++) {
      final DateTime? beforeDue = before[i].dueAt;
      final DateTime? afterDue = after[i].dueAt;
      if ((beforeDue == null) != (afterDue == null)) {
        return true;
      }
      if (beforeDue != null &&
          afterDue != null &&
          !beforeDue.isAtSameMomentAs(afterDue)) {
        return true;
      }
    }

    return false;
  }

  Future<void> addOrUpdate(InvoiceHistoryEntry entry) async {
    final List<InvoiceHistoryEntry> entries = await getHistory();

    final int samePathIndex = entries.indexWhere(
      (InvoiceHistoryEntry item) => item.filePath == entry.filePath,
    );

    if (samePathIndex >= 0) {
      entries[samePathIndex] = entry;
    } else {
      entries.add(entry);
    }

    entries.sort(
      (InvoiceHistoryEntry a, InvoiceHistoryEntry b) =>
          b.createdAt.compareTo(a.createdAt),
    );
    await _writeAll(entries);
  }

  Future<void> deleteById(String id) async {
    final List<InvoiceHistoryEntry> entries = await getHistory();
    entries.removeWhere((InvoiceHistoryEntry entry) => entry.id == id);
    await _writeAll(entries);
  }

  Future<void> removeMissingFiles() async {
    final List<InvoiceHistoryEntry> entries = await getHistory();
    final List<InvoiceHistoryEntry> filtered = <InvoiceHistoryEntry>[];

    for (final InvoiceHistoryEntry entry in entries) {
      if (await File(entry.filePath).exists()) {
        filtered.add(entry);
      }
    }

    await _writeAll(filtered);
  }

  Future<void> _writeAll(List<InvoiceHistoryEntry> entries) async {
    final File file = await _historyFile();
    final List<Map<String, dynamic>> jsonList = entries
        .map((InvoiceHistoryEntry item) => item.toJson())
        .toList();

    await file.writeAsString(jsonEncode(jsonList), flush: true);
  }

  Future<List<InvoiceHistoryEntry>> _readFile(File file) async {
    final String raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return <InvoiceHistoryEntry>[];
    }

    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .whereType<Map<String, dynamic>>()
        .map(InvoiceHistoryEntry.fromJson)
        .where(
          (InvoiceHistoryEntry entry) =>
              entry.adminId.isEmpty || entry.adminId == adminId,
        )
        .map(
          (InvoiceHistoryEntry entry) =>
              entry.adminId.isEmpty ? entry.copyWith(adminId: adminId) : entry,
        )
        .toList();
  }

  Future<File> _historyFile() async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory invoiceDir = Directory(
      '${root.path}${Platform.pathSeparator}invoices${Platform.pathSeparator}$adminId',
    );

    if (!await invoiceDir.exists()) {
      await invoiceDir.create(recursive: true);
    }

    return File('${invoiceDir.path}${Platform.pathSeparator}history.json');
  }

  Future<File> _legacyHistoryFile() async {
    final Directory root = await getApplicationDocumentsDirectory();
    final Directory invoiceDir = Directory(
      '${root.path}${Platform.pathSeparator}invoices',
    );
    return File('${invoiceDir.path}${Platform.pathSeparator}history.json');
  }
}
