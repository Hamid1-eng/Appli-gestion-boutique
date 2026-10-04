import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'auth_provider.dart';
import 'clients_provider.dart';
import 'products_provider.dart';

class SalesProvider extends ChangeNotifier {
  SalesProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    unawaited(_syncScope());
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Sale> _sales = <Sale>[];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _streamError;
  String? _adminId;
  int _scopeVersion = 0;

  String? get streamError => _streamError;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('sales');

  List<Sale> get sales => List<Sale>.unmodifiable(_sales);

  void _handleAuthChanged() {
    unawaited(_syncScope());
  }

  Future<void> _syncScope() async {
    final String? nextAdminId = _authProvider.currentAdminId;
    if (nextAdminId == _adminId && _sub != null) {
      return;
    }

    _scopeVersion++;
    final int scopeVersion = _scopeVersion;

    await _sub?.cancel();
    _sub = null;

    _adminId = nextAdminId;
    _streamError = null;
    _sales.clear();
    notifyListeners();

    if (nextAdminId == null || nextAdminId.isEmpty) {
      return;
    }

    await _migrateLegacyDataIfNeeded(nextAdminId, scopeVersion);
    if (scopeVersion != _scopeVersion) {
      return;
    }

    _sub = _collection
        .where('adminId', isEqualTo: nextAdminId)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _sales
              ..clear()
              ..addAll(
                snapshot.docs
                    .map(
                      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                          Sale.fromJson(<String, dynamic>{
                            ...doc.data(),
                            'id': doc.id,
                          }),
                    )
                    .toList()
                  ..sort((Sale a, Sale b) => b.date.compareTo(a.date)),
              );
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _streamError = _mapError(error);
            debugPrint('SalesProvider stream error: $error');
            notifyListeners();
          },
        );
  }

  Future<bool> registerSale({
    required ProductsProvider productsProvider,
    required ClientsProvider clientsProvider,
    required String productId,
    required int quantity,
    String? clientId,
    String? clientName,
    double? paidAmount,
  }) async {
    final String? adminId = _adminId;
    if (adminId == null || quantity <= 0) {
      return false;
    }

    final int index = productsProvider.products.indexWhere(
      (p) => p.id == productId,
    );
    if (index == -1) {
      return false;
    }

    final Product product = productsProvider.products[index];
    if (product.stock < quantity) {
      return false;
    }

    final double totalAmount = product.salePrice * quantity;
    final double effectivePaid = paidAmount ?? totalAmount;
    if (effectivePaid < 0 || effectivePaid > totalAmount) {
      return false;
    }

    final double creditAmount = totalAmount - effectivePaid;
    if (creditAmount > 0) {
      if (clientId == null || clientId.isEmpty) {
        return false;
      }
      final bool exists = clientsProvider.clients.any(
        (Client c) => c.id == clientId,
      );
      if (!exists) {
        return false;
      }
    }

    final Product updatedProduct = product.copyWith(
      adminId: adminId,
      stock: product.stock - quantity,
    );
    final Client? client = clientId == null
        ? null
        : clientsProvider.byId(clientId);
    final Client? updatedClient = (creditAmount > 0 && client != null)
        ? client.copyWith(
            adminId: adminId,
            creditBalance: (client.creditBalance + creditAmount).clamp(
              0,
              double.infinity,
            ),
          )
        : null;

    final Sale sale = Sale(
      id: _id('sale'),
      adminId: adminId,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      unitPurchasePrice: product.purchasePrice,
      unitSalePrice: product.salePrice,
      paidAmount: effectivePaid,
      date: DateTime.now(),
      clientId: clientId,
      client: clientName,
    );

    final WriteBatch batch = _firestore.batch();
    batch.set(
      _firestore.collection('products').doc(updatedProduct.id),
      updatedProduct.toJson(),
    );
    batch.set(_collection.doc(sale.id), sale.toJson());
    if (updatedClient != null) {
      batch.set(
        _firestore.collection('clients').doc(updatedClient.id),
        updatedClient.toJson(),
      );
    }

    try {
      await batch.commit();
      return true;
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  double salesAmountFor(DateTimeRange range) {
    return _sales
        .where((Sale sale) => _inRange(sale.date, range))
        .fold<double>(0, (double sum, Sale sale) => sum + sale.amount);
  }

  double productCostFor(DateTimeRange range) {
    return _sales
        .where((Sale sale) => _inRange(sale.date, range))
        .fold<double>(0, (double sum, Sale sale) => sum + sale.cost);
  }

  List<MapEntry<String, int>> topProducts({int limit = 5}) {
    final Map<String, int> byName = <String, int>{};
    for (final Sale sale in _sales) {
      byName[sale.productName] =
          (byName[sale.productName] ?? 0) + sale.quantity;
    }

    final List<MapEntry<String, int>> entries = byName.entries.toList()
      ..sort(
        (MapEntry<String, int> a, MapEntry<String, int> b) =>
            b.value.compareTo(a.value),
      );

    return entries.take(limit).toList();
  }

  double totalPurchasesForClient(String clientId, String clientName) {
    return _sales
        .where(
          (Sale sale) => sale.clientId == clientId || sale.client == clientName,
        )
        .fold<double>(0, (double sum, Sale sale) => sum + sale.amount);
  }

  List<double> dailySalesForLastDays(int days) {
    final DateTime now = DateTime.now();
    return List<double>.generate(days, (int index) {
      final int dayOffset = days - index - 1;
      final DateTime target = DateTime(
        now.year,
        now.month,
        now.day - dayOffset,
      );
      final DateTime start = DateTime(target.year, target.month, target.day);
      final DateTime end = start.add(const Duration(days: 1));
      return salesAmountFor(DateTimeRange(start: start, end: end));
    });
  }

  static bool _inRange(DateTime date, DateTimeRange range) {
    return (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) &&
        date.isBefore(range.end);
  }

  static String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void dispose() {
    _authProvider.removeListener(_handleAuthChanged);
    _sub?.cancel();
    super.dispose();
  }

  static String _mapError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Acces refuse par les regles Firestore. Verifie Authentication et Firestore Rules.';
      }
      if (error.code == 'unavailable') {
        return 'Service Firestore indisponible. Verifie la connexion internet.';
      }
      return 'Erreur Firestore (${error.code}): ${error.message ?? 'inconnue'}';
    }
    return 'Erreur inattendue: $error';
  }

  Future<void> _migrateLegacyDataIfNeeded(
    String adminId,
    int scopeVersion,
  ) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> owned = await _collection
          .where('adminId', isEqualTo: adminId)
          .limit(1)
          .get();
      if (owned.docs.isNotEmpty || scopeVersion != _scopeVersion) {
        return;
      }

      final QuerySnapshot<Map<String, dynamic>> legacy = await _collection
          .where('adminId', isNull: true)
          .get();
      if (legacy.docs.isEmpty || scopeVersion != _scopeVersion) {
        return;
      }

      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in legacy.docs) {
        batch.update(doc.reference, <String, dynamic>{'adminId': adminId});
      }
      await batch.commit();
    } catch (error) {
      debugPrint('SalesProvider migration error: $error');
    }
  }
}
