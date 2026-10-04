import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice_model.dart';
import '../services/invoice_service.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/auth_provider.dart';

enum _WebInvoiceFilter { all, paid, pending, late }

class InvoiceHistoryScreenWeb extends StatefulWidget {
  const InvoiceHistoryScreenWeb({super.key});

  @override
  State<InvoiceHistoryScreenWeb> createState() =>
      _InvoiceHistoryScreenWebState();
}

class _InvoiceHistoryScreenWebState extends State<InvoiceHistoryScreenWeb> {
  final InvoiceService _invoiceService = const InvoiceService();
  _WebInvoiceFilter _filter = _WebInvoiceFilter.all;
  String _search = '';
  Future<_DbCheckResult>? _dbCheckFuture;
  String? _dbCheckAdminId;
  String? _autoBackfillAdminId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeAutoBackfill();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final String? providerAdminId = context
        .watch<AuthProvider>()
        .currentAdminId;
    final String? authUid = FirebaseAuth.instance.currentUser?.uid;
    final String? adminId = (authUid != null && authUid.trim().isNotEmpty)
        ? authUid.trim()
        : providerAdminId;

    if (adminId == null || adminId.isEmpty) {
      return const SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            'Aucun administrateur connecté.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    _dbCheckFuture ??= _runDbCheck(adminId);
    if (_dbCheckAdminId != adminId) {
      _dbCheckAdminId = adminId;
      _dbCheckFuture = _runDbCheck(adminId);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invoices')
          .where('adminId', isEqualTo: adminId)
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.hasError) {
              return _buildDbErrorView(adminId: adminId, error: snapshot.error);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SafeArea(
                bottom: false,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final DateTime now = DateTime.now();
            final List<_WebInvoiceRow> invoices =
                (snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                      final Map<String, dynamic> data = doc.data();
                      final DateTime date =
                          _asDateTime(data['createdAt']) ?? now;
                      final DateTime dueAt =
                          _asDateTime(data['dueAt']) ??
                          date.add(const Duration(days: 30));

                      final String rawStatus = (data['paymentStatus'] ?? '')
                          .toString()
                          .toLowerCase();
                      final bool paid = rawStatus == 'paid';
                      final bool late =
                          !paid &&
                          now.isAfter(
                            DateTime(
                              dueAt.year,
                              dueAt.month,
                              dueAt.day,
                              23,
                              59,
                              59,
                              999,
                            ),
                          );

                      final _InvoiceStatus status = paid
                          ? _InvoiceStatus.paid
                          : late
                          ? _InvoiceStatus.late
                          : _InvoiceStatus.pending;

                      final String number = (data['invoiceNumber'] ?? '')
                          .toString()
                          .trim();
                      final String client = (data['clientName'] ?? '')
                          .toString()
                          .trim();

                      return _WebInvoiceRow(
                        id: doc.id,
                        number: number.isEmpty ? 'FAC-${doc.id}' : number,
                        client: client.isEmpty ? 'Client comptant' : client,
                        date: date,
                        dueAt: dueAt,
                        amount: (data['total'] as num?)?.toDouble() ?? 0,
                        status: status,
                        data: data,
                      );
                    })
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

            final int paidCount = invoices
                .where((item) => item.status == _InvoiceStatus.paid)
                .length;
            final int pendingCount = invoices
                .where((item) => item.status == _InvoiceStatus.pending)
                .length;
            final int lateCount = invoices
                .where((item) => item.status == _InvoiceStatus.late)
                .length;
            final List<_WebInvoiceRow> filtered = _applyFilter(invoices);
            final List<_WebInvoiceRow> visible = _applySearch(filtered);
            final double totalAmount = invoices.fold<double>(
              0,
              (double sum, _WebInvoiceRow row) => sum + row.amount,
            );

            if (!isDesktop) {
              return _buildCompactFunctionalView(
                appSettings: appSettings,
                invoices: invoices,
                visible: visible,
                paidCount: paidCount,
                pendingCount: pendingCount,
                lateCount: lateCount,
                totalAmount: totalAmount,
              );
            }

            return SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 120),
                children: <Widget>[
                  const Text(
                    'Factures',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vue d\'ensemble des factures et statuts de paiement en temps réel.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (invoices.isEmpty)
                    _buildDbDiagnosticsCard(adminId: adminId),
                  if (invoices.isEmpty) const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _InvoiceTopCard(
                          title: 'TOTAL FACTURES',
                          value: NumberFormat(
                            '#,###',
                            'fr_FR',
                          ).format(invoices.length),
                          subtitle: 'Documents générés',
                          icon: Icons.receipt_long_rounded,
                          iconBg: const Color(0xFFFFEDD5),
                          iconColor: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InvoiceTopCard(
                          title: 'MONTANT CUMULÉ',
                          value: appSettings.formatMoney(
                            totalAmount,
                            decimals: 0,
                          ),
                          subtitle: 'Toutes factures',
                          icon: Icons.account_balance_wallet_rounded,
                          iconBg: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InvoiceTopCard(
                          title: 'PAYÉES',
                          value: '$paidCount',
                          subtitle: 'Statut réglé',
                          icon: Icons.check_circle_rounded,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InvoiceTopCard(
                          title: 'EN ATTENTE',
                          value: '$pendingCount',
                          subtitle: '$lateCount en retard',
                          icon: Icons.pending_actions_rounded,
                          iconBg: const Color(0xFFFFF7ED),
                          iconColor: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8ECF3)),
                    ),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  _filterChip(
                                    label: 'Tout',
                                    selected: _filter == _WebInvoiceFilter.all,
                                    onTap: () => setState(
                                      () => _filter = _WebInvoiceFilter.all,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _filterChip(
                                    label: 'Payées',
                                    selected: _filter == _WebInvoiceFilter.paid,
                                    onTap: () => setState(
                                      () => _filter = _WebInvoiceFilter.paid,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _filterChip(
                                    label: 'En attente',
                                    selected:
                                        _filter == _WebInvoiceFilter.pending,
                                    onTap: () => setState(
                                      () => _filter = _WebInvoiceFilter.pending,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _filterChip(
                                    label: 'En retard',
                                    selected: _filter == _WebInvoiceFilter.late,
                                    onTap: () => setState(
                                      () => _filter = _WebInvoiceFilter.late,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 280,
                                    child: TextField(
                                      onChanged: (String value) {
                                        setState(() {
                                          _search = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        hintText:
                                            'Rechercher facture ou client...',
                                        prefixIcon: const Icon(
                                          Icons.search_rounded,
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF7315),
                                            width: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${visible.length} facture(s) affichée(s)',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFEFF2F6)),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'FACTURE',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'CLIENT',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'DATE',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'ÉCHÉANCE',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'MONTANT',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'STATUT',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 54,
                                child: Text(
                                  'APERCU',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFEFF2F6)),
                        if (visible.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Aucune facture pour ce filtre.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        else
                          ...visible
                              .take(30)
                              .map((row) => _invoiceRow(row, appSettings)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  List<_WebInvoiceRow> _applyFilter(List<_WebInvoiceRow> invoices) {
    switch (_filter) {
      case _WebInvoiceFilter.paid:
        return invoices
            .where((row) => row.status == _InvoiceStatus.paid)
            .toList();
      case _WebInvoiceFilter.pending:
        return invoices
            .where((row) => row.status == _InvoiceStatus.pending)
            .toList();
      case _WebInvoiceFilter.late:
        return invoices
            .where((row) => row.status == _InvoiceStatus.late)
            .toList();
      case _WebInvoiceFilter.all:
        return invoices;
    }
  }

  List<_WebInvoiceRow> _applySearch(List<_WebInvoiceRow> rows) {
    final String query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return rows;
    }

    return rows.where((row) {
      return row.number.toLowerCase().contains(query) ||
          row.client.toLowerCase().contains(query);
    }).toList();
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFEE2D5),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFB45309) : const Color(0xFF334155),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCompactFunctionalView({
    required AppSettingsProvider appSettings,
    required List<_WebInvoiceRow> invoices,
    required List<_WebInvoiceRow> visible,
    required int paidCount,
    required int pendingCount,
    required int lateCount,
    required double totalAmount,
  }) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 120),
        children: <Widget>[
          const Text(
            'Factures',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${invoices.length} facture(s) • ${appSettings.formatMoney(totalAmount, decimals: 0)}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (invoices.isEmpty)
            _buildDbDiagnosticsCard(adminId: _dbCheckAdminId ?? ''),
          if (invoices.isEmpty) const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _filterChip(
                  label: 'Tout (${invoices.length})',
                  selected: _filter == _WebInvoiceFilter.all,
                  onTap: () => setState(() => _filter = _WebInvoiceFilter.all),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Payées ($paidCount)',
                  selected: _filter == _WebInvoiceFilter.paid,
                  onTap: () => setState(() => _filter = _WebInvoiceFilter.paid),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'En attente ($pendingCount)',
                  selected: _filter == _WebInvoiceFilter.pending,
                  onTap: () =>
                      setState(() => _filter = _WebInvoiceFilter.pending),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Retard ($lateCount)',
                  selected: _filter == _WebInvoiceFilter.late,
                  onTap: () => setState(() => _filter = _WebInvoiceFilter.late),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (String value) {
              setState(() {
                _search = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Rechercher facture ou client...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFFF7315),
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${visible.length} facture(s) affichée(s)',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Aucune facture pour ce filtre.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ...visible.take(50).map((row) {
              Color statusBg;
              Color statusFg;
              String statusLabel;
              switch (row.status) {
                case _InvoiceStatus.paid:
                  statusBg = const Color(0xFFECFDF3);
                  statusFg = const Color(0xFF047857);
                  statusLabel = 'PAYÉE';
                  break;
                case _InvoiceStatus.pending:
                  statusBg = const Color(0xFFFFF7ED);
                  statusFg = const Color(0xFFB45309);
                  statusLabel = 'EN ATTENTE';
                  break;
                case _InvoiceStatus.late:
                  statusBg = const Color(0xFFFEF2F2);
                  statusFg = const Color(0xFFB91C1C);
                  statusLabel = 'EN RETARD';
                  break;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8ECF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            row.client,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusFg,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      row.number,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy', 'fr_FR').format(row.date)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Echéance: ${DateFormat('dd MMM yyyy', 'fr_FR').format(row.dueAt)}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            appSettings.formatMoney(row.amount, decimals: 0),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _previewInvoice(row),
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text('Aperçu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            side: const BorderSide(color: Color(0xFFC7D2FE)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDbErrorView({required String adminId, Object? error}) {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? 'null';
    final bool uidMismatch = authUid != 'null' && authUid != adminId;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: <Widget>[
          const Text(
            'Factures',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Text(
              'Erreur Firestore: ${error ?? 'inconnue'}',
              style: const TextStyle(
                color: Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Auth UID: $authUid',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Admin ID courant: $adminId',
                  style: const TextStyle(color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                Text(
                  uidMismatch
                      ? 'UID Firebase et adminId ne correspondent pas.'
                      : (authUid == 'null'
                            ? 'Aucune session Firebase active.'
                            : 'Session active: probable problème de règles Firestore déployées.'),
                  style: const TextStyle(color: Color(0xFFB45309)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => _recoverFirebaseSession(adminId),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Rétablir la session'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _dbCheckFuture = _runDbCheck(adminId);
                        });
                      },
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Retester la DB'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildDbDiagnosticsCard(adminId: adminId),
        ],
      ),
    );
  }

  Widget _buildDbDiagnosticsCard({required String adminId}) {
    final String trimmedId = adminId.trim();
    if (trimmedId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<_DbCheckResult>(
      future: _dbCheckFuture,
      builder: (BuildContext context, AsyncSnapshot<_DbCheckResult> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              'Diagnostic base de données en cours...',
              style: TextStyle(color: Color(0xFF475569)),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Text(
              'Diagnostic impossible: ${snapshot.error ?? 'erreur inconnue'}',
              style: const TextStyle(color: Color(0xFF9F1239)),
            ),
          );
        }

        final _DbCheckResult result = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Diagnostic DB',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Admin: ${result.adminId}',
                style: const TextStyle(color: Color(0xFF7C2D12), fontSize: 12),
              ),
              Text(
                'Ventes (sales): ${result.salesCount}',
                style: const TextStyle(color: Color(0xFF7C2D12), fontSize: 12),
              ),
              Text(
                'Factures (invoices): ${result.invoicesCount}',
                style: const TextStyle(color: Color(0xFF7C2D12), fontSize: 12),
              ),
              if (result.invoicesCount == 0 && result.salesCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Des ventes existent mais aucune facture: le flux d\'écriture invoices n\'a probablement pas abouti.',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _backfillInvoicesFromSales(result.adminId),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                        label: const Text('Générer les factures manquantes'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_DbCheckResult> _runDbCheck(String adminId) async {
    final String normalized = adminId.trim();
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final AggregateQuerySnapshot salesAgg = await db
        .collection('sales')
        .where('adminId', isEqualTo: normalized)
        .count()
        .get();
    final AggregateQuerySnapshot invoicesAgg = await db
        .collection('invoices')
        .where('adminId', isEqualTo: normalized)
        .count()
        .get();

    return _DbCheckResult(
      adminId: normalized,
      salesCount: salesAgg.count ?? 0,
      invoicesCount: invoicesAgg.count ?? 0,
    );
  }

  Future<void> _maybeAutoBackfill() async {
    final String? currentAuthId = FirebaseAuth.instance.currentUser?.uid.trim();
    final String? providerAdminId = context
        .read<AuthProvider>()
        .currentAdminId
        ?.trim();
    final String? adminId = (currentAuthId != null && currentAuthId.isNotEmpty)
        ? currentAuthId
        : providerAdminId;
    if (adminId == null || adminId.isEmpty) {
      return;
    }
    if (_autoBackfillAdminId == adminId) {
      return;
    }

    final Future<_DbCheckResult>? future = _dbCheckFuture;
    if (future == null) {
      return;
    }

    _autoBackfillAdminId = adminId;
    try {
      final _DbCheckResult result = await future;
      if (!mounted) {
        return;
      }
      if (result.salesCount > 0 && result.invoicesCount == 0) {
        await _backfillInvoicesFromSales(adminId);
      }
    } catch (_) {
      // Si le diagnostic échoue, on ne bloque pas l'affichage.
    }
  }

  Future<void> _recoverFirebaseSession(String adminId) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune session active. Reconnectez-vous.'),
          ),
        );
        return;
      }

      await user.getIdToken(true);
      await user.reload();

      if (!mounted) {
        return;
      }
      setState(() {
        _dbCheckFuture = _runDbCheck(adminId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session Firebase actualisée.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Echec actualisation session: $error')),
      );
    }
  }

  Future<void> _backfillInvoicesFromSales(String adminId) async {
    final String normalized = adminId.trim();
    if (normalized.isEmpty) {
      return;
    }

    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final QuerySnapshot<Map<String, dynamic>> salesSnapshot = await db
          .collection('sales')
          .where('adminId', isEqualTo: normalized)
          .get();

      if (salesSnapshot.docs.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune vente à convertir en facture.')),
        );
        return;
      }

      int written = 0;
      WriteBatch batch = db.batch();
      int ops = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in salesSnapshot.docs) {
        final Map<String, dynamic> sale = doc.data();
        final String saleId = (sale['id'] ?? doc.id).toString();
        if (saleId.trim().isEmpty) {
          continue;
        }

        final DateTime saleDate = _asDateTime(sale['date']) ?? DateTime.now();
        final int quantity = (sale['quantity'] as num?)?.toInt() ?? 1;
        final double unitSalePrice =
            (sale['unitSalePrice'] as num?)?.toDouble() ?? 0;
        final double total = unitSalePrice * quantity;
        final double paid = (sale['paidAmount'] as num?)?.toDouble() ?? total;
        final bool isPending = paid < total;
        final String rawClient = (sale['client'] ?? '').toString().trim();
        final String clientName = rawClient.isEmpty
            ? 'Client comptant'
            : rawClient;
        final String invoiceNumber =
            'FAC-SALE-${saleId.length > 10 ? saleId.substring(0, 10) : saleId}';

        final DocumentReference<Map<String, dynamic>> invoiceRef = db
            .collection('invoices')
            .doc('sale_$saleId');

        batch.set(invoiceRef, <String, dynamic>{
          'adminId': normalized,
          'saleId': saleId,
          'invoiceNumber': invoiceNumber,
          'clientName': clientName,
          'clientPhone': null,
          'clientAddress': null,
          'total': total,
          'currency': 'GNF',
          'taxRate': 0,
          'notes': isPending
              ? 'Reste à payer: ${(total - paid).toStringAsFixed(0)} GNF'
              : 'Paiement complet.',
          'items': <Map<String, dynamic>>[
            <String, dynamic>{
              'name': (sale['productName'] ?? 'Produit').toString(),
              'quantity': quantity,
              'unitPrice': unitSalePrice,
            },
          ],
          'shop': <String, dynamic>{
            'name': 'AppliGestion Boutique',
            'address': 'Conakry, Guinée',
            'phone': '+224 6XX XX XX XX',
            'email': null,
            'logoAssetPath': null,
          },
          'paymentStatus': isPending ? 'pending' : 'paid',
          'createdAt': Timestamp.fromDate(saleDate),
          'dueAt': isPending
              ? Timestamp.fromDate(saleDate.add(const Duration(days: 30)))
              : null,
          'source': 'sales_backfill',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        ops += 1;
        written += 1;

        if (ops >= 350) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }

      if (ops > 0) {
        await batch.commit();
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _dbCheckFuture = _runDbCheck(normalized);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$written facture(s) générée(s) depuis les ventes.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backfill impossible: $error')));
    }
  }

  Widget _invoiceRow(_WebInvoiceRow row, AppSettingsProvider appSettings) {
    Color statusBg;
    Color statusFg;
    String statusLabel;
    switch (row.status) {
      case _InvoiceStatus.paid:
        statusBg = const Color(0xFFECFDF3);
        statusFg = const Color(0xFF047857);
        statusLabel = 'PAYÉE';
        break;
      case _InvoiceStatus.pending:
        statusBg = const Color(0xFFFFF7ED);
        statusFg = const Color(0xFFB45309);
        statusLabel = 'EN ATTENTE';
        break;
      case _InvoiceStatus.late:
        statusBg = const Color(0xFFFEF2F2);
        statusFg = const Color(0xFFB91C1C);
        statusLabel = 'EN RETARD';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              row.number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.client,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF334155)),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd MMM yyyy', 'fr_FR').format(row.date),
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd MMM yyyy', 'fr_FR').format(row.dueAt),
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          Expanded(
            child: Text(
              appSettings.formatMoney(row.amount, decimals: 0),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: statusFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 54,
            child: IconButton(
              tooltip: 'Prévisualiser',
              onPressed: () => _previewInvoice(row),
              icon: const Icon(Icons.visibility_rounded),
              color: const Color(0xFF4F46E5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _previewInvoice(_WebInvoiceRow row) async {
    final List<dynamic>? itemsRaw = row.data['items'] as List<dynamic>?;
    final Map<String, dynamic>? shopRaw =
        row.data['shop'] as Map<String, dynamic>?;

    if (itemsRaw == null || itemsRaw.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cette facture ne contient pas encore les détails nécessaires à la prévisualisation.',
          ),
        ),
      );
      return;
    }

    final List<ProductModel> items = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> item) => ProductModel(
            name: (item['name'] ?? '').toString(),
            quantity: (item['quantity'] as num?)?.toInt() ?? 0,
            unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((ProductModel item) => item.name.trim().isNotEmpty)
        .toList();

    if (items.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de reconstruire la facture pour la prévisualisation.',
          ),
        ),
      );
      return;
    }

    final InvoiceModel invoice = InvoiceModel(
      shop: ShopInfo(
        name: (shopRaw?['name'] ?? 'AppliGestion Boutique').toString(),
        address: (shopRaw?['address'] ?? 'Conakry, Guinée').toString(),
        phone: (shopRaw?['phone'] ?? '+224 6XX XX XX XX').toString(),
        email: shopRaw?['email']?.toString(),
        logoAssetPath: shopRaw?['logoAssetPath']?.toString(),
      ),
      items: items,
      createdAt: row.date,
      invoiceNumber: row.number,
      clientName: row.client,
      clientPhone: (row.data['clientPhone'] ?? '').toString().trim().isEmpty
          ? null
          : row.data['clientPhone'].toString(),
      clientAddress: (row.data['clientAddress'] ?? '').toString().trim().isEmpty
          ? null
          : row.data['clientAddress'].toString(),
      notes: (row.data['notes'] ?? '').toString().trim().isEmpty
          ? null
          : row.data['notes'].toString(),
      dueAt: row.dueAt,
      currency: (row.data['currency'] ?? 'GNF').toString(),
      taxRate: (row.data['taxRate'] as num?)?.toDouble() ?? 0,
    );

    await _invoiceService.previewInvoice(
      context,
      invoice,
      format: InvoicePaperFormat.a4,
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class _InvoiceTopCard extends StatelessWidget {
  const _InvoiceTopCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebInvoiceRow {
  const _WebInvoiceRow({
    required this.id,
    required this.number,
    required this.client,
    required this.date,
    required this.dueAt,
    required this.amount,
    required this.status,
    required this.data,
  });

  final String id;
  final String number;
  final String client;
  final DateTime date;
  final DateTime dueAt;
  final double amount;
  final _InvoiceStatus status;
  final Map<String, dynamic> data;
}

enum _InvoiceStatus { paid, pending, late }

class _DbCheckResult {
  const _DbCheckResult({
    required this.adminId,
    required this.salesCount,
    required this.invoicesCount,
  });

  final String adminId;
  final int salesCount;
  final int invoicesCount;
}
