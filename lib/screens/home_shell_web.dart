import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../invoice/models/invoice_model.dart';
import '../invoice/services/invoice_service.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/suppliers_provider.dart';
import '../invoice/ui/invoice_history_screen_web.dart';
import 'admin_profile_screen.dart';
import 'admin_sidebar.dart';
import 'clients_screen.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'settings_screen.dart';
import 'suppliers_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const ShopInfo _shopInfo = ShopInfo(
    name: 'AppliGestion Boutique',
    address: 'Conakry, Guinée',
    phone: '+224 6XX XX XX XX',
  );

  final InvoiceService _invoiceService = const InvoiceService();
  final TextEditingController _desktopSearchCtrl = TextEditingController();
  Timer? _desktopSearchDebounce;

  int _index = 0;

  @override
  void dispose() {
    _desktopSearchDebounce?.cancel();
    _desktopSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveWebInvoiceRecord({
    required String adminId,
    required InvoiceModel invoice,
    required double creditAmount,
  }) async {
    final String safeInvoiceNumber =
        (invoice.invoiceNumber ??
                'FAC-${invoice.createdAt.millisecondsSinceEpoch}')
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final DocumentReference<Map<String, dynamic>> invoiceRef = FirebaseFirestore
        .instance
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
        'source': 'sale_checkout_web',
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
  }

  void _handleDesktopSearch(String rawQuery, {bool showNoMatch = true}) {
    final String query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return;
    }

    final Map<int, List<String>> aliases = <int, List<String>>{
      0: <String>['dashboard', 'tableau', 'accueil'],
      1: <String>['produit', 'produits', 'stock', 'inventaire'],
      2: <String>['vente', 'ventes', 'caisse', 'pos'],
      3: <String>['depense', 'depenses', 'charges', 'finance'],
      4: <String>['fournisseur', 'fournisseurs', 'supplier'],
      5: <String>['client', 'clients', 'crm'],
      6: <String>['facture', 'factures', 'invoice'],
      7: <String>['profil', 'profile', 'compte'],
      8: <String>['parametre', 'parametres', 'settings', 'configuration'],
    };

    int? targetIndex;
    for (final MapEntry<int, List<String>> entry in aliases.entries) {
      final bool hit = entry.value.any(
        (String alias) => alias.contains(query) || query.contains(alias),
      );
      if (hit) {
        targetIndex = entry.key;
        break;
      }
    }

    if (targetIndex == null) {
      if (!showNoMatch) {
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun onglet correspondant.')),
      );
      return;
    }

    setState(() {
      _index = targetIndex!;
    });
  }

  void _onDesktopSearchChanged(String value) {
    _desktopSearchDebounce?.cancel();
    _desktopSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      _handleDesktopSearch(value, showNoMatch: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktop = screenWidth >= 1024;
    final bool isTabletOrLarger = screenWidth >= 600;
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final String adminName = authProvider.currentAdminDisplayName;
    final String? adminEmail = authProvider.user?.email;

    final List<Widget> pages = <Widget>[
      const DashboardScreen(),
      const ProductsScreen(),
      const SalesScreen(),
      const ExpensesScreen(),
      SuppliersScreen(onAddSupplierPressed: _showAddSupplierSheet),
      const ClientsScreen(),
      const InvoiceHistoryScreenWeb(),
      const AdminProfileScreen(),
      SettingsScreen(
        onOpenProfile: () {
          setState(() {
            _index = 7;
          });
        },
      ),
    ];

    final List<String> pageTitles = <String>[
      l10n?.pageDashboard ?? 'Tableau de bord',
      l10n?.pageProducts ?? 'Produits',
      l10n?.pageSales ?? 'Ventes',
      l10n?.pageExpenses ?? 'Depenses',
      'Fournisseurs',
      l10n?.pageClients ?? 'Clients',
      l10n?.pageInvoices ?? 'Factures',
      l10n?.pageAdminProfile ?? 'Profil admin',
      l10n?.pageSettings ?? 'Parametres',
    ];

    final List<AdminSidebarItem> sidebarItems =
        <(String, IconData, IconData)>[
              (
                l10n?.navDashboard ?? 'Tableau',
                Icons.dashboard_outlined,
                Icons.dashboard_rounded,
              ),
              (
                l10n?.navProducts ?? 'Produits',
                Icons.inventory_2_outlined,
                Icons.inventory_2_rounded,
              ),
              (
                l10n?.navSales ?? 'Ventes',
                Icons.point_of_sale_outlined,
                Icons.point_of_sale_rounded,
              ),
              (
                l10n?.navExpenses ?? 'Depenses',
                Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet_rounded,
              ),
              (
                'Fournisseurs',
                Icons.local_shipping_outlined,
                Icons.local_shipping_rounded,
              ),
              (
                l10n?.navClients ?? 'Clients',
                Icons.people_alt_outlined,
                Icons.people_alt_rounded,
              ),
              (
                l10n?.navInvoices ?? 'Factures',
                Icons.receipt_long_outlined,
                Icons.receipt_long_rounded,
              ),
              (
                l10n?.navProfile ?? 'Profil',
                Icons.person_outline,
                Icons.person_rounded,
              ),
              (
                l10n?.navSettings ?? 'Parametres',
                Icons.settings_outlined,
                Icons.settings_rounded,
              ),
            ]
            .map(
              (item) => AdminSidebarItem(
                label: item.$1,
                icon: item.$2,
                selectedIcon: item.$3,
              ),
            )
            .toList();

    final Widget sidebar = AdminSidebar(
      items: sidebarItems,
      selectedIndex: _index,
      primaryItemCount: 7,
      onSelected: (int index) {
        setState(() {
          _index = index;
        });
      },
      onLogout: () async {
        await context.read<AuthProvider>().signOut();
      },
      adminName: adminName,
      adminEmail: adminEmail,
    );

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(pageTitles[_index]),
              centerTitle: false,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              automaticallyImplyLeading: !isTabletOrLarger,
            ),
      drawer: isTabletOrLarger
          ? null
          : Drawer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: sidebar,
                ),
              ),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: isDesktop
            ? Container(
                color: const Color(0xFFF3F4F7),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 280, child: sidebar),
                    Expanded(
                      child: SafeArea(
                        child: Column(
                          children: <Widget>[
                            _buildDesktopTopBar(
                              title: pageTitles[_index],
                              adminName: adminName,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  18,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: KeyedSubtree(
                                    key: ValueKey<int>(_index),
                                    child: pages[_index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : KeyedSubtree(key: ValueKey<int>(_index), child: pages[_index]),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildDesktopTopBar({
    required String title,
    required String? adminName,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TextField(
                controller: _desktopSearchCtrl,
                textInputAction: TextInputAction.search,
                onChanged: _onDesktopSearchChanged,
                onSubmitted: (String value) {
                  _handleDesktopSearch(value, showNoMatch: true);
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Rechercher un onglet...',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            color: const Color(0xFF64748B),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _index = 8;
              });
            },
            icon: const Icon(Icons.settings_rounded),
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _index = 7;
              });
            },
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFFF7315),
              child: Text(
                (adminName ?? 'A').trim().isEmpty
                    ? 'A'
                    : (adminName ?? 'A').trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    if (_index == 0) {
      return null;
    }

    if (_index == 1) {
      return FloatingActionButton.extended(
        onPressed: _showAddProductSheet,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.fabProduct ?? 'Produit'),
      );
    }

    if (_index == 2) {
      return FloatingActionButton.extended(
        onPressed: _showAddSaleSheet,
        icon: const Icon(Icons.sell_outlined),
        label: Text(AppLocalizations.of(context)?.fabSale ?? 'Vente'),
      );
    }

    if (_index == 3) {
      return FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.note_add_outlined),
        label: Text(AppLocalizations.of(context)?.fabExpense ?? 'Depense'),
      );
    }

    if (_index == 4) {
      return FloatingActionButton.extended(
        onPressed: _showAddSupplierSheet,
        icon: const Icon(Icons.local_shipping_rounded),
        label: const Text('Fournisseur'),
      );
    }

    if (_index == 5) {
      return FloatingActionButton.extended(
        onPressed: _showAddClientSheet,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(AppLocalizations.of(context)?.fabClient ?? 'Client'),
      );
    }

    if (_index == 7) {
      return null;
    }

    return null;
  }

  Future<void> _showAddSupplierSheet() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController categoryCtrl = TextEditingController();
    final TextEditingController debtCtrl = TextEditingController(text: '0');
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        Widget buildInputGroup(String label, Widget child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          );
        }

        Widget buildTextField(
          TextEditingController controller, {
          bool isNumber = false,
        }) {
          return TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE5E7EB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7315),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'NOUVEAU FOURNISSEUR',
                          style: TextStyle(
                            color: Color(0xFFFF7315),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        buildInputGroup(
                          'NOM FOURNISSEUR *',
                          buildTextField(nameCtrl),
                        ),
                        const SizedBox(height: 16),
                        buildInputGroup(
                          'CATÉGORIE *',
                          buildTextField(categoryCtrl),
                        ),
                        const SizedBox(height: 16),
                        buildInputGroup(
                          'DETTE ACTUELLE *',
                          buildTextField(debtCtrl, isNumber: true),
                        ),
                        const SizedBox(height: 16),
                        buildInputGroup(
                          'TÉLÉPHONE (OPTIONNEL)',
                          buildTextField(phoneCtrl),
                        ),
                        const SizedBox(height: 16),
                        buildInputGroup(
                          'EMAIL (OPTIONNEL)',
                          buildTextField(emailCtrl),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final String name = nameCtrl.text.trim();
                        final String category = categoryCtrl.text.trim();
                        final double? debt = double.tryParse(
                          debtCtrl.text.trim(),
                        );

                        if (name.isEmpty ||
                            category.isEmpty ||
                            debt == null ||
                            debt < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Saisissez un nom, une catégorie et une dette valide.',
                              ),
                            ),
                          );
                          return;
                        }

                        context.read<SuppliersProvider>().addSupplier(
                          name: name,
                          category: category,
                          currentDebt: debt,
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Créer le fournisseur'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddProductSheet() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController purchaseCtrl = TextEditingController();
    final TextEditingController saleCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController(text: '0');
    final TextEditingController alertCtrl = TextEditingController(text: '5');
    String category = '-- Sans Catégorie --';
    String supplier = '-- Sans Fournisseur --';

    final List<String> supplierNames = <String>['-- Sans Fournisseur --'];
    if (context.mounted) {
      final suppliers = context.read<SuppliersProvider>().suppliers;
      supplierNames.addAll(suppliers.map((s) => s.name));
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                Widget buildInputGroup(String label, Widget child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      child,
                    ],
                  );
                }

                Widget buildTextField(
                  TextEditingController controller, {
                  bool isNumber = false,
                  TextStyle? textStyle,
                }) {
                  return TextField(
                    controller: controller,
                    keyboardType: isNumber
                        ? TextInputType.number
                        : TextInputType.text,
                    style:
                        textStyle ??
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE5E7EB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  );
                }

                Widget buildDropdownField({
                  required String value,
                  required List<String> items,
                  required ValueChanged<String?> onChanged,
                }) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6B7280),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        items: items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
                    ),
                  );
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.all(24),
                  child: Container(
                    width: 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7315),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'NOUVEAU PRODUIT',
                                  style: TextStyle(
                                    color: Color(0xFFFF7315),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                buildInputGroup(
                                  "DÉSIGNATION DE L'ARTICLE *",
                                  buildTextField(nameCtrl),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: buildInputGroup(
                                        'CATÉGORIE',
                                        buildDropdownField(
                                          value: category,
                                          items: const <String>[
                                            '-- Sans Catégorie --',
                                            'Alimentation',
                                            'Télécom',
                                            'Hygiène',
                                            'Divers',
                                          ],
                                          onChanged: (String? val) {
                                            if (val != null) {
                                              setModalState(
                                                () => category = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: buildInputGroup(
                                        'FOURNISSEUR',
                                        buildDropdownField(
                                          value: supplier,
                                          items: supplierNames,
                                          onChanged: (String? val) {
                                            if (val != null) {
                                              setModalState(
                                                () => supplier = val,
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: buildInputGroup(
                                        "PRIX D'ACHAT (GNF) *",
                                        buildTextField(
                                          purchaseCtrl,
                                          isNumber: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: buildInputGroup(
                                        'PRIX DE VENTE (GNF) *',
                                        buildTextField(
                                          saleCtrl,
                                          isNumber: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: buildInputGroup(
                                        'STOCK INITIAL',
                                        buildTextField(
                                          stockCtrl,
                                          isNumber: true,
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: buildInputGroup(
                                        'SEUIL ALERTE',
                                        buildTextField(
                                          alertCtrl,
                                          isNumber: true,
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFDC2626),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF1F5F9,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF475569,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'ANNULER',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: FilledButton(
                                        onPressed: () async {
                                          final String name = nameCtrl.text
                                              .trim();
                                          final double? purchase =
                                              double.tryParse(
                                                purchaseCtrl.text.trim(),
                                              );
                                          final double? sale = double.tryParse(
                                            saleCtrl.text.trim(),
                                          );
                                          final int? stock = int.tryParse(
                                            stockCtrl.text.trim(),
                                          );
                                          final int? alert = int.tryParse(
                                            alertCtrl.text.trim(),
                                          );

                                          if (name.isEmpty ||
                                              purchase == null ||
                                              sale == null ||
                                              stock == null ||
                                              alert == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Veuillez remplir tous les champs correctement.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final String finalCat =
                                              category == '-- Sans Catégorie --'
                                              ? 'Divers'
                                              : category;

                                          try {
                                            await context
                                                .read<ProductsProvider>()
                                                .addProduct(
                                                  Product(
                                                    id: 'p-${DateTime.now().microsecondsSinceEpoch}',
                                                    adminId:
                                                        context
                                                            .read<
                                                              AuthProvider
                                                            >()
                                                            .currentAdminId ??
                                                        '',
                                                    name: name,
                                                    category: finalCat,
                                                    purchasePrice: purchase,
                                                    salePrice: sale,
                                                    stock: stock,
                                                    alertThreshold: alert,
                                                    supplier: supplier,
                                                  ),
                                                );
                                          } catch (error) {
                                            if (!context.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  error.toString().replaceFirst(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF7315,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          "ENREGISTRER L'ARTICLE",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showAddSaleSheet() async {
    final productsProvider = context.read<ProductsProvider>();
    final clientsProvider = context.read<ClientsProvider>();
    final salesProvider = context.read<SalesProvider>();
    final AppSettingsProvider appSettings = context.read<AppSettingsProvider>();

    if (productsProvider.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez un produit avant d\'enregistrer une vente.'),
        ),
      );
      return;
    }

    String selectedProductId = productsProvider.products.first.id;
    final TextEditingController quantityCtrl = TextEditingController(text: '1');
    final TextEditingController clientCtrl = TextEditingController();
    final TextEditingController paidCtrl = TextEditingController();
    final List<
      ({String productId, String productName, int quantity, double unitPrice})
    >
    cartItems =
        <
          ({
            String productId,
            String productName,
            int quantity,
            double unitPrice,
          })
        >[];
    String? selectedClientId;
    String paymentMode = 'comptant';
    DateTime? creditDueDate;

    List<
      ({String productId, String productName, int quantity, double unitPrice})
    >
    mergedCartItems() {
      final Map<
        String,
        ({String productId, String productName, int quantity, double unitPrice})
      >
      grouped =
          <
            String,
            ({
              String productId,
              String productName,
              int quantity,
              double unitPrice,
            })
          >{};
      for (final item in cartItems) {
        final existing = grouped[item.productId];
        if (existing == null) {
          grouped[item.productId] = item;
        } else {
          grouped[item.productId] = (
            productId: existing.productId,
            productName: existing.productName,
            quantity: existing.quantity + item.quantity,
            unitPrice: existing.unitPrice,
          );
        }
      }
      return grouped.values.toList();
    }

    Product? findProductById(String productId) {
      return productsProvider.byId(productId);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setModalState) {
            final List<
              ({
                String productId,
                String productName,
                int quantity,
                double unitPrice,
              })
            >
            normalizedCartItems = mergedCartItems();
            final Product selectedProduct = productsProvider.products
                .firstWhere((Product item) => item.id == selectedProductId);
            final int selectedProductInCart = normalizedCartItems
                .where((item) => item.productId == selectedProductId)
                .fold<int>(0, (int sum, item) => sum + item.quantity);
            final int selectedProductStockLeft =
                (selectedProduct.stock - selectedProductInCart).clamp(
                  0,
                  1 << 30,
                );
            final double totalPreview = normalizedCartItems.fold<double>(
              0,
              (double sum, item) => sum + (item.unitPrice * item.quantity),
            );
            final double paidPreview = paymentMode == 'comptant'
                ? totalPreview
                : paymentMode == 'credit_total'
                ? 0
                : (double.tryParse(paidCtrl.text) ?? 0);
            final double creditPreview = (totalPreview - paidPreview).clamp(
              0,
              double.infinity,
            );
            final MediaQueryData media = MediaQuery.of(context);
            final bool isWideLayout = media.size.width >= 960;

            return SafeArea(
              top: false,
              child: Align(
                alignment: isWideLayout
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWideLayout ? 24 : 0,
                    0,
                    isWideLayout ? 24 : 0,
                    isWideLayout ? 24 : 0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideLayout ? 860 : media.size.width,
                      maxHeight:
                          media.size.height * (isWideLayout ? 0.9 : 0.92),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(24),
                          bottom: Radius.circular(isWideLayout ? 24 : 0),
                        ),
                      ),
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: media.viewInsets.bottom + 24,
                      ),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Nouvelle vente',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111827),
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Enregistrez une transaction rapidement',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedProductId,
                                    items: productsProvider.products
                                        .map(
                                          (
                                            Product product,
                                          ) => DropdownMenuItem<String>(
                                            value: product.id,
                                            child: Text(
                                              '${product.name} (Stock: ${product.stock})',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value == null) return;
                                      setModalState(
                                        () => selectedProductId = value,
                                      );
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Sélectionner le produit',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
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
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 16,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAF9F8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: quantityCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Quantité vendue',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
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
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 16,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAF9F8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFBBE1FA),
                                      ),
                                    ),
                                    child: Row(
                                      children: <Widget>[
                                        const Icon(
                                          Icons.inventory_2_rounded,
                                          color: Color(0xFF0369A1),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Stock restant pour ${selectedProduct.name}: $selectedProductStockLeft',
                                            style: const TextStyle(
                                              color: Color(0xFF0C2D48),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        final int? quantity = int.tryParse(
                                          quantityCtrl.text.trim(),
                                        );
                                        if (quantity == null || quantity <= 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Quantité invalide.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final int nextQuantity =
                                            selectedProductInCart + quantity;
                                        if (nextQuantity >
                                            selectedProduct.stock) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Stock insuffisant pour ${selectedProduct.name}.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        final int index = cartItems.indexWhere(
                                          (item) =>
                                              item.productId ==
                                              selectedProductId,
                                        );
                                        setModalState(() {
                                          if (index == -1) {
                                            cartItems.add((
                                              productId: selectedProduct.id,
                                              productName: selectedProduct.name,
                                              quantity: quantity,
                                              unitPrice:
                                                  selectedProduct.salePrice,
                                            ));
                                          } else {
                                            final item = cartItems[index];
                                            cartItems[index] = (
                                              productId: item.productId,
                                              productName: item.productName,
                                              quantity:
                                                  item.quantity + quantity,
                                              unitPrice: item.unitPrice,
                                            );
                                          }
                                          quantityCtrl.text = '1';
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                      ),
                                      label: const Text('Ajouter au panier'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF7315,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (normalizedCartItems
                                      .isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              const Icon(
                                                Icons.shopping_cart_rounded,
                                                color: Color(0xFFFF7315),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Panier',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 16,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFF7315,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${normalizedCartItems.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ...normalizedCartItems.map((item) {
                                            final double lineTotal =
                                                item.unitPrice * item.quantity;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFFAF9F8,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            item.productName,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 14,
                                                                  color: Color(
                                                                    0xFF111827,
                                                                  ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 3,
                                                          ),
                                                          Text(
                                                            'Qté: ${item.quantity} • ${appSettings.formatMoney(item.unitPrice, decimals: 0)}/u',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color(
                                                                    0xFF64748B,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      appSettings.formatMoney(
                                                        lineTotal,
                                                        decimals: 0,
                                                      ),
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFFFF7315,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  DropdownButtonFormField<String>(
                                    initialValue: paymentMode,
                                    items: const <DropdownMenuItem<String>>[
                                      DropdownMenuItem(
                                        value: 'comptant',
                                        child: Text('💳 Paiement comptant'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'credit_partiel',
                                        child: Text('📋 Crédit partiel'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'credit_total',
                                        child: Text('📅 Crédit total'),
                                      ),
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) return;
                                      setModalState(() {
                                        paymentMode = value;
                                        if (paymentMode == 'comptant') {
                                          paidCtrl.clear();
                                          creditDueDate = null;
                                        } else {
                                          creditDueDate ??= DateTime.now().add(
                                            const Duration(days: 30),
                                          );
                                        }
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Mode de paiement',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
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
                                          width: 2,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 16,
                                          ),
                                      filled: true,
                                      fillColor: const Color(0xFFFAF9F8),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (paymentMode != 'comptant') ...<Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF8F3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFF7315),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF7315),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.event_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                const Text(
                                                  'Date d\'échéance',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF111827),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  appSettings.formatDate(
                                                    creditDueDate ??
                                                        DateTime.now().add(
                                                          const Duration(
                                                            days: 30,
                                                          ),
                                                        ),
                                                  ),
                                                  style: const TextStyle(
                                                    color: Color(0xFF475569),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              final DateTime now =
                                                  DateTime.now();
                                              final DateTime initial =
                                                  creditDueDate ??
                                                  now.add(
                                                    const Duration(days: 30),
                                                  );
                                              final DateTime? picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    locale: const Locale(
                                                      'fr',
                                                      'FR',
                                                    ),
                                                    initialDate: initial,
                                                    firstDate: DateTime(
                                                      now.year,
                                                      now.month,
                                                      now.day,
                                                    ),
                                                    lastDate: DateTime(
                                                      now.year + 5,
                                                    ),
                                                  );
                                              if (picked != null) {
                                                setModalState(() {
                                                  creditDueDate = picked;
                                                });
                                              }
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFFFF7315,
                                              ),
                                            ),
                                            child: const Text(
                                              'Modifier',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (paymentMode ==
                                      'credit_partiel') ...<Widget>[
                                    TextField(
                                      controller: paidCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Montant payé maintenant',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF7315),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 16,
                                            ),
                                        filled: true,
                                        fillColor: const Color(0xFFFAF9F8),
                                      ),
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (paymentMode != 'comptant') ...<Widget>[
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedClientId,
                                      items: <DropdownMenuItem<String>>[
                                        const DropdownMenuItem<String>(
                                          value: '',
                                          child: Text('Nouveau client libre'),
                                        ),
                                        ...clientsProvider.clients.map(
                                          (
                                            Client client,
                                          ) => DropdownMenuItem<String>(
                                            value: client.id,
                                            child: Text(
                                              '${client.name} (${client.phone})',
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (String? value) {
                                        setModalState(() {
                                          selectedClientId =
                                              (value == null || value.isEmpty)
                                              ? null
                                              : value;
                                          if (selectedClientId != null) {
                                            final Client selected =
                                                clientsProvider.clients
                                                    .firstWhere(
                                                      (Client client) =>
                                                          client.id ==
                                                          selectedClientId,
                                                    );
                                            clientCtrl.text = selected.name;
                                          }
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Client enregistré',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF7315),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 16,
                                            ),
                                        filled: true,
                                        fillColor: const Color(0xFFFAF9F8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (paymentMode == 'comptant' ||
                                      selectedClientId == null) ...<Widget>[
                                    TextField(
                                      controller: clientCtrl,
                                      decoration: InputDecoration(
                                        labelText: 'Nom client (optionnel)',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFFF7315),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 16,
                                            ),
                                        filled: true,
                                        fillColor: const Color(0xFFFAF9F8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            const Text(
                                              'Total estimé',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              appSettings.formatMoney(
                                                totalPreview,
                                                decimals: 0,
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF111827),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: <Widget>[
                                            const Text(
                                              'Montant payé',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              appSettings.formatMoney(
                                                paidPreview,
                                                decimals: 0,
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF059669),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (creditPreview > 0) ...<Widget>[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: <Widget>[
                                              const Text(
                                                'Reste à payer',
                                                style: TextStyle(
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                appSettings.formatMoney(
                                                  creditPreview,
                                                  decimals: 0,
                                                ),
                                                style: const TextStyle(
                                                  color: Color(0xFFEA580C),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () async {
                                final ScaffoldMessengerState messenger =
                                    ScaffoldMessenger.of(context);
                                final AuthProvider authProvider = context
                                    .read<AuthProvider>();

                                final List<
                                  ({
                                    String productId,
                                    String productName,
                                    int quantity,
                                    double unitPrice,
                                  })
                                >
                                checkoutItems = mergedCartItems();
                                if (checkoutItems.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Ajoute au moins un produit au panier.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final bool hasCreditMode =
                                    paymentMode != 'comptant';
                                String? effectiveClientId = selectedClientId;
                                Client? selectedClient;

                                if (hasCreditMode &&
                                    (effectiveClientId == null ||
                                        effectiveClientId.isEmpty)) {
                                  final String typedClientName = clientCtrl.text
                                      .trim();
                                  if (typedClientName.isEmpty) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Sélectionne un client enregistré ou saisis son nom pour la vente à crédit.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  selectedClient = clientsProvider.clients
                                      .cast<Client?>()
                                      .firstWhere(
                                        (Client? item) =>
                                            item != null &&
                                            item.name.trim().toLowerCase() ==
                                                typedClientName.toLowerCase(),
                                        orElse: () => null,
                                      );

                                  if (selectedClient != null) {
                                    effectiveClientId = selectedClient.id;
                                  } else {
                                    final String? adminId =
                                        authProvider.currentAdminId;
                                    if (adminId == null || adminId.isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Aucun administrateur connecté.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final Client newClient = Client(
                                      id: 'client_${DateTime.now().microsecondsSinceEpoch}',
                                      adminId: adminId,
                                      name: typedClientName,
                                      phone: '',
                                    );

                                    try {
                                      await clientsProvider.saveClient(
                                        newClient,
                                      );
                                      selectedClient = newClient;
                                      effectiveClientId = newClient.id;
                                    } catch (error) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Impossible de créer le client: ${error.toString().replaceFirst('Exception: ', '')}',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                }
                                double paidAmount = totalPreview;
                                if (paymentMode == 'credit_total') {
                                  paidAmount = 0;
                                } else if (paymentMode == 'credit_partiel') {
                                  final double? paid = double.tryParse(
                                    paidCtrl.text.trim(),
                                  );
                                  if (paid == null ||
                                      paid < 0 ||
                                      paid > totalPreview) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Montant payé invalide pour le crédit partiel.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  paidAmount = paid;
                                }
                                final Map<String, int> groupedQuantities =
                                    <String, int>{};
                                for (final item in checkoutItems) {
                                  groupedQuantities[item.productId] =
                                      (groupedQuantities[item.productId] ?? 0) +
                                      item.quantity;
                                }
                                for (final entry in groupedQuantities.entries) {
                                  final Product? product = findProductById(
                                    entry.key,
                                  );
                                  if (product == null ||
                                      product.stock < entry.value) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Stock insuffisant ou produit introuvable.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }
                                selectedClient ??= effectiveClientId == null
                                    ? null
                                    : clientsProvider.byId(effectiveClientId);
                                final String effectiveClientName =
                                    selectedClient?.name.isNotEmpty == true
                                    ? selectedClient!.name
                                    : (clientCtrl.text.trim().isEmpty
                                          ? 'Client comptant'
                                          : clientCtrl.text.trim());
                                double remainingPaid = paidAmount;
                                for (final item in checkoutItems) {
                                  final double lineTotal =
                                      item.unitPrice * item.quantity;
                                  final double linePaid = remainingPaid
                                      .clamp(0, lineTotal)
                                      .toDouble();
                                  remainingPaid = (remainingPaid - linePaid)
                                      .clamp(0, double.infinity)
                                      .toDouble();
                                  bool ok;
                                  try {
                                    ok = await salesProvider.registerSale(
                                      productsProvider: productsProvider,
                                      clientsProvider: clientsProvider,
                                      productId: item.productId,
                                      quantity: item.quantity,
                                      clientId: effectiveClientId,
                                      clientName: effectiveClientName,
                                      paidAmount: linePaid,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error.toString().replaceFirst(
                                            'Exception: ',
                                            '',
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (!ok) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Impossible d\'enregistrer la vente complète.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                }

                                final InvoiceModel invoice = InvoiceModel(
                                  shop: _shopInfo,
                                  invoiceNumber: _invoiceService
                                      .buildInvoiceNumber(),
                                  createdAt: DateTime.now(),
                                  clientName: effectiveClientName,
                                  clientPhone: selectedClient?.phone,
                                  items: checkoutItems
                                      .map(
                                        (item) => InvoiceItem(
                                          name: item.productName,
                                          quantity: item.quantity,
                                          unitPrice: item.unitPrice,
                                        ),
                                      )
                                      .toList(),
                                  taxRate: 0,
                                  notes: creditPreview > 0
                                      ? 'Reste à payer: ${appSettings.formatMoney(creditPreview, decimals: 0)}'
                                      : 'Paiement complet.',
                                  dueAt: creditPreview > 0
                                      ? (creditDueDate ??
                                            DateTime.now().add(
                                              const Duration(days: 30),
                                            ))
                                      : null,
                                );

                                final String? adminId =
                                    FirebaseAuth.instance.currentUser?.uid ??
                                    authProvider.currentAdminId;
                                if (adminId != null && adminId.isNotEmpty) {
                                  try {
                                    await _saveWebInvoiceRecord(
                                      adminId: adminId,
                                      invoice: invoice,
                                      creditAmount: creditPreview,
                                    );
                                  } catch (error) {
                                    if (context.mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Facture web non enregistrée: ${error.toString().replaceFirst('Exception: ', '')}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }

                                if (!mounted) {
                                  return;
                                }

                                await _showInvoiceActions(invoice);
                              },
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
                              child: const Text('Valider la vente'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showInvoiceActions(InvoiceModel invoice) async {
    InvoicePaperFormat selectedFormat = InvoicePaperFormat.a4;
    bool isProcessing = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder:
              (BuildContext ctx, void Function(void Function()) setModalState) {
                Future<void> runAction(
                  Future<void> Function(InvoicePaperFormat format) action,
                ) async {
                  if (isProcessing) {
                    return;
                  }

                  setModalState(() {
                    isProcessing = true;
                  });

                  try {
                    await action(selectedFormat);
                  } catch (error) {
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Action facture echouee: $error')),
                    );
                  } finally {
                    if (ctx.mounted) {
                      setModalState(() {
                        isProcessing = false;
                      });
                    }
                  }
                }

                final MediaQueryData media = MediaQuery.of(ctx);
                final bool isWideLayout = media.size.width >= 960;

                return SafeArea(
                  top: false,
                  child: Align(
                    alignment: isWideLayout
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isWideLayout ? 24 : 0,
                        0,
                        isWideLayout ? 24 : 0,
                        isWideLayout ? 24 : 0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWideLayout ? 820 : media.size.width,
                          maxHeight:
                              media.size.height * (isWideLayout ? 0.86 : 0.92),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(
                              top: const Radius.circular(24),
                              bottom: Radius.circular(isWideLayout ? 24 : 0),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDD5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Facture de la vente',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'No ${invoice.invoiceNumber ?? '-'}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<InvoicePaperFormat>(
                                initialValue: selectedFormat,
                                decoration: InputDecoration(
                                  labelText: 'Format de facture',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
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
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: InvoicePaperFormat.values
                                    .map(
                                      (InvoicePaperFormat format) =>
                                          DropdownMenuItem<InvoicePaperFormat>(
                                            value: format,
                                            child: Text(format.label),
                                          ),
                                    )
                                    .toList(),
                                onChanged: isProcessing
                                    ? null
                                    : (InvoicePaperFormat? value) {
                                        if (value == null) {
                                          return;
                                        }
                                        setModalState(() {
                                          selectedFormat = value;
                                        });
                                      },
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder:
                                    (
                                      BuildContext context,
                                      BoxConstraints constraints,
                                    ) {
                                      final bool rowActions =
                                          constraints.maxWidth >= 620;

                                      final Widget
                                      previewBtn = FilledButton.icon(
                                        onPressed: isProcessing
                                            ? null
                                            : () => runAction(
                                                (InvoicePaperFormat format) =>
                                                    _invoiceService
                                                        .previewInvoice(
                                                          context,
                                                          invoice,
                                                          format: format,
                                                        ),
                                              ),
                                        icon: const Icon(
                                          Icons.visibility_rounded,
                                        ),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFF7315,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        label: Text(
                                          isProcessing
                                              ? 'Traitement...'
                                              : 'Prévisualiser',
                                        ),
                                      );

                                      final Widget
                                      printBtn = OutlinedButton.icon(
                                        onPressed: isProcessing
                                            ? null
                                            : () => runAction(
                                                (InvoicePaperFormat format) =>
                                                    _invoiceService
                                                        .printInvoice(
                                                          invoice,
                                                          format: format,
                                                        ),
                                              ),
                                        icon: const Icon(Icons.print_rounded),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF4F46E5,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF818CF8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        label: const Text('Imprimer'),
                                      );

                                      final Widget
                                      shareBtn = OutlinedButton.icon(
                                        onPressed: isProcessing
                                            ? null
                                            : () => runAction(
                                                (InvoicePaperFormat format) =>
                                                    _invoiceService
                                                        .shareInvoice(
                                                          invoice,
                                                          format: format,
                                                        ),
                                              ),
                                        icon: const Icon(Icons.share_rounded),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF4F46E5,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF818CF8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        label: const Text('Partager'),
                                      );

                                      if (rowActions) {
                                        return Row(
                                          children: <Widget>[
                                            Expanded(child: previewBtn),
                                            const SizedBox(width: 10),
                                            Expanded(child: printBtn),
                                            const SizedBox(width: 10),
                                            Expanded(child: shareBtn),
                                          ],
                                        );
                                      }

                                      return Column(
                                        children: <Widget>[
                                          SizedBox(
                                            width: double.infinity,
                                            child: previewBtn,
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: printBtn,
                                          ),
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            width: double.infinity,
                                            child: shareBtn,
                                          ),
                                        ],
                                      );
                                    },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showAddExpenseSheet() async {
    String type = 'Transport';
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                Widget buildInputGroup(String label, Widget child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      child,
                    ],
                  );
                }

                Widget buildTextField(
                  TextEditingController controller, {
                  bool isNumber = false,
                }) {
                  return TextField(
                    controller: controller,
                    keyboardType: isNumber
                        ? TextInputType.number
                        : TextInputType.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFE5E7EB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  );
                }

                Widget buildDropdownField({
                  required String value,
                  required List<String> items,
                  required ValueChanged<String?> onChanged,
                }) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF6B7280),
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        items: items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: onChanged,
                      ),
                    ),
                  );
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  insetPadding: const EdgeInsets.all(24),
                  child: Container(
                    width: 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7315),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'NOUVELLE DÉPENSE',
                                  style: TextStyle(
                                    color: Color(0xFFFF7315),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                buildInputGroup(
                                  'TYPE DE DÉPENSE *',
                                  buildDropdownField(
                                    value: type,
                                    items: const <String>[
                                      'Transport',
                                      'Loyer',
                                      'Salaire',
                                      'Courant',
                                      'Autres',
                                    ],
                                    onChanged: (String? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setModalState(() => type = value);
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                buildInputGroup(
                                  'MONTANT (GNF) *',
                                  buildTextField(amountCtrl, isNumber: true),
                                ),
                                const SizedBox(height: 16),
                                buildInputGroup(
                                  'NOTE (OPTIONNEL)',
                                  buildTextField(noteCtrl),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                final double? amount = double.tryParse(
                                  amountCtrl.text.trim(),
                                );
                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Montant invalide.'),
                                    ),
                                  );
                                  return;
                                }
                                context.read<ExpensesProvider>().addExpense(
                                  type: type,
                                  amount: amount,
                                  note: noteCtrl.text.trim().isEmpty
                                      ? null
                                      : noteCtrl.text.trim(),
                                );
                                Navigator.pop(context);
                              },
                              child: const Text('Ajouter la dépense'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showAddClientSheet() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext context) {
        Widget buildInputGroup(String label, Widget child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          );
        }

        Widget buildTextField(
          TextEditingController controller, {
          bool isPhone = false,
        }) {
          return TextField(
            controller: controller,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFE5E7EB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7315),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'NOUVEAU CLIENT',
                          style: TextStyle(
                            color: Color(0xFFFF7315),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        buildInputGroup(
                          'NOM DU CLIENT *',
                          buildTextField(nameCtrl),
                        ),
                        const SizedBox(height: 16),
                        buildInputGroup(
                          'NUMÉRO DE TÉLÉPHONE *',
                          buildTextField(phoneCtrl, isPhone: true),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Nom et téléphone sont obligatoires.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await context.read<ClientsProvider>().addClient(
                            name: nameCtrl.text,
                            phone: phoneCtrl.text,
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Créer le client'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
