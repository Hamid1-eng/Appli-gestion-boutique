import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import 'auth_provider.dart';

class ExpensesProvider extends ChangeNotifier {
  ExpensesProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    unawaited(_syncScope());
  }

  final AuthProvider _authProvider;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<Expense> _expenses = <Expense>[];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _adminId;

  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('expenses');

  void _handleAuthChanged() {
    unawaited(_syncScope());
  }

  Future<void> _syncScope() async {
    final String? nextAdminId = _authProvider.currentAdminId;
    if (nextAdminId == _adminId && _sub != null) {
      return;
    }

    await _sub?.cancel();
    _sub = null;

    _adminId = nextAdminId;
    _expenses.clear();
    notifyListeners();

    if (nextAdminId == null || nextAdminId.isEmpty) {
      return;
    }

    _sub = _collection
        .where('adminId', isEqualTo: nextAdminId)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            _expenses
              ..clear()
              ..addAll(
                snapshot.docs
                    .map(
                      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                          Expense.fromJson(<String, dynamic>{
                            ...doc.data(),
                            'id': doc.id,
                          }),
                    )
                    .toList()
                  ..sort((Expense a, Expense b) => b.date.compareTo(a.date)),
              );
            notifyListeners();
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('ExpensesProvider stream error: $error');
            notifyListeners();
          },
        );
  }

  void addExpense({
    required String type,
    required double amount,
    String? note,
  }) {
    final String? adminId = _adminId;
    if (amount <= 0 || adminId == null || adminId.isEmpty) {
      return;
    }

    final Expense expense = Expense(
      id: _id('exp'),
      adminId: adminId,
      type: type,
      amount: amount,
      date: DateTime.now(),
      note: note,
    );

    unawaited(_collection.doc(expense.id).set(expense.toJson()));
    _expenses.insert(0, expense);
    notifyListeners();
  }

  double expenseAmountFor(DateTimeRange range) {
    return _expenses
        .where((Expense expense) => _inRange(expense.date, range))
        .fold<double>(0, (double sum, Expense expense) => sum + expense.amount);
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
}
