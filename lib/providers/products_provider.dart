import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import 'auth_provider.dart';

class ProductsProvider extends ChangeNotifier {
  ProductsProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    unawaited(_syncScope());
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Product> _products = <Product>[];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _streamError;
  String? _adminId;
  int _scopeVersion = 0;
  static const String _cacheKeyPrefix = 'products_cache_v2';

  String? get streamError => _streamError;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  List<Product> get products => List<Product>.unmodifiable(_products);

  List<Product> get lowStockProducts {
    return _products.where((Product product) => product.isLowStock).toList();
  }

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
    _products.clear();
    notifyListeners();

    if (nextAdminId == null || nextAdminId.isEmpty) {
      return;
    }

    await _migrateLegacyDataIfNeeded(nextAdminId, scopeVersion);
    if (scopeVersion != _scopeVersion) {
      return;
    }

    await _restoreFromCache(nextAdminId);
    if (scopeVersion != _scopeVersion) {
      return;
    }

    _sub = _collection
        .where('adminId', isEqualTo: nextAdminId)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _products
              ..clear()
              ..addAll(
                snapshot.docs
                    .map(
                      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                          Product.fromJson(<String, dynamic>{
                            ...doc.data(),
                            'id': doc.id,
                          }),
                    )
                    .toList()
                  ..sort(
                    (Product a, Product b) =>
                        b.createdAt.compareTo(a.createdAt),
                  ),
              );
            unawaited(_persistCache(nextAdminId));
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _streamError = _mapError(error);
            debugPrint('ProductsProvider stream error: $error');
            notifyListeners();
          },
        );
  }

  Future<void> addProduct(Product product) async {
    final String? adminId = _adminId;
    if (adminId == null || adminId.isEmpty) {
      throw Exception('Aucun administrateur connecté.');
    }

    try {
      final Product scoped = product.copyWith(adminId: adminId);
      await _collection.doc(scoped.id).set(scoped.toJson());
      final int existingIndex = _products.indexWhere(
        (Product p) => p.id == scoped.id,
      );
      if (existingIndex == -1) {
        _products.insert(0, scoped);
      } else {
        _products[existingIndex] = scoped;
      }
      await _persistCache(adminId);
      notifyListeners();
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  Future<void> updateProduct(Product updated) async {
    final String? adminId = _adminId;
    if (adminId == null || adminId.isEmpty) {
      throw Exception('Aucun administrateur connecté.');
    }

    try {
      final Product scoped = updated.copyWith(adminId: adminId);
      await _collection.doc(scoped.id).set(scoped.toJson());
      final int index = _products.indexWhere((Product p) => p.id == scoped.id);
      if (index != -1) {
        _products[index] = scoped;
        await _persistCache(adminId);
        notifyListeners();
      }
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _collection.doc(productId).delete();
      _products.removeWhere((Product product) => product.id == productId);
      final String? adminId = _adminId;
      if (adminId != null && adminId.isNotEmpty) {
        await _persistCache(adminId);
      }
      notifyListeners();
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  Future<bool> reduceStock({
    required String productId,
    required int quantity,
  }) async {
    final int index = _products.indexWhere((Product p) => p.id == productId);
    if (index == -1) {
      return false;
    }

    final Product product = _products[index];
    if (product.stock < quantity) {
      return false;
    }

    await updateProduct(product.copyWith(stock: product.stock - quantity));
    return true;
  }

  Product? byId(String productId) {
    final int index = _products.indexWhere(
      (Product item) => item.id == productId,
    );
    if (index == -1) {
      return null;
    }
    return _products[index];
  }

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
      debugPrint('ProductsProvider migration error: $error');
    }
  }

  Future<void> _restoreFromCache(String adminId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_cacheKey(adminId));
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<Product> cachedProducts =
          decoded
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList()
            ..sort(
              (Product a, Product b) => b.createdAt.compareTo(a.createdAt),
            );

      if (cachedProducts.isNotEmpty) {
        _products
          ..clear()
          ..addAll(cachedProducts);
        notifyListeners();
      }
    } catch (error) {
      debugPrint('ProductsProvider cache restore error: $error');
    }
  }

  Future<void> _persistCache(String adminId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        _products.map((Product item) => item.toJson()).toList(),
      );
      await prefs.setString(_cacheKey(adminId), encoded);
    } catch (error) {
      debugPrint('ProductsProvider cache persist error: $error');
    }
  }

  String _cacheKey(String adminId) => '$_cacheKeyPrefix::$adminId';
}
