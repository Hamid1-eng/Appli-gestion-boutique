import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/client.dart';
import 'auth_provider.dart';

class ClientsProvider extends ChangeNotifier {
  ClientsProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    unawaited(_syncScope());
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Client> _clients = <Client>[];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _streamError;
  String? _adminId;
  int _scopeVersion = 0;

  String? get streamError => _streamError;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('clients');

  List<Client> get clients => List<Client>.unmodifiable(_clients);

  double get totalClientCredit {
    return _clients.fold<double>(
      0,
      (double sum, Client client) => sum + client.creditBalance,
    );
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
    _clients.clear();
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
            _clients
              ..clear()
              ..addAll(
                snapshot.docs
                    .map(
                      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                          Client.fromJson(<String, dynamic>{
                            ...doc.data(),
                            'id': doc.id,
                          }),
                    )
                    .toList()
                  ..sort(
                    (Client a, Client b) => b.createdAt.compareTo(a.createdAt),
                  ),
              );
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            _streamError = _mapError(error);
            debugPrint('ClientsProvider stream error: $error');
            notifyListeners();
          },
        );
  }

  Future<void> addClient({required String name, required String phone}) async {
    final String? adminId = _adminId;
    if (name.trim().isEmpty || phone.trim().isEmpty || adminId == null) {
      return;
    }

    final Client client = Client(
      id: _id('client'),
      adminId: adminId,
      name: name.trim(),
      phone: phone.trim(),
    );

    try {
      await _collection.doc(client.id).set(client.toJson());
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  Future<void> saveClient(Client client) async {
    final String? adminId = _adminId;
    if (adminId == null || adminId.isEmpty) {
      throw Exception('Aucun administrateur connecté.');
    }

    try {
      await _collection
          .doc(client.id)
          .set(client.copyWith(adminId: adminId).toJson());
    } catch (error) {
      throw Exception(_mapError(error));
    }
  }

  Future<void> updateClientCredit({
    required String clientId,
    required double amount,
  }) async {
    final Client? client = byId(clientId);
    if (client == null) {
      return;
    }

    final double next = (client.creditBalance + amount).clamp(
      0,
      double.infinity,
    );

    final Client updated = client.copyWith(creditBalance: next);
    await saveClient(updated);
  }

  Client? byId(String clientId) {
    final int index = _clients.indexWhere(
      (Client client) => client.id == clientId,
    );
    if (index == -1) {
      return null;
    }
    return _clients[index];
  }

  Future<void> repayClientCredit({
    required String clientId,
    required double amount,
  }) async {
    if (amount <= 0) {
      return;
    }
    await updateClientCredit(clientId: clientId, amount: -amount);
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
      debugPrint('ClientsProvider migration error: $error');
    }
  }
}
