import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../invoice/models/invoice_model.dart';
import '../invoice/services/invoice_service.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const ShopInfo _shopInfo = ShopInfo(
    name: 'AppliGestion Boutique',
    address: 'Conakry, Guinee',
    phone: '+224 6XX XX XX XX',
  );

  final InvoiceService _invoiceService = const InvoiceService();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, int> _cart = <String, int>{};

  String _search = '';
  String _category = 'Tous';
  String? _selectedClientId;
  bool _pendingMode = false;
  bool _submitting = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1360;
    if (isDesktop) {
      return _buildDesktopPos(context);
    }

    return _buildMobileHistory(context);
  }

  Widget _buildDesktopPos(BuildContext context) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final ProductsProvider productsProvider = context.watch<ProductsProvider>();
    final ClientsProvider clientsProvider = context.watch<ClientsProvider>();
    final SalesProvider salesProvider = context.watch<SalesProvider>();

    final List<String> categories = <String>{
      'Tous',
      ...productsProvider.products.map((Product p) => p.category),
    }.toList();

    final List<Product> catalog = productsProvider.products.where((Product p) {
      final bool queryOk =
          _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.category.toLowerCase().contains(_search.toLowerCase());
      final bool categoryOk = _category == 'Tous' || p.category == _category;
      return queryOk && categoryOk;
    }).toList();

    final List<({Product product, int qty})> cartLines = _cart.entries
        .map((MapEntry<String, int> entry) {
          final Product? product = productsProvider.byId(entry.key);
          if (product == null || entry.value <= 0) {
            return null;
          }
          return (product: product, qty: entry.value);
        })
        .whereType<({Product product, int qty})>()
        .toList();

    final double subTotal = cartLines.fold<double>(
      0,
      (double sum, ({Product product, int qty}) line) =>
          sum + (line.product.salePrice * line.qty),
    );
    final double vat = subTotal * 0.2;
    final double vipDiscount = _selectedClientId == null ? 0 : subTotal * 0.05;
    final double totalToPay = (subTotal + vat - vipDiscount).clamp(
      0,
      double.infinity,
    );

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compactDesktop =
              constraints.maxWidth < 1520 || constraints.maxHeight < 860;

          return Container(
            color: const Color(0xFFF3F4F7),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: compactDesktop ? 11 : 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 6, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Catalogue Produits',
                          style: TextStyle(
                            fontSize: compactDesktop ? 34 : 40,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sélectionnez les articles pour la vente en cours.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF2F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (String value) {
                              setState(() {
                                _search = value;
                              });
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Rechercher un produit ou scanner...',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((String category) {
                              final bool selected = category == _category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() {
                                      _category = category;
                                    });
                                  },
                                  selectedColor: const Color(0xFFFF7315),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: catalog.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucun produit dans ce filtre.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                )
                              : GridView.builder(
                                  itemCount: catalog.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: compactDesktop ? 3 : 4,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: compactDesktop
                                            ? 0.78
                                            : 0.74,
                                      ),
                                  itemBuilder: (BuildContext context, int index) {
                                    final Product product = catalog[index];
                                    final int qtyInCart =
                                        _cart[product.id] ?? 0;
                                    return _PosProductCard(
                                      product: product,
                                      qtyInCart: qtyInCart,
                                      onAdd: () {
                                        if (product.stock <= qtyInCart) {
                                          _showSnack(
                                            'Stock insuffisant pour ${product.name}.',
                                          );
                                          return;
                                        }
                                        setState(() {
                                          _cart[product.id] = qtyInCart + 1;
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: compactDesktop ? 9 : 2,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 8, 8, 120),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8ECF3)),
                    ),
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints panel) {
                        final bool compactPanel =
                            panel.maxWidth < 470 || panel.maxHeight < 760;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Panier Actuel',
                              style: TextStyle(
                                color: const Color(0xFF111827),
                                fontSize: compactPanel ? 26 : 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: compactPanel ? 8 : 10),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedClientId,
                              decoration: const InputDecoration(
                                labelText: 'Client (optionnel)',
                              ),
                              items: <DropdownMenuItem<String>>[
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Client comptant'),
                                ),
                                ...clientsProvider.clients.map(
                                  (Client client) => DropdownMenuItem<String>(
                                    value: client.id,
                                    child: Text(
                                      '${client.name} (${client.phone})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedClientId = value;
                                });
                              },
                            ),
                            SizedBox(height: compactPanel ? 8 : 10),
                            Expanded(
                              child: cartLines.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Ajoutez des produits au panier.',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: cartLines.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                            final ({Product product, int qty})
                                            line = cartLines[index];
                                            return _PosCartLine(
                                              product: line.product,
                                              quantity: line.qty,
                                              onDecrease: () {
                                                setState(() {
                                                  final int next = line.qty - 1;
                                                  if (next <= 0) {
                                                    _cart.remove(
                                                      line.product.id,
                                                    );
                                                  } else {
                                                    _cart[line.product.id] =
                                                        next;
                                                  }
                                                });
                                              },
                                              onIncrease: () {
                                                if (line.qty >=
                                                    line.product.stock) {
                                                  _showSnack(
                                                    'Stock maximum atteint pour ${line.product.name}.',
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  _cart[line.product.id] =
                                                      line.qty + 1;
                                                });
                                              },
                                              onRemove: () {
                                                setState(() {
                                                  _cart.remove(line.product.id);
                                                });
                                              },
                                            );
                                          },
                                    ),
                            ),
                            const Divider(height: 20),
                            _totalLine(context, 'Sous-total', subTotal),
                            _totalLine(context, 'TVA (18%)', vat),
                            _totalLine(
                              context,
                              'Remise VIP (5%)',
                              -vipDiscount,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Total à payer',
                                    style: TextStyle(
                                      color: const Color(0xFF111827),
                                      fontSize: compactPanel ? 22 : 26,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      appSettings.formatMoney(
                                        totalToPay,
                                        decimals: 0,
                                      ),
                                      style: TextStyle(
                                        color: const Color(0xFFB45309),
                                        fontSize: compactPanel ? 32 : 38,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: compactPanel ? 8 : 12),
                            if (compactPanel) ...<Widget>[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: cartLines.isEmpty
                                      ? null
                                      : () {
                                          _showSnack(
                                            'Impression ticket disponible depuis les actions facture.',
                                          );
                                        },
                                  icon: const Icon(Icons.print_rounded),
                                  label: const Text('Ticket'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: cartLines.isEmpty
                                      ? null
                                      : () {
                                          setState(() {
                                            _pendingMode = !_pendingMode;
                                          });
                                        },
                                  icon: Icon(
                                    _pendingMode
                                        ? Icons.pause_circle_rounded
                                        : Icons.pause_circle_outline_rounded,
                                  ),
                                  label: Text(
                                    _pendingMode
                                        ? 'En attente'
                                        : 'Paiement comptant',
                                  ),
                                ),
                              ),
                            ] else ...<Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: cartLines.isEmpty
                                          ? null
                                          : () {
                                              _showSnack(
                                                'Impression ticket disponible depuis les actions facture.',
                                              );
                                            },
                                      icon: const Icon(Icons.print_rounded),
                                      label: const Text('Ticket'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: cartLines.isEmpty
                                          ? null
                                          : () {
                                              setState(() {
                                                _pendingMode = !_pendingMode;
                                              });
                                            },
                                      icon: Icon(
                                        _pendingMode
                                            ? Icons.pause_circle_rounded
                                            : Icons
                                                  .pause_circle_outline_rounded,
                                      ),
                                      label: Text(
                                        _pendingMode
                                            ? 'En attente'
                                            : 'Paiement comptant',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: (_submitting || cartLines.isEmpty)
                                    ? null
                                    : () => _submitDesktopSale(
                                        productsProvider: productsProvider,
                                        clientsProvider: clientsProvider,
                                        salesProvider: salesProvider,
                                        cartLines: cartLines,
                                      ),
                                icon: const Icon(Icons.point_of_sale_rounded),
                                label: Text(
                                  _submitting
                                      ? 'Enregistrement...'
                                      : 'Enregistrer la vente',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7315),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitDesktopSale({
    required ProductsProvider productsProvider,
    required ClientsProvider clientsProvider,
    required SalesProvider salesProvider,
    required List<({Product product, int qty})> cartLines,
  }) async {
    if (cartLines.isEmpty) {
      _showSnack('Panier vide.');
      return;
    }

    if (_pendingMode &&
        (_selectedClientId == null || _selectedClientId!.isEmpty)) {
      _showSnack('Choisissez un client pour la vente en attente.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    final Client? selectedClient = _selectedClientId == null
        ? null
        : clientsProvider.byId(_selectedClientId!);

    final String clientName = (selectedClient?.name ?? '').trim().isEmpty
        ? 'Client comptant'
        : selectedClient!.name;

    try {
      for (final ({Product product, int qty}) line in cartLines) {
        final double lineTotal = line.product.salePrice * line.qty;
        final bool ok = await salesProvider.registerSale(
          productsProvider: productsProvider,
          clientsProvider: clientsProvider,
          productId: line.product.id,
          quantity: line.qty,
          clientId: _pendingMode ? _selectedClientId : null,
          clientName: _pendingMode ? clientName : 'Client comptant',
          paidAmount: _pendingMode ? 0 : lineTotal,
        );

        if (!ok) {
          _showSnack(
            'Impossible d\'enregistrer la vente pour ${line.product.name}.',
          );
          return;
        }
      }

      final double totalAmount = cartLines.fold<double>(
        0,
        (double sum, ({Product product, int qty}) line) =>
            sum + (line.product.salePrice * line.qty),
      );
      final double paidAmount = _pendingMode ? 0 : totalAmount;
      final double creditAmount = (totalAmount - paidAmount).clamp(
        0,
        double.infinity,
      );
      final String effectiveClientName = _pendingMode
          ? clientName
          : 'Client comptant';

      final InvoiceModel invoice = InvoiceModel(
        shop: _shopInfo,
        invoiceNumber: _invoiceService.buildInvoiceNumber(),
        createdAt: DateTime.now(),
        clientName: effectiveClientName,
        clientPhone: selectedClient?.phone,
        items: cartLines
            .map(
              (({Product product, int qty}) line) => InvoiceItem(
                name: line.product.name,
                quantity: line.qty,
                unitPrice: line.product.salePrice,
              ),
            )
            .toList(),
        taxRate: 0,
        notes: creditAmount > 0
            ? 'Reste a payer: ${totalAmount.toStringAsFixed(0)} GNF'
            : 'Paiement complet.',
        dueAt: creditAmount > 0
            ? DateTime.now().add(const Duration(days: 30))
            : null,
      );

      try {
        await _persistInvoiceAfterSale(
          invoice: invoice,
          creditAmount: creditAmount,
        );
      } catch (error) {
        _showSnack(
          'Vente enregistree, mais facture non enregistree: ${error.toString().replaceFirst('Exception: ', '')}',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _cart.clear();
        _pendingMode = false;
      });
      _showSnack('Vente enregistrée avec succès.');

      await _openInvoicePreview(invoice);
    } catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _persistInvoiceAfterSale({
    required InvoiceModel invoice,
    required double creditAmount,
  }) async {
    final String? adminId =
        FirebaseAuth.instance.currentUser?.uid ??
        context.read<AuthProvider>().currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      return;
    }

    if (kIsWeb) {
      final String safeInvoiceNumber =
          (invoice.invoiceNumber ??
                  'FAC-${invoice.createdAt.millisecondsSinceEpoch}')
              .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final DocumentReference<Map<String, dynamic>> invoiceRef =
          FirebaseFirestore.instance
              .collection('invoices')
              .doc('${adminId}_$safeInvoiceNumber');

      Future<void> write() {
        return invoiceRef.set(<String, dynamic>{
          'adminId': adminId,
          'invoiceNumber': invoice.invoiceNumber,
          'clientName': invoice.clientName,
          'clientPhone': invoice.clientPhone,
          'clientAddress': invoice.clientAddress,
          'total': invoice.grandTotal,
          'currency': invoice.currency,
          'taxRate': invoice.taxRate,
          'notes': invoice.notes,
          'items': invoice.items
              .map(
                (InvoiceItem item) => <String, dynamic>{
                  'name': item.name,
                  'quantity': item.quantity,
                  'unitPrice': item.unitPrice,
                },
              )
              .toList(),
          'shop': <String, dynamic>{
            'name': invoice.shop.name,
            'address': invoice.shop.address,
            'phone': invoice.shop.phone,
            'email': invoice.shop.email,
            'logoAssetPath': invoice.shop.logoAssetPath,
          },
          'paymentStatus': creditAmount > 0 ? 'pending' : 'paid',
          'createdAt': Timestamp.fromDate(invoice.createdAt),
          'dueAt': invoice.dueAt != null
              ? Timestamp.fromDate(invoice.dueAt!)
              : null,
          'source': 'sales_screen_checkout',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      try {
        await write();
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied' &&
            error.code != 'unauthenticated') {
          rethrow;
        }
        final User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          rethrow;
        }
        await user.getIdToken(true);
        await user.reload();
        await write();
      }
      return;
    }

    await _invoiceService.saveInvoice(
      invoice,
      adminId: adminId,
      format: InvoicePaperFormat.ticket80mm,
      preferDownloads: true,
    );
  }

  Future<void> _openInvoicePreview(InvoiceModel invoice) async {
    if (!mounted) {
      return;
    }

    try {
      await _invoiceService.previewInvoice(
        context,
        invoice,
        format: InvoicePaperFormat.ticket80mm,
      );
    } catch (error) {
      _showSnack(
        'Impossible d\'ouvrir la facture: ${error.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _totalLine(BuildContext context, String label, double value) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final bool negative = value < 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${negative ? '-' : ''}${appSettings.formatMoney(value.abs(), decimals: 0)}',
            style: TextStyle(
              color: negative
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHistory(BuildContext context) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;
    final SalesProvider salesProvider = context.watch<SalesProvider>();
    final List<Sale> sales = salesProvider.sales;
    final double totalSalesAmount = sales.fold<double>(
      0,
      (double sum, Sale sale) => sum + sale.amount,
    );
    final double totalCreditAmount = sales.fold<double>(
      0,
      (double sum, Sale sale) => sum + sale.creditAmount,
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 20,
          16,
          isCompact ? 16 : 20,
          120,
        ),
        children: <Widget>[
          Text(
            'Ventes',
            style: TextStyle(
              fontSize: isCompact ? 24 : 28,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
          const SizedBox(height: 4),
          Text(
            'Historique de vos transactions',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _summaryTile(
                  title: 'Total ventes',
                  value: appSettings.formatMoney(totalSalesAmount, decimals: 0),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  title: 'Crédit restant',
                  value: appSettings.formatMoney(
                    totalCreditAmount,
                    decimals: 0,
                  ),
                  icon: Icons.credit_card_rounded,
                  color: const Color(0xFFB91C1C),
                ),
              ),
            ],
          ).animate(delay: 150.ms).fadeIn(),
          const SizedBox(height: 24),
          if (sales.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Aucune vente enregistrée.',
                  style: const TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
            ).animate(delay: 200.ms).fadeIn()
          else
            ...sales.reversed.toList().asMap().entries.map(
              (MapEntry<int, Sale> entry) =>
                  _saleTile(context, entry.value, entry.key),
            ),
        ],
      ),
    );
  }

  Widget _saleTile(BuildContext context, Sale sale, int index) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final bool isFullCredit = sale.paidAmount == 0;
    final bool isPartialCredit = sale.isCredit && sale.paidAmount > 0;

    Color statusColor;
    Color statusBgColor;
    String statusText;

    if (isFullCredit) {
      statusColor = const Color(0xFFEF4444); // Red
      statusBgColor = const Color(0xFFFEF2F2);
      statusText = 'Crédit total';
    } else if (isPartialCredit) {
      statusColor = const Color(0xFFF59E0B); // Amber
      statusBgColor = const Color(0xFFFFFBEB);
      statusText = 'Crédit partiel';
    } else {
      statusColor = const Color(0xFF10B981); // Emerald
      statusBgColor = const Color(0xFFECFDF5);
      statusText = 'Payé';
    }

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        sale.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qté: ${sale.quantity} • ${appSettings.formatDateTime(sale.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      if (sale.client != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sale.client!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      appSettings.formatMoney(sale.amount, decimals: 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate(delay: (200 + (index * 50)).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosProductCard extends StatelessWidget {
  const _PosProductCard({
    required this.product,
    required this.qtyInCart,
    required this.onAdd,
  });

  final Product product;
  final int qtyInCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final bool low = product.isLowStock || product.stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child:
                          (product.imageUrl != null &&
                              product.imageUrl!.trim().isNotEmpty)
                          ? Image.network(
                              product.imageUrl!.trim(),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return Container(
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    );
                                  },
                            )
                          : Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: low ? const Color(0xFFFEE2E2) : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'STOCK: ${product.stock}',
                        style: TextStyle(
                          color: low
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFFB45309),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.category.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                letterSpacing: 0.9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    appSettings.formatMoney(product.salePrice, decimals: 2),
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7315),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (qtyInCart > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Dans panier: $qtyInCart',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PosCartLine extends StatelessWidget {
  const _PosCartLine({
    required this.product,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final double lineTotal = product.salePrice * quantity;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  appSettings.formatMoney(lineTotal, decimals: 0),
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            color: const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }
}
