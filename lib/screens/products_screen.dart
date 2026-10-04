import 'dart:typed_data';

import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/product.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/suppliers_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (isDesktop) {
      return _buildDesktop(context);
    }

    final bool isCompact = MediaQuery.sizeOf(context).width < 390;
    final ProductsProvider productsProvider = context.watch<ProductsProvider>();
    final List<Product> visibleProducts = productsProvider.products
        .where(
          (Product product) =>
              product.name.toLowerCase().contains(_query.toLowerCase()) ||
              product.category.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFEDEFF3),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 14 : 18,
            12,
            isCompact ? 14 : 18,
            130,
          ),
          children: <Widget>[
            Text(
              'Produits',
              style: TextStyle(
                fontSize: isCompact ? 44 : 48,
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gérez vos articles, vos prix et vos seuils d\'alerte.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportToExcel(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Exporter',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddProductSheet(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFFFF7315),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Nouveau',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EBEF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9A7C6B),
                    size: 30,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: (String value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            if (visibleProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Aucun produit trouvé.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                  ),
                ),
              )
            else
              ...visibleProducts.map(
                (Product product) => _productTile(context, product),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool compactDesktop = screenWidth < 1520;
    final ProductsProvider productsProvider = context.watch<ProductsProvider>();
    final List<Product> visibleProducts = productsProvider.products
        .where(
          (Product product) =>
              product.name.toLowerCase().contains(_query.toLowerCase()) ||
              product.id.toLowerCase().contains(_query.toLowerCase()) ||
              product.category.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF3F4F7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 120),
          children: <Widget>[
            if (compactDesktop)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Inventaire des Produits',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.06,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gérez vos articles, vos prix et vos seuils d\'alerte.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => _exportToExcel(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'Exporter Excel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () => _showAddProductSheet(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFFF7315),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Nouveau Produit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Inventaire des Produits',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.06,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Gérez vos articles, vos prix et vos seuils d\'alerte.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () => _exportToExcel(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'Exporter Excel',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 14),
                      FilledButton.icon(
                        onPressed: () => _showAddProductSheet(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFFF7315),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Nouveau Produit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8ECF3)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: compactDesktop ? 960 : 1080,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: <Widget>[
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'SKU',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'DÉSIGNATION',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'CATÉGORIE',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'FOURNISSEUR',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'PRIX VENTE',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'STOCK',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 80,
                              child: Text(
                                'ACTIONS',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFEFF2F6)),
                      if (visibleProducts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Text(
                            'Aucun produit trouvé.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      else
                        ...visibleProducts.map(
                          (Product product) => _desktopRow(context, product),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopRow(BuildContext context, Product product) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final String sku = product.id.toUpperCase();
    final String category = product.category.trim().isEmpty
        ? 'N/A'
        : product.category;
    final String supplier = product.supplier.trim().isEmpty
        ? 'N/A'
        : product.supplier;
    final String priceText = appSettings.formatMoney(
      product.salePrice,
      decimals: 0,
      withCurrency: false,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              sku,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                supplier,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '$priceText GNF',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${product.stock}',
                    style: const TextStyle(
                      color: Color(0xFF166534),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showAdjustStockDialog(context, product),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFFD1D5DB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                InkWell(
                  onTap: () => _showEditProductDialog(context, product),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _showDeleteConfirmation(context, product);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdjustStockDialog(
    BuildContext context,
    Product product,
  ) async {
    final TextEditingController quantityCtrl = TextEditingController(text: '1');

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ajouter au stock'),
          content: TextField(
            controller: quantityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantité à ajouter',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final int? quantity = int.tryParse(quantityCtrl.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Entrez une quantité valide.'),
                    ),
                  );
                  return;
                }

                try {
                  await dialogContext.read<ProductsProvider>().updateProduct(
                    product.copyWith(stock: product.stock + quantity),
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stock de ${product.name} augmenté de $quantity.',
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditProductDialog(
    BuildContext context,
    Product product,
  ) async {
    final TextEditingController nameCtrl = TextEditingController(
      text: product.name,
    );
    final TextEditingController purchaseCtrl = TextEditingController(
      text: product.purchasePrice.toStringAsFixed(0),
    );
    final TextEditingController saleCtrl = TextEditingController(
      text: product.salePrice.toStringAsFixed(0),
    );
    final TextEditingController stockCtrl = TextEditingController(
      text: product.stock.toString(),
    );
    final TextEditingController alertCtrl = TextEditingController(
      text: product.alertThreshold.toString(),
    );
    String category = product.category.isEmpty
        ? '-- Sans Catégorie --'
        : product.category;
    String supplier = product.supplier.isEmpty
        ? '-- Sans Fournisseur --'
        : product.supplier;

    final List<String> supplierNames = <String>['-- Sans Fournisseur --'];
    if (context.mounted) {
      final suppliers = context.read<SuppliersProvider>().suppliers;
      supplierNames.addAll(suppliers.map((s) => s.name));
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext dialogContext) {
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
                        items: items
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: onChanged,
                      ),
                    ),
                  );
                }

                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(24),
                  child: Container(
                    width: 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'MODIFIER LE PRODUIT',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
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
                                onPressed: () => Navigator.pop(dialogContext),
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
                                        'STOCK',
                                        buildTextField(
                                          stockCtrl,
                                          isNumber: true,
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
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
                                        child: const Text('ANNULER'),
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
                                              dialogContext,
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
                                          final String finalSupplier =
                                              supplier ==
                                                  '-- Sans Fournisseur --'
                                              ? '-- Sans Fournisseur --'
                                              : supplier;

                                          try {
                                            await dialogContext
                                                .read<ProductsProvider>()
                                                .updateProduct(
                                                  product.copyWith(
                                                    name: name,
                                                    category: finalCat,
                                                    purchasePrice: purchase,
                                                    salePrice: sale,
                                                    stock: stock,
                                                    alertThreshold: alert,
                                                    supplier: finalSupplier,
                                                  ),
                                                );
                                          } catch (error) {
                                            if (!dialogContext.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              dialogContext,
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

                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
                                            ScaffoldMessenger.of(
                                              dialogContext,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Produit ${product.name} mis à jour.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('METTRE À JOUR'),
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

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Product product,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Supprimer le produit'),
          content: Text('Voulez-vous vraiment supprimer "${product.name}" ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      await context.read<ProductsProvider>().deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produit ${product.name} supprimé.')),
        );
      }
    }
  }

  Future<void> _exportToExcel(BuildContext context) async {
    final ProductsProvider productsProvider = context.read<ProductsProvider>();
    final AppSettingsProvider appSettings = context.read<AppSettingsProvider>();
    final List<Product> products = productsProvider.products;

    if (products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('L\'inventaire est vide.')));
      return;
    }

    final List<String> headers = <String>[
      'SKU',
      'Désignation',
      'Catégorie',
      'Fournisseur',
      'Prix Achat (GNF)',
      'Prix Vente (GNF)',
      'Stock',
      'Seuil d\'alerte',
    ];

    try {
      final excel.Excel workbook = excel.Excel.createExcel();
      const String defaultSheet = 'Sheet1';
      const String sheetName = 'Inventaire';
      if (workbook.sheets.containsKey(defaultSheet)) {
        workbook.delete(defaultSheet);
      }
      final excel.Sheet sheet = workbook[sheetName];

      final excel.CellStyle titleStyle = excel.CellStyle(
        bold: true,
        fontSize: 18,
        fontColorHex: excel.ExcelColor.black,
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
      );
      final excel.CellStyle dateStyle = excel.CellStyle(
        italic: true,
        fontSize: 11,
        fontColorHex: excel.ExcelColor.grey,
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
      );
      final excel.CellStyle headerStyle = excel.CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: excel.ExcelColor.white,
        backgroundColorHex: excel.ExcelColor.blueGrey,
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
      );

      sheet.merge(
        excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0),
      );
      sheet.merge(
        excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 1),
      );

      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = excel.TextCellValue(
        'Inventaire des produits',
      );
      sheet
              .cell(
                excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
              )
              .cellStyle =
          titleStyle;
      sheet.setRowHeight(0, 26);

      sheet
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
          .value = excel.TextCellValue(
        'Généré le ${appSettings.formatDateTime(DateTime.now())}',
      );
      sheet
              .cell(
                excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
              )
              .cellStyle =
          dateStyle;
      sheet.setRowHeight(1, 20);

      sheet.appendRow(<excel.CellValue>[excel.TextCellValue('')]);

      sheet.appendRow(
        headers.map((String h) => excel.TextCellValue(h)).toList(),
      );

      for (int columnIndex = 0; columnIndex < headers.length; columnIndex++) {
        sheet
                .cell(
                  excel.CellIndex.indexByColumnRow(
                    columnIndex: columnIndex,
                    rowIndex: 3,
                  ),
                )
                .cellStyle =
            headerStyle;
      }

      for (final Product product in products) {
        sheet.appendRow(<excel.CellValue>[
          excel.TextCellValue(product.id.toUpperCase()),
          excel.TextCellValue(product.name),
          excel.TextCellValue(product.category),
          excel.TextCellValue(product.supplier),
          excel.TextCellValue(
            appSettings.formatMoney(product.purchasePrice, decimals: 0),
          ),
          excel.TextCellValue(
            appSettings.formatMoney(product.salePrice, decimals: 0),
          ),
          excel.TextCellValue(product.stock.toString()),
          excel.TextCellValue(product.alertThreshold.toString()),
        ]);
      }

      sheet.setColumnWidth(0, 18);
      sheet.setColumnWidth(1, 28);
      sheet.setColumnWidth(2, 24);
      sheet.setColumnWidth(3, 24);
      sheet.setColumnWidth(4, 20);
      sheet.setColumnWidth(5, 20);
      sheet.setColumnWidth(6, 12);
      sheet.setColumnWidth(7, 16);

      final List<int>? bytes = workbook.encode();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Impossible de générer le fichier Excel.');
      }

      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        name: 'inventaire_produits.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await Share.shareXFiles([xFile], text: 'Inventaire des produits');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export Excel généré avec succès.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur lors de l\'export: $e')));
      }
    }
  }

  Future<void> _showAddProductSheet(BuildContext context) async {
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
      builder: (BuildContext dialogContext) {
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
                                onPressed: () => Navigator.pop(dialogContext),
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
                                        onPressed: () =>
                                            Navigator.pop(dialogContext),
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
                                              dialogContext,
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
                                            await dialogContext
                                                .read<ProductsProvider>()
                                                .addProduct(
                                                  Product(
                                                    id: 'p-${DateTime.now().microsecondsSinceEpoch}',
                                                    adminId:
                                                        dialogContext
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
                                            if (!dialogContext.mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              dialogContext,
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

                                          if (dialogContext.mounted) {
                                            Navigator.pop(dialogContext);
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

  Widget _productTile(BuildContext context, Product product) {
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final _StockStatus status = _stockStatus(product);
    final String qtyText = 'Qte: ${product.stock}';
    final String priceText = appSettings.formatMoney(
      product.salePrice,
      decimals: 2,
      withCurrency: false,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ProductThumb(product: product),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: Color(0xFFB24C00),
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          '',
                          style: TextStyle(
                            color: Color(0xFFB24C00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          appSettings.currencyLabel,
                          style: const TextStyle(
                            color: Color(0xFFB24C00),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF556779),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status.bg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: status.fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      qtyText,
                      style: const TextStyle(
                        color: Color(0xFF8B6D63),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StockStatus _stockStatus(Product product) {
    if (product.stock <= 0) {
      return const _StockStatus(
        label: 'RUPTURE STOCK',
        bg: Color(0xFFE5EAF0),
        fg: Color(0xFF5E7088),
      );
    }
    if (product.isLowStock) {
      return const _StockStatus(
        label: 'STOCK FAIBLE',
        bg: Color(0xFFFCE6D1),
        fg: Color(0xFFC24810),
      );
    }
    return const _StockStatus(
      label: 'EN STOCK',
      bg: Color(0xFFD0F3DD),
      fg: Color(0xFF0A7A3D),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      color: const Color(0xFFD9E2EA),
      child: const Center(
        child: Icon(
          Icons.inventory_2_rounded,
          color: Color(0xFF64748B),
          size: 34,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 60,
        height: 60,
        child: (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty)
            ? Image.network(
                product.imageUrl!.trim(),
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) => fallback,
                loadingBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      ImageChunkEvent? progress,
                    ) {
                      if (progress == null) {
                        return child;
                      }
                      return fallback;
                    },
              )
            : fallback,
      ),
    );
  }
}

class _StockStatus {
  const _StockStatus({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;
}
