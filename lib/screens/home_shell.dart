import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import 'package:provider/provider.dart';

import '../invoice/models/invoice_model.dart';
import '../invoice/services/invoice_service.dart';
import '../invoice/ui/invoice_history_screen.dart';
import 'admin_profile_screen.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/suppliers_provider.dart';
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
    email: 'contact@appligestion.gn',
    // Ajoute ton logo ici quand il sera disponible dans pubspec assets.
    logoAssetPath: null,
  );

  final InvoiceService _invoiceService = const InvoiceService();

  int _index = 0;
  int _lastMainIndex = 0;

  /// Calcule la hauteur maximale du bottom sheet selon la largeur de l'écran
  double _getResponsiveMaxHeight(MediaQueryData media) {
    final double screenWidth = media.size.width;
    if (screenWidth < 380) {
      // Petits écrans : 85% de hauteur
      return media.size.height * 0.85;
    } else if (screenWidth < 600) {
      // Écrans moyens : 80% de hauteur
      return media.size.height * 0.80;
    } else {
      // Grands écrans : 75% de hauteur
      return media.size.height * 0.75;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTabletOrLarger = screenWidth >= 600;
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final String adminName = authProvider.currentAdminDisplayName;
    final String? adminEmail = authProvider.user?.email;

    final List<Widget> pages = <Widget>[
      const DashboardScreen(),
      const ProductsScreen(),
      const SalesScreen(),
      const ExpensesScreen(),
      ClientsScreen(onAddClientPressed: _showAddClientSheet),
      const InvoiceHistoryScreen(),
      SuppliersScreen(onAddSupplierPressed: _showAddSupplierSheet),
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
      l10n?.pageClients ?? 'Clients',
      l10n?.pageInvoices ?? 'Factures',
      'Fournisseurs',
      l10n?.pageAdminProfile ?? 'Profil admin',
      l10n?.pageSettings ?? 'Parametres',
    ];

    final List<AdminSidebarItem> sidebarItems =
        <(String, IconData, IconData)>[
              (
                'Fournisseurs',
                Icons.handshake_outlined,
                Icons.handshake_rounded,
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
      selectedIndex: _index == 6
          ? 0
          : _index == 7
          ? 1
          : _index == 8
          ? 2
          : -1,
      onSelected: (int sidebarIndex) {
        final int targetIndex = sidebarIndex == 0
            ? 6
            : sidebarIndex == 1
            ? 7
            : 8;
        if (!isTabletOrLarger) {
          Navigator.of(context).pop();
        }
        setState(() {
          if (_index == targetIndex) {
            _index = _lastMainIndex;
          } else {
            if (_index < 6) {
              _lastMainIndex = _index;
            }
            _index = targetIndex;
          }
        });
      },
      onLogout: () async {
        if (!isTabletOrLarger) {
          Navigator.of(context).pop();
        }
        await context.read<AuthProvider>().signOut();
      },
      adminName: adminName,
      adminEmail: adminEmail,
    );

    return Scaffold(
      appBar: isTabletOrLarger
          ? AppBar(
              title: Text(pageTitles[_index]),
              centerTitle: false,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 0,
              automaticallyImplyLeading: false,
            )
          : _buildMobileAppBar(adminName, adminEmail),
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
        child: isTabletOrLarger
            ? Stack(
                children: <Widget>[
                  Positioned(
                    top: -120,
                    right: -40,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -180,
                    left: -120,
                    child: Container(
                      width: 420,
                      height: 420,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF14B8A6).withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: screenWidth >= 980 ? 288 : 250,
                            child: sidebar,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFE5EAF7),
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0F172A,
                                    ).withValues(alpha: 0.05),
                                    blurRadius: 35,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: pages[_index],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : pages[_index],
      ),
      bottomNavigationBar: _index >= 6
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (int value) {
                setState(() {
                  _lastMainIndex = value;
                  _index = value;
                });
              },
              destinations: <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: l10n?.navDashboard ?? 'Tableau',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: l10n?.navProducts ?? 'Produits',
                ),
                NavigationDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale_rounded),
                  label: l10n?.navSales ?? 'Ventes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: l10n?.navExpenses ?? 'Depenses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt_rounded),
                  label: l10n?.navClients ?? 'Clients',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: l10n?.navInvoices ?? 'Factures',
                ),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    String? adminName,
    String? adminEmail,
  ) {
    final String source = (adminName != null && adminName.trim().isNotEmpty)
        ? adminName.trim()
        : ((adminEmail != null && adminEmail.trim().isNotEmpty)
              ? adminEmail.trim()
              : 'Admin');
    final List<String> parts = source.split(RegExp(r'\s+'));
    final String initials = parts.length >= 2
        ? '${parts.first[0]}${parts[1][0]}'.toUpperCase()
        : source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();

    return AppBar(
      toolbarHeight: 68,
      backgroundColor: const Color(0xFFF3F4F6),
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 8,
      title: Row(
        children: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                color: const Color(0xFF64748B),
              );
            },
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'AppliGestion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFFEA580C),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

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
      if (isMobile) {
        return FloatingActionButton(
          onPressed: _showAddExpenseSheet,
          backgroundColor: const Color(0xFFFF7A12),
          foregroundColor: const Color(0xFF1F2937),
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 34),
        );
      }

      return FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        icon: const Icon(Icons.note_add_outlined),
        label: Text(AppLocalizations.of(context)?.fabExpense ?? 'Depense'),
      );
    }

    if (_index == 4) {
      return FloatingActionButton.extended(
        onPressed: _showAddClientSheet,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: Text(AppLocalizations.of(context)?.fabClient ?? 'Client'),
      );
    }

    return null;
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
                                    const SizedBox(width: 16),
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
                                    const SizedBox(width: 16),
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
                                    const SizedBox(width: 16),
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
      final int index = productsProvider.products.indexWhere(
        (Product item) => item.id == productId,
      );
      if (index == -1) {
        return null;
      }
      return productsProvider.products[index];
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
                                final NavigatorState navigator = Navigator.of(
                                  context,
                                );
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
                                    if (!mounted) {
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

                                navigator.pop();

                                if (!mounted) {
                                  return;
                                }

                                if (!kIsWeb) {
                                  try {
                                    final String? adminId =
                                        authProvider.currentAdminId;
                                    if (adminId != null && adminId.isNotEmpty) {
                                      await _invoiceService.saveInvoice(
                                        invoice,
                                        adminId: adminId,
                                        format: InvoicePaperFormat.ticket80mm,
                                        preferDownloads: true,
                                      );
                                    }
                                  } catch (error) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Facture non enregistrée localement: ${error.toString().replaceFirst('Exception: ', '')}',
                                        ),
                                      ),
                                    );
                                  }
                                }

                                if (!context.mounted) {
                                  return;
                                }

                                // ignore: use_build_context_synchronously
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
    final AuthProvider authProvider = context.read<AuthProvider>();

    Future<(Uint8List, File?)> prepare(InvoicePaperFormat format) async {
      final Uint8List bytes = await _invoiceService.generateInvoice(
        invoice,
        format: format,
      );

      if (kIsWeb) {
        return (bytes, null);
      }

      File? savedFile;
      try {
        final String? adminId = authProvider.currentAdminId;
        if (adminId == null || adminId.isEmpty) {
          return (bytes, null);
        }
        savedFile = await _invoiceService.saveInvoice(
          invoice,
          adminId: adminId,
          bytes: bytes,
          preferDownloads: true,
          format: format,
        );
      } catch (error) {
        debugPrint('saveInvoice failed: $error');
      }

      return (bytes, savedFile);
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext sheetContext, void Function(void Function()) setState) {
            final MediaQueryData media = MediaQuery.of(context);
            final bool isWideLayout = media.size.width >= 960;
            final bool isCompactMobile = media.size.width < 420;
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWideLayout ? 24 : 8,
                    8,
                    isWideLayout ? 24 : 8,
                    isWideLayout ? 24 : 8,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideLayout ? 820 : media.size.width - 16,
                      maxHeight: _getResponsiveMaxHeight(media),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(26),
                          bottom: const Radius.circular(26),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                                        width: 42,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFEDD5),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long_rounded,
                                            color: Color(0xFFF97316),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(
                                          child: Text(
                                            'Facture de la vente',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
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
                                        fillColor: Colors.white,
                                      ),
                                      items: InvoicePaperFormat.values
                                          .map(
                                            (InvoicePaperFormat format) =>
                                                DropdownMenuItem<
                                                  InvoicePaperFormat
                                                >(
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
                                              setState(() {
                                                selectedFormat = value;
                                              });
                                            },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFF97316),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isCompactMobile ? 16 : 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        setState(() {
                                          isProcessing = true;
                                        });

                                        try {
                                          final (Uint8List bytes, File? file) =
                                              await prepare(selectedFormat);
                                          if (!mounted) {
                                            return;
                                          }

                                          if (file != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Facture enregistrée: ${file.path}',
                                                ),
                                              ),
                                            );
                                          }

                                          if (modalContext.mounted) {
                                            Navigator.of(modalContext).pop();
                                          }
                                          await _invoiceService.previewInvoice(
                                            context,
                                            invoice,
                                            bytes: bytes,
                                            format: selectedFormat,
                                          );
                                        } catch (error) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erreur lors de la prévisualisation: $error',
                                                ),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (modalContext.mounted) {
                                            setState(() {
                                              isProcessing = false;
                                            });
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.visibility_rounded),
                                label: Text(
                                  isProcessing
                                      ? 'Traitement...'
                                      : 'Prévisualiser le PDF',
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        setState(() {
                                          isProcessing = true;
                                        });

                                        try {
                                          final (Uint8List bytes, File? file) =
                                              await prepare(selectedFormat);
                                          if (!mounted) {
                                            return;
                                          }

                                          if (file != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Facture enregistrée: ${file.path}',
                                                ),
                                              ),
                                            );
                                          }

                                          if (modalContext.mounted) {
                                            Navigator.of(modalContext).pop();
                                          }
                                          await _invoiceService.printInvoice(
                                            invoice,
                                            bytes: bytes,
                                            format: selectedFormat,
                                          );
                                        } catch (error) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erreur lors de l\'impression: $error',
                                                ),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (modalContext.mounted) {
                                            setState(() {
                                              isProcessing = false;
                                            });
                                          }
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4F46E5),
                                  side: const BorderSide(
                                    color: Color(0xFF818CF8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isCompactMobile ? 15 : 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                icon: const Icon(Icons.print_rounded),
                                label: const Text('Imprimer'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        setState(() {
                                          isProcessing = true;
                                        });

                                        try {
                                          final (Uint8List bytes, File? file) =
                                              await prepare(selectedFormat);
                                          if (!mounted) {
                                            return;
                                          }

                                          if (file != null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Facture enregistrée: ${file.path}',
                                                ),
                                              ),
                                            );
                                          }

                                          if (modalContext.mounted) {
                                            Navigator.of(modalContext).pop();
                                          }
                                          await _invoiceService.shareInvoice(
                                            invoice,
                                            bytes: bytes,
                                            format: selectedFormat,
                                          );
                                        } catch (error) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Erreur lors du partage: $error',
                                                ),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (modalContext.mounted) {
                                            setState(() {
                                              isProcessing = false;
                                            });
                                          }
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4F46E5),
                                  side: const BorderSide(
                                    color: Color(0xFF818CF8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: isCompactMobile ? 15 : 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('Partager'),
                              ),
                            ),
                          ],
                        ),
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setModalState,
              ) {
                final MediaQueryData media = MediaQuery.of(context);
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: _getResponsiveMaxHeight(media),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Nouvelle dépense',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<String>(
                                initialValue: type,
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem(
                                    value: 'Transport',
                                    child: Text('Transport'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Loyer',
                                    child: Text('Loyer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Salaire',
                                    child: Text('Salaire'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Courant',
                                    child: Text('Courant'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Autres',
                                    child: Text('Autres'),
                                  ),
                                ],
                                onChanged: (String? value) {
                                  if (value == null) return;
                                  setModalState(() {
                                    type = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Type de dépense',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: amountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Montant de la dépense',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: noteCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Note (optionnel)',
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
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
                    ],
                  ),
                );
              },
        );
      },
    );
  }

  Future<void> _showAddSupplierSheet() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController categoryCtrl = TextEditingController();
    final TextEditingController debtCtrl = TextEditingController(text: '0');
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final MediaQueryData media = MediaQuery.of(context);
        return Container(
          constraints: BoxConstraints(
            maxHeight: _getResponsiveMaxHeight(media),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.handshake_rounded,
                              color: Color(0xFFF97316),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Nouveau fournisseur',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom du fournisseur',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Categorie',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: debtCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Dette actuelle',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telephone (optionnel)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optionnel)',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final double? debt = double.tryParse(debtCtrl.text.trim());
                    if (nameCtrl.text.trim().isEmpty ||
                        categoryCtrl.text.trim().isEmpty ||
                        debt == null ||
                        debt < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nom, categorie et dette valide sont obligatoires.',
                          ),
                        ),
                      );
                      return;
                    }

                    context.read<SuppliersProvider>().addSupplier(
                      name: nameCtrl.text,
                      category: categoryCtrl.text,
                      currentDebt: debt,
                      phone: phoneCtrl.text,
                      email: emailCtrl.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Ajouter le fournisseur'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAddClientSheet() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final MediaQueryData media = MediaQuery.of(context);
        return Container(
          constraints: BoxConstraints(
            maxHeight: _getResponsiveMaxHeight(media),
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Nouveau client',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet du client',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        phoneCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nom et téléphone sont obligatoires.'),
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
                            error.toString().replaceFirst('Exception: ', ''),
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
            ],
          ),
        );
      },
    );
  }
}
