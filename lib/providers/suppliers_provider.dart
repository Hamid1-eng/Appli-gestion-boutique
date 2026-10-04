import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/supplier.dart';
import 'auth_provider.dart';

class SuppliersProvider extends ChangeNotifier {
  SuppliersProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    unawaited(_syncScope());
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Supplier> _suppliers = <Supplier>[];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _adminId;

  List<Supplier> get suppliers => List<Supplier>.unmodifiable(_suppliers);

  double get totalDebt => _suppliers.fold<double>(
    0,
    (double sum, Supplier supplier) => sum + supplier.currentDebt,
  );

  int get totalActiveOrders => _suppliers.fold<int>(
    0,
    (int sum, Supplier supplier) => sum + supplier.activeOrders,
  );

  void _handleAuthChanged() {
    unawaited(_syncScope());
  }

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('suppliers');

  Future<void> _syncScope() async {
    final String? nextAdminId = _authProvider.currentAdminId;
    if (nextAdminId == _adminId && _sub != null) {
      return;
    }

    await _sub?.cancel();
    _sub = null;

    _adminId = nextAdminId;
    _suppliers.clear();
    notifyListeners();

    if (nextAdminId == null || nextAdminId.isEmpty) {
      return;
    }

    _sub = _collection
        .where('adminId', isEqualTo: nextAdminId)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _suppliers
              ..clear()
              ..addAll(
                snapshot.docs
                    .map(
                      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                          Supplier.fromJson(<String, dynamic>{
                            ...doc.data(),
                            'id': doc.id,
                          }),
                    )
                    .toList()
                  ..sort(
                    (Supplier a, Supplier b) =>
                        b.createdAt.compareTo(a.createdAt),
                  ),
              );
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('SuppliersProvider stream error: $error');
            notifyListeners();
          },
        );
  }

  void addSupplier({
    required String name,
    required String category,
    required double currentDebt,
    String? phone,
    String? email,
  }) {
    final String? adminId = _adminId;
    if (name.trim().isEmpty ||
        category.trim().isEmpty ||
        currentDebt < 0 ||
        adminId == null) {
      return;
    }

    final Supplier supplier = Supplier(
      id: _id('sup'),
      adminId: adminId,
      name: name.trim(),
      category: category.trim(),
      currentDebt: currentDebt,
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      createdAt: DateTime.now(),
    );

    unawaited(_collection.doc(supplier.id).set(supplier.toJson()));
    _suppliers.insert(0, supplier);
    notifyListeners();
  }

  static String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}
