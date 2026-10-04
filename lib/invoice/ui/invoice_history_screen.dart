import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/invoice_history_entry.dart';
import '../models/invoice_model.dart';
import '../services/invoice_history_service.dart';
import '../services/invoice_service.dart';
import '../../providers/auth_provider.dart';

enum _InvoiceFilter { all, paid, pending, late }

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final InvoiceService _invoiceService = const InvoiceService();

  late Future<List<InvoiceHistoryEntry>> _future;
  _InvoiceFilter _filter = _InvoiceFilter.all;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<InvoiceHistoryEntry>> _load() async {
    final String? adminId = context.read<AuthProvider>().currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      return <InvoiceHistoryEntry>[];
    }

    final InvoiceHistoryService historyService = InvoiceHistoryService(
      adminId: adminId,
    );
    await historyService.removeMissingFiles();
    return historyService.getHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<InvoiceHistoryEntry>>(
          future: _future,
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<InvoiceHistoryEntry>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<InvoiceHistoryEntry> entries =
                    snapshot.data ?? <InvoiceHistoryEntry>[];
                final List<InvoiceHistoryEntry> filtered = _applyFilter(
                  entries,
                );
                final List<InvoiceHistoryEntry> visible = _applySearch(
                  filtered,
                );

                if (entries.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    children: const <Widget>[
                      Text(
                        'Historique des factures',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aucune facture enregistrée pour le moment.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  children: <Widget>[
                    const SizedBox(height: 4),
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
                      'Vue d\'ensemble • ${_currentQuarterLabel()}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildFilters(entries),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (String value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher client ou facture...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF7315),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${visible.length} facture(s) affichée(s)',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (visible.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text(
                          'Aucune facture pour ce filtre.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ...visible.map(
                      (InvoiceHistoryEntry entry) => _HistoryTile(
                        entry: entry,
                        onPreview: () => _preview(entry),
                        onPrint: () => _print(entry),
                        onShare: () => _share(entry),
                        onDelete: () => _delete(entry),
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  List<InvoiceHistoryEntry> _applyFilter(List<InvoiceHistoryEntry> source) {
    final List<InvoiceHistoryEntry> sorted =
        List<InvoiceHistoryEntry>.from(source)..sort(
          (InvoiceHistoryEntry a, InvoiceHistoryEntry b) =>
              b.createdAt.compareTo(a.createdAt),
        );

    if (_filter == _InvoiceFilter.all) {
      return sorted;
    }

    return sorted.where((InvoiceHistoryEntry entry) {
      switch (_filter) {
        case _InvoiceFilter.paid:
          return entry.currentStatus == InvoicePaymentStatus.paid;
        case _InvoiceFilter.pending:
          return entry.currentStatus == InvoicePaymentStatus.pending;
        case _InvoiceFilter.late:
          return entry.currentStatus == InvoicePaymentStatus.late;
        case _InvoiceFilter.all:
          return true;
      }
    }).toList();
  }

  List<InvoiceHistoryEntry> _applySearch(List<InvoiceHistoryEntry> source) {
    final String query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }

    return source.where((InvoiceHistoryEntry entry) {
      return entry.invoiceNumber.toLowerCase().contains(query) ||
          (entry.clientName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildFilters(List<InvoiceHistoryEntry> entries) {
    int countFor(InvoicePaymentStatus status) {
      return entries
          .where((InvoiceHistoryEntry e) => e.currentStatus == status)
          .length;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _filterChip(
            label: 'Tout (${entries.length})',
            active: _filter == _InvoiceFilter.all,
            onTap: () => setState(() => _filter = _InvoiceFilter.all),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Payées (${countFor(InvoicePaymentStatus.paid)})',
            active: _filter == _InvoiceFilter.paid,
            onTap: () => setState(() => _filter = _InvoiceFilter.paid),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'En attente (${countFor(InvoicePaymentStatus.pending)})',
            active: _filter == _InvoiceFilter.pending,
            onTap: () => setState(() => _filter = _InvoiceFilter.pending),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'En retard (${countFor(InvoicePaymentStatus.late)})',
            active: _filter == _InvoiceFilter.late,
            onTap: () => setState(() => _filter = _InvoiceFilter.late),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _currentQuarterLabel() {
    final DateTime now = DateTime.now();
    final int q = ((now.month - 1) ~/ 3) + 1;
    return 'T$q ${now.year}';
  }

  Future<void> _preview(InvoiceHistoryEntry entry) async {
    final File file = File(entry.filePath);
    if (!await file.exists()) {
      await _delete(entry, silent: true);
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    await _invoiceService.previewPdfBytes(
      context,
      bytes: bytes,
      title: 'Prévisualisation ${entry.invoiceNumber}',
    );
  }

  Future<void> _print(InvoiceHistoryEntry entry) async {
    await _invoiceService.printSavedInvoice(entry);
  }

  Future<void> _share(InvoiceHistoryEntry entry) async {
    await _invoiceService.shareSavedInvoice(entry);
  }

  Future<void> _delete(InvoiceHistoryEntry entry, {bool silent = false}) async {
    final String? adminId = context.read<AuthProvider>().currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      return;
    }

    final InvoiceHistoryService historyService = InvoiceHistoryService(
      adminId: adminId,
    );
    await historyService.deleteById(entry.id);
    final File file = File(entry.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    if (mounted && !silent) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Facture supprimée.')));
    }

    await _refresh();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onPreview,
    required this.onPrint,
    required this.onShare,
    required this.onDelete,
  });

  final InvoiceHistoryEntry entry;
  final VoidCallback onPreview;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String dateText = DateFormat(
      'dd MMM yyyy',
      'fr_FR',
    ).format(entry.createdAt);
    final String? dueText = entry.dueAt == null
        ? null
        : DateFormat('dd MMM yyyy', 'fr_FR').format(entry.dueAt!);
    final NumberFormat moneyFormat = NumberFormat('#,##0', 'fr_FR');
    final String filename = _basename(entry.filePath);
    final InvoicePaymentStatus status = entry.currentStatus;
    final bool isPending = status == InvoicePaymentStatus.pending;
    final bool isLate = status == InvoicePaymentStatus.late;

    final String statusLabel;
    final Color statusBg;
    final Color statusFg;

    if (isLate) {
      statusLabel = 'En retard';
      statusBg = const Color(0xFFFFE4E6);
      statusFg = const Color(0xFFBE123C);
    } else if (isPending) {
      statusLabel = 'En attente';
      statusBg = const Color(0xFFFFF4E5);
      statusFg = const Color(0xFF9A3412);
    } else {
      statusLabel = 'Payée';
      statusBg = const Color(0xFFDCFCE7);
      statusFg = const Color(0xFF166534);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.clientName?.isNotEmpty == true
                            ? entry.clientName!
                            : 'Client comptant',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.invoiceNumber} • $dateText',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      if (dueText != null)
                        Text(
                          'Echeance: $dueText',
                          style: TextStyle(
                            color: isLate
                                ? const Color(0xFFBE123C)
                                : const Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: isLate
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String action) {
                    switch (action) {
                      case 'preview':
                        onPreview();
                        break;
                      case 'print':
                        onPrint();
                        break;
                      case 'share':
                        onShare();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'preview',
                          child: Text('Prévisualiser'),
                        ),
                        PopupMenuItem<String>(
                          value: 'print',
                          child: Text('Imprimer'),
                        ),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Text('Partager'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Supprimer'),
                        ),
                      ],
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusFg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    entry.format.label,
                    style: const TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Total: ${moneyFormat.format(entry.total)} ${entry.currency}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isPending || isLate
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onPreview,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEA580C),
                  side: const BorderSide(color: Color(0xFFF97316)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Voir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _basename(String input) {
    final List<String> segments = input.split(Platform.pathSeparator);
    if (segments.isEmpty) {
      return input;
    }
    return segments.last;
  }
}
