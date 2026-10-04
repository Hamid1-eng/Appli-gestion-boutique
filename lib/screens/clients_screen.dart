import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/sale.dart';
import '../providers/app_settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/sales_provider.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, this.onAddClientPressed});

  final VoidCallback? onAddClientPressed;

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  static const Color _pumpkin = Color(0xFFFF7518);
  static const Color _charcoal = Color(0xFF36454F);
  static const Color _offWhite = Color(0xFFF8F9FC);

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _segment = 'Tout';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1360;
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final ClientsProvider clientsProvider = context.watch<ClientsProvider>();
    final SalesProvider salesProvider = context.watch<SalesProvider>();

    final List<Client> clients = clientsProvider.clients;
    final List<Sale> sales = salesProvider.sales;

    final List<Client> filteredClients = clients.where((Client client) {
      if (_query.trim().isEmpty) {
        return true;
      }
      final String q = _query.toLowerCase();
      return client.name.toLowerCase().contains(q) ||
          client.phone.toLowerCase().contains(q);
    }).toList();

    final double totalCredit = clientsProvider.totalClientCredit;
    final double totalPaid = sales
        .where(
          (Sale sale) =>
              (sale.clientId != null && sale.clientId!.isNotEmpty) ||
              (sale.client != null && sale.client!.trim().isNotEmpty),
        )
        .fold<double>(0, (double sum, Sale sale) => sum + sale.paidAmount);
    final int lateClients = clients
        .where(
          (Client c) =>
              c.creditBalance > 0 && _daysFromLastSale(c, sales) >= 15,
        )
        .length;

    final double paymentsRatio = totalCredit <= 0
        ? 100
        : (totalPaid / (totalPaid + totalCredit) * 100).clamp(0, 100);

    if (isDesktop) {
      return _buildDesktop(
        context,
        appSettings: appSettings,
        clients: clients,
        sales: sales,
        totalCredit: totalCredit,
        paymentsRatio: paymentsRatio,
      );
    }

    return SafeArea(
      bottom: false,
      child: Container(
        color: _offWhite,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            16,
            isCompact ? 16 : 20,
            120,
          ),
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Clients',
                        style: TextStyle(
                          fontSize: isCompact ? 30 : 34,
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gestion et suivi des crédits clients',
                        style: const TextStyle(color: _charcoal, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _pumpkin,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (widget.onAddClientPressed != null) {
                      widget.onAddClientPressed!();
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter client'),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.03),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: (String value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher un client...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _pumpkin, width: 1.8),
                ),
              ),
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 16),
            SizedBox(
              height: 170,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  _highlightStatCard(
                    title: 'Total des dettes',
                    value: appSettings.formatMoney(totalCredit, decimals: 0),
                    subtitle:
                        '${paymentsRatio.toStringAsFixed(0)}% de paiements reçus',
                  ),
                  const SizedBox(width: 12),
                  _lightStatCard(
                    title: 'Total clients',
                    value: clients.length.toString(),
                  ),
                  const SizedBox(width: 12),
                  _lightStatCard(
                    title: 'Paiements reçus',
                    value: appSettings.formatMoney(totalPaid, decimals: 0),
                  ),
                  const SizedBox(width: 12),
                  _lightStatCard(
                    title: 'Clients en retard',
                    value: lateClients.toString(),
                  ),
                ],
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 350.ms),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Liste des clients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      color: _pumpkin,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ).animate(delay: 160.ms).fadeIn(),
            const SizedBox(height: 8),
            if (filteredClients.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _query.trim().isEmpty
                        ? 'Aucun client enregistré.'
                        : 'Aucun client trouvé.',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ).animate(delay: 200.ms).fadeIn()
            else
              ...filteredClients.asMap().entries.map(
                (MapEntry<int, Client> entry) => _clientTile(
                  context,
                  entry.value,
                  sales,
                  entry.key,
                  appSettings,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required AppSettingsProvider appSettings,
    required List<Client> clients,
    required List<Sale> sales,
    required double totalCredit,
    required double paymentsRatio,
  }) {
    final DateTime now = DateTime.now();

    double purchasesFor(Client client) {
      return sales
          .where(
            (Sale sale) =>
                sale.clientId == client.id ||
                (sale.client != null && sale.client == client.name),
          )
          .fold<double>(0, (double sum, Sale sale) => sum + sale.amount);
    }

    String categoryFor(Client client) {
      final double purchases = purchasesFor(client);
      if (purchases >= 10000000) {
        return 'VIP';
      }
      final int days = now.difference(client.createdAt).inDays;
      if (days <= 30) {
        return 'Nouveau';
      }
      return 'Régulier';
    }

    final List<Client> filtered = clients.where((Client client) {
      final String q = _query.trim().toLowerCase();
      final bool queryOk =
          q.isEmpty ||
          client.name.toLowerCase().contains(q) ||
          client.phone.toLowerCase().contains(q);
      final String category = categoryFor(client);
      final bool segmentOk = _segment == 'Tout' || _segment == category;
      return queryOk && segmentOk;
    }).toList();

    final int newThisMonth = clients
        .where(
          (Client c) =>
              c.createdAt.year == now.year && c.createdAt.month == now.month,
        )
        .length;
    final int activeCustomers = clients
        .where(
          (Client c) => sales.any(
            (Sale sale) =>
                sale.clientId == c.id ||
                (sale.client != null && sale.client == c.name),
          ),
        )
        .length;
    final double activeRatio = clients.isEmpty
        ? 0
        : (activeCustomers / clients.length) * 100;

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF3F4F7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 120),
          children: <Widget>[
            const Text(
              'Gestion des Clients',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Bonjour, suivez vos performances clients et crédits actifs.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DesktopClientStat(
                    title: 'TOTAL CLIENTS',
                    value: NumberFormat(
                      '#,###',
                      'fr_FR',
                    ).format(clients.length),
                    subtitle: '+12%',
                    subtitleColor: const Color(0xFF16A34A),
                    icon: Icons.people_alt_rounded,
                    iconBg: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFEA580C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DesktopClientStat(
                    title: 'NOUVEAUX CE MOIS',
                    value: '$newThisMonth',
                    subtitle: 'Nouveau',
                    subtitleColor: const Color(0xFFB45309),
                    icon: Icons.person_add_alt_1_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DesktopClientStat(
                    title: 'TOTAL CRÉDIT',
                    value: appSettings.formatMoney(totalCredit, decimals: 0),
                    subtitle: 'Suivi en direct',
                    subtitleColor: const Color(0xFF64748B),
                    icon: Icons.credit_score_rounded,
                    iconBg: const Color(0xFFFFF1F2),
                    iconColor: const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DesktopClientStat(
                    title: 'CLIENTS ACTIFS',
                    value: '${activeRatio.toStringAsFixed(0)}%',
                    subtitle:
                        '${paymentsRatio.toStringAsFixed(0)}% de paiements',
                    subtitleColor: const Color(0xFF64748B),
                    icon: Icons.verified_user_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
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
                    child: Row(
                      children: <Widget>[
                        ...<String>['Tout', 'VIP', 'Régulier', 'Nouveau'].map((
                          String item,
                        ) {
                          final bool selected = _segment == item;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _segment = item;
                                });
                              },
                              backgroundColor: const Color(0xFFF8FAFC),
                              selectedColor: const Color(0xFFFF7315),
                              labelStyle: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF334155),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEA580C),
                            side: const BorderSide(color: Color(0xFFF97316)),
                          ),
                          icon: const Icon(Icons.filter_alt_outlined),
                          label: const Text('Filtres'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: widget.onAddClientPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7315),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Ajouter un Client'),
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
                          flex: 3,
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
                          flex: 2,
                          child: Text(
                            'CATÉGORIE',
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
                            'ACHATS TOTAUX',
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
                            'CRÉDIT ACTUEL',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            'ACTIONS',
                            textAlign: TextAlign.right,
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
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Aucun client pour ce filtre.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ...filtered.take(10).map((Client client) {
                      final String category = categoryFor(client);
                      final double purchases = purchasesFor(client);
                      final bool hasCredit = client.creditBalance > 0;
                      final Color creditColor = hasCredit
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF111827);

                      Color categoryBg;
                      Color categoryFg;
                      if (category == 'VIP') {
                        categoryBg = const Color(0xFFFFEDD5);
                        categoryFg = const Color(0xFFB45309);
                      } else if (category == 'Nouveau') {
                        categoryBg = const Color(0xFFF3F4F6);
                        categoryFg = const Color(0xFF475569);
                      } else {
                        categoryBg = const Color(0xFFDBEAFE);
                        categoryFg = const Color(0xFF1D4ED8);
                      }

                      return Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    child: Text(
                                      _initials(client.name),
                                      style: const TextStyle(
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          client.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          client.phone,
                                          style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: categoryBg,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: categoryFg,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                appSettings.formatMoney(purchases, decimals: 2),
                                style: const TextStyle(
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                appSettings.formatMoney(
                                  client.creditBalance,
                                  decimals: 2,
                                ),
                                style: TextStyle(
                                  color: creditColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: IconButton(
                                onPressed: () =>
                                    _showRepaymentSheet(context, client),
                                icon: const Icon(Icons.more_vert_rounded),
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Affichage de 1 à ${filtered.take(10).length} sur ${filtered.length} clients',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _pagePill('<', active: false),
                        const SizedBox(width: 6),
                        _pagePill('1', active: true),
                        const SizedBox(width: 6),
                        _pagePill('2', active: false),
                        const SizedBox(width: 6),
                        _pagePill('3', active: false),
                        const SizedBox(width: 6),
                        _pagePill('>', active: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFB45309), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Performance du mois',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Votre base de clients a augmenté de 12% ce mois-ci. Les clients VIP représentent désormais 35% de votre chiffre d\'affaires.',
                          style: TextStyle(
                            color: Color(0xFFFFEDD5),
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8ECF3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Client du mois',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Jean-Luc Moreau',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${appSettings.formatMoney(12450, decimals: 2)} d\'achats ce trimestre',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagePill(String label, {required bool active}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFFF7315) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _highlightStatCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFF7518), Color(0xFFFF8A3D)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: _pumpkin.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFFFE8D8),
              fontSize: 12,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lightStatCard({required String title, required String value}) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clientTile(
    BuildContext context,
    Client client,
    List<Sale> sales,
    int index,
    AppSettingsProvider appSettings,
  ) {
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;
    final bool hasCredit = client.creditBalance > 0;
    final DateTime? lastSaleDate = _lastSaleDate(client, sales);
    final String status = _statusForClient(client, sales);

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
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 12 : 16,
            ),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: isCompact ? 56 : 60,
                      height: isCompact ? 56 : 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          _initials(client.name),
                          style: TextStyle(
                            color: _pumpkin,
                            fontSize: isCompact ? 20 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isCompact ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            client.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isCompact ? 16 : 18,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastSaleDate == null
                                ? 'Dernière facture: -'
                                : 'Dernière facture: ${_dateLabel(lastSaleDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _charcoal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text(
                          'CRÉDIT',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appSettings.formatMoney(
                            client.creditBalance,
                            decimals: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isCompact ? 18 : 20,
                            color: hasCredit
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF111827),
                            height: 0.95,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _statusBadge(status),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Appeler ${client.phone}')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _charcoal,
                          backgroundColor: const Color(0xFFF2F4F8),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.call_rounded),
                        label: const Text(
                          'Appeler',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showRepaymentSheet(context, client),
                        style: FilledButton.styleFrom(
                          backgroundColor: _pumpkin,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: Text(
                          hasCredit ? 'Relancer' : 'Détails',
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.03, curve: Curves.easeOut);
  }

  Widget _statusBadge(String status) {
    Color textColor;
    Color bgColor;

    if (status == 'En retard') {
      textColor = const Color(0xFFB91C1C);
      bgColor = const Color(0xFFFFE4E6);
    } else if (status == 'En attente') {
      textColor = const Color(0xFFB45309);
      bgColor = const Color(0xFFFFF1D6);
    } else {
      textColor = const Color(0xFF065F46);
      bgColor = const Color(0xFFDCFCE7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusForClient(Client client, List<Sale> sales) {
    if (client.creditBalance <= 0) {
      return 'OK';
    }
    final int daysSinceLastSale = _daysFromLastSale(client, sales);
    return daysSinceLastSale >= 15 ? 'En retard' : 'En attente';
  }

  int _daysFromLastSale(Client client, List<Sale> sales) {
    final DateTime? last = _lastSaleDate(client, sales);
    if (last == null) {
      return 999;
    }
    return DateTime.now().difference(last).inDays;
  }

  DateTime? _lastSaleDate(Client client, List<Sale> sales) {
    final List<Sale> clientSales = sales
        .where(
          (Sale sale) =>
              sale.clientId == client.id ||
              (sale.client != null && sale.client == client.name),
        )
        .toList();

    if (clientSales.isEmpty) {
      return null;
    }

    clientSales.sort((Sale a, Sale b) => b.date.compareTo(a.date));
    return clientSales.first.date;
  }

  String _dateLabel(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Fev',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aout',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
  }

  String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty
        ? 'CL'
        : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> _showRepaymentSheet(BuildContext context, Client client) async {
    final TextEditingController amountCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final MediaQueryData media = MediaQuery.of(context);
        final double screenWidth = media.size.width;
        final double horizontalPadding = screenWidth < 380 ? 16 : 24;
        final double maxHeight = screenWidth < 380
            ? media.size.height * 0.85
            : screenWidth < 600
            ? media.size.height * 0.80
            : media.size.height * 0.75;

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
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
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: _pumpkin,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Remboursement',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          children: <Widget>[
                            const Text(
                              'Crédit actuel',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.read<AppSettingsProvider>().formatMoney(
                                client.creditBalance,
                                decimals: 0,
                              ),
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Montant à rembourser',
                          prefixIcon: Icon(Icons.payments_rounded),
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
                    final double? amount = double.tryParse(
                      amountCtrl.text.trim(),
                    );
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez entrer un montant valide.'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    try {
                      await context.read<ClientsProvider>().repayClientCredit(
                        clientId: client.id,
                        amount: amount,
                      );
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erreur lors du remboursement.'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Remboursement enregistré avec succès.'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  child: const Text('Valider le remboursement'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopClientStat extends StatelessWidget {
  const _DesktopClientStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
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
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
