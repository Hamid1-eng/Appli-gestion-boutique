import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DataRetentionService {
  static const Duration _retention = Duration(days: 30);

  static Future<int> purgeForAdmin({
    required FirebaseFirestore firestore,
    required String adminId,
  }) async {
    final int deletedSales = await purgeOldSalesForAdmin(
      firestore: firestore,
      adminId: adminId,
    );
    final int deletedInvoices = await purgeOldInvoicesForAdmin(
      firestore: firestore,
      adminId: adminId,
    );
    return deletedSales + deletedInvoices;
  }

  static Future<int> purgeForAdminIds({
    required FirebaseFirestore firestore,
    required Iterable<String> adminIds,
  }) async {
    int totalDeleted = 0;
    final Set<String> uniqueAdminIds = adminIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    for (final String adminId in uniqueAdminIds) {
      totalDeleted += await purgeForAdmin(
        firestore: firestore,
        adminId: adminId,
      );
    }
    return totalDeleted;
  }

  static Future<int> purgeOldSalesForAdmin({
    required FirebaseFirestore firestore,
    required String adminId,
  }) async {
    if (adminId.trim().isEmpty) {
      return 0;
    }

    try {
      final DateTime cutoff = DateTime.now().subtract(_retention);
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('sales')
          .where('adminId', isEqualTo: adminId)
          .get();

      final List<DocumentReference<Map<String, dynamic>>> toDelete =
          <DocumentReference<Map<String, dynamic>>>[];

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final DateTime? saleDate = _toDateTime(doc.data()['date']);
        if (saleDate != null && saleDate.isBefore(cutoff)) {
          toDelete.add(doc.reference);
        }
      }

      await _deleteInChunks(firestore: firestore, refs: toDelete);
      return toDelete.length;
    } catch (error) {
      debugPrint('Retention sales cleanup error: $error');
      return 0;
    }
  }

  static Future<int> purgeOldInvoicesForAdmin({
    required FirebaseFirestore firestore,
    required String adminId,
  }) async {
    if (adminId.trim().isEmpty) {
      return 0;
    }

    try {
      final DateTime cutoff = DateTime.now().subtract(_retention);
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('invoices')
          .where('adminId', isEqualTo: adminId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final List<DocumentReference<Map<String, dynamic>>> toDelete = snapshot
          .docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.reference,
          )
          .toList();

      await _deleteInChunks(firestore: firestore, refs: toDelete);
      return toDelete.length;
    } catch (error) {
      debugPrint('Retention invoices cleanup error: $error');
      return 0;
    }
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static Future<void> _deleteInChunks({
    required FirebaseFirestore firestore,
    required List<DocumentReference<Map<String, dynamic>>> refs,
  }) async {
    const int chunkSize = 400;
    for (int i = 0; i < refs.length; i += chunkSize) {
      final int end = (i + chunkSize > refs.length)
          ? refs.length
          : i + chunkSize;
      final List<DocumentReference<Map<String, dynamic>>> chunk = refs.sublist(
        i,
        end,
      );
      final WriteBatch batch = firestore.batch();
      for (final DocumentReference<Map<String, dynamic>> ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
