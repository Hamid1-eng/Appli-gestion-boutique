import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final SalesProvider salesProvider = context.watch<SalesProvider>();
    final ExpensesProvider expensesProvider = context.watch<ExpensesProvider>();
    final ClientsProvider clientsProvider = context.watch<ClientsProvider>();
    final ProductsProvider productsProvider = context.watch<ProductsProvider>();
    final String welcomeName = _welcomeName(authProvider);

    final DateTime now = DateTime.now();
    final DateTime startDay = DateTime(now.year, now.month, now.day);
    final DateTime startWeek = startDay.subtract(
      Duration(days: now.weekday - 1),
    );
    final DateTime startMonth = DateTime(now.year, now.month);

    final DateTimeRange dayRange = DateTimeRange(
      start: startDay,
      end: now.add(const Duration(minutes: 1)),
    );
    final DateTimeRange weekRange = DateTimeRange(
      start: startWeek,
      end: now.add(const Duration(minutes: 1)),
    );
    final DateTimeRange monthRange = DateTimeRange(
      start: startMonth,
      end: now.add(const Duration(minutes: 1)),
    );
    final DateTimeRange prevDayRange = DateTimeRange(
      start: startDay.subtract(const Duration(days: 1)),
      end: startDay,
    );
    final DateTimeRange prevWeekRange = DateTimeRange(
      start: startWeek.subtract(const Duration(days: 7)),
      end: startWeek,
    );

    final double daySales = salesProvider.salesAmountFor(dayRange);
    final double weekSales = salesProvider.salesAmountFor(weekRange);
    final double prevDaySales = salesProvider.salesAmountFor(prevDayRange);
    final double prevWeekSales = salesProvider.salesAmountFor(prevWeekRange);
    final double monthSales = salesProvider.salesAmountFor(monthRange);
    final double monthExpenses = expensesProvider.expenseAmountFor(monthRange);
    final double monthProfit =
        monthSales - monthExpenses - salesProvider.productCostFor(monthRange);
    final double totalClientCredit = clientsProvider.totalClientCredit;
    final List<MapEntry<String, int>> topProducts = salesProvider.topProducts();
    final List<double> weeklySeries = salesProvider.dailySalesForLastDays(7);

    final double monthObjective = monthSales <= 0 ? 1000000 : monthSales * 1.33;
    final double objectiveProgress = (monthSales / monthObjective).clamp(0, 1);

    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1360;
    if (isDesktop) {
      return _WebDashboard(
        welcomeName: welcomeName,
        daySales: daySales,
        weekSales: weekSales,
        monthSales: monthSales,
        monthExpenses: monthExpenses,
        monthProfit: monthProfit,
        totalClientCredit: totalClientCredit,
        prevDaySales: prevDaySales,
        prevWeekSales: prevWeekSales,
        weeklySeries: weeklySeries,
        lowStockProducts: productsProvider.lowStockProducts,
        recentSales: salesProvider.sales,
        appSettings: appSettings,
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => Future<void>.value(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: <Widget>[
            Text(
              'Bonjour $welcomeName',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 30,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Tableau de bord',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7ECF1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: Color(0xFFEA580C),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '24°C',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _KpiTile(
                    icon: Icons.today_rounded,
                    label: 'VENTES DU JOUR',
                    value: _money(daySales, appSettings),
                    delta: _percentDelta(daySales, prevDaySales),
                    positive: daySales >= prevDaySales,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiTile(
                    icon: Icons.view_week_rounded,
                    label: 'LA SEMAINE',
                    value: _money(weekSales, appSettings),
                    delta: _percentDelta(weekSales, prevWeekSales),
                    positive: weekSales >= prevWeekSales,
                    highlight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MonthSalesBanner(
              amount: _money(monthSales, appSettings),
              progress: objectiveProgress,
              progressText:
                  '${(objectiveProgress * 100).toStringAsFixed(0)}% Objectif',
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SimpleTile(
                    icon: Icons.trending_down_rounded,
                    label: 'DÉPENSES MOIS',
                    value: _money(monthExpenses, appSettings),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SimpleTile(
                    icon: Icons.credit_score_rounded,
                    label: 'CRÉDIT CLIENT',
                    value: _money(totalClientCredit, appSettings),
                    iconColor: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProfitBanner(amount: _money(monthProfit, appSettings)),
            const SizedBox(height: 16),
            _WeeklyChart(series: weeklySeries),
            const SizedBox(height: 16),
            _LowStockCard(products: productsProvider.lowStockProducts),
            const SizedBox(height: 16),
            _TopProductsCard(topProducts: topProducts),
          ],
        ),
      ),
    );
  }

  String _money(double value, AppSettingsProvider appSettings) {
    return appSettings.formatMoney(value, decimals: 0);
  }

  String _percentDelta(double current, double previous) {
    if (previous <= 0) {
      return '0%';
    }
    final double delta = ((current - previous) / previous) * 100;
    return '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%';
  }

  String _welcomeName(AuthProvider authProvider) {
    final String displayName = authProvider.currentAdminDisplayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = authProvider.user?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Admin';
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.positive,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool positive;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: highlight ? const Color(0xFFFF6A00) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFECEFF3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF475569), size: 23),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positive
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    color: positive
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSalesBanner extends StatelessWidget {
  const _MonthSalesBanner({
    required this.amount,
    required this.progress,
    required this.progressText,
  });

  final String amount;
  final double progress;
  final String progressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7410),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'VENTES DU MOIS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 58,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    backgroundColor: const Color(0xFFFFD0AA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                progressText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = const Color(0xFF64748B),
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitBanner extends StatelessWidget {
  const _ProfitBanner({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF00392D), Color(0xFF012D23)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'BÉNÉFICE NET ESTIMÉ',
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '+ $amount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0B6A53),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.stars_rounded, color: Color(0xFF6EE7B7)),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final List<String> days = <String>[
      'LUN',
      'MAR',
      'MER',
      'JEU',
      'VEN',
      'SAM',
      'DIM',
    ];
    final double max = series.isEmpty
        ? 1
        : series.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: const <Widget>[
              Text(
                'Ventes (7 derniers jours)',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(7, (int index) {
                final double value = index < series.length ? series[index] : 0;
                final bool highlighted = index == 3;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Container(
                          height: max == 0 ? 8 : (value / max) * 150,
                          decoration: BoxDecoration(
                            color: highlighted
                                ? const Color(0xFFFF7410)
                                : const Color(0xFFE8CBA1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          days[index],
                          style: TextStyle(
                            color: highlighted
                                ? const Color(0xFF111827)
                                : const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.products});

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: const <Widget>[
              Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text(
                'Stock bas',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Spacer(),
              Text(
                'VOIR TOUT',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Aucun stock critique.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          else
            ...products.take(3).map((dynamic product) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${product.stock} unités restantes',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.topProducts});

  final List<MapEntry<String, int>> topProducts;

  @override
  Widget build(BuildContext context) {
    final int max = topProducts.isEmpty
        ? 1
        : topProducts
              .map((MapEntry<String, int> e) => e.value)
              .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Top produits vendus',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Text(
              'Aucune vente enregistrée.',
              style: TextStyle(color: Color(0xFF6B7280)),
            )
          else
            ...topProducts.take(3).map((MapEntry<String, int> item) {
              final double pct = (item.value / max) * 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFEA580C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (item.value / max).clamp(0, 1),
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF7410),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _WebDashboard extends StatelessWidget {
  const _WebDashboard({
    required this.welcomeName,
    required this.daySales,
    required this.weekSales,
    required this.monthSales,
    required this.monthExpenses,
    required this.monthProfit,
    required this.totalClientCredit,
    required this.prevDaySales,
    required this.prevWeekSales,
    required this.weeklySeries,
    required this.lowStockProducts,
    required this.recentSales,
    required this.appSettings,
  });

  final String welcomeName;
  final double daySales;
  final double weekSales;
  final double monthSales;
  final double monthExpenses;
  final double monthProfit;
  final double totalClientCredit;
  final double prevDaySales;
  final double prevWeekSales;
  final List<double> weeklySeries;
  final List<Product> lowStockProducts;
  final List<Sale> recentSales;
  final AppSettingsProvider appSettings;

  String _money(double value) {
    return appSettings.formatMoney(value, decimals: 0);
  }

  String _compactMoney(double value) {
    final double abs = value.abs();
    final String suffix = appSettings.currencyLabel;
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M $suffix';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K $suffix';
    }
    return _money(value);
  }

  String _percentDelta(double current, double previous) {
    if (previous <= 0) {
      return '+0%';
    }
    final double delta = ((current - previous) / previous) * 100;
    return '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 120),
        children: <Widget>[
          Text(
            'Bonjour $welcomeName',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tableau de bord',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.today_rounded,
                  label: 'VENTES DU JOUR',
                  value: _compactMoney(daySales),
                  delta: _percentDelta(daySales, prevDaySales),
                  deltaPositive: daySales >= prevDaySales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.calendar_view_week_rounded,
                  label: 'CETTE SEMAINE',
                  value: _compactMoney(weekSales),
                  delta: _percentDelta(weekSales, prevWeekSales),
                  deltaPositive: weekSales >= prevWeekSales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.date_range_rounded,
                  label: 'CE MOIS',
                  value: _compactMoney(monthSales),
                  delta: monthSales >= monthExpenses ? '+5%' : '-2%',
                  deltaPositive: monthSales >= monthExpenses,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.payments_outlined,
                  label: 'DÉPENSES',
                  value: _compactMoney(monthExpenses),
                  delta: monthExpenses <= monthSales ? '-3%' : '+4%',
                  deltaPositive: monthExpenses <= monthSales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.credit_score_rounded,
                  label: 'CRÉDIT CLIENT',
                  value: _compactMoney(totalClientCredit),
                  delta: totalClientCredit <= monthSales ? 'OK' : 'HAUT',
                  deltaPositive: totalClientCredit <= monthSales,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WebKpiCard(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'BÉNÉFICE NET',
                  value: _compactMoney(monthProfit),
                  delta: monthProfit >= 0 ? '+12%' : '-8%',
                  deltaPositive: monthProfit >= 0,
                  featured: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 3,
                child: _WebSalesAnalysisCard(series: weeklySeries),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _WebCriticalStockCard(products: lowStockProducts),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WebRecentSalesCard(sales: recentSales, money: _money),
        ],
      ),
    );
  }
}

class _WebKpiCard extends StatelessWidget {
  const _WebKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaPositive,
    this.featured = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool deltaPositive;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final Color bg = featured ? const Color(0xFFFF7315) : Colors.white;
    final Color fg = featured ? Colors.white : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: featured ? const Color(0xFFFF7315) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: featured
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFFF3F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: featured ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: featured
                      ? Colors.white.withValues(alpha: 0.16)
                      : (deltaPositive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  delta,
                  style: TextStyle(
                    color: featured
                        ? Colors.white
                        : (deltaPositive
                              ? const Color(0xFF166534)
                              : const Color(0xFFB91C1C)),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: featured
                  ? Colors.white.withValues(alpha: 0.86)
                  : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 30,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebSalesAnalysisCard extends StatelessWidget {
  const _WebSalesAnalysisCard({required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    final List<String> days = <String>[
      'LUN',
      'MAR',
      'MER',
      'JEU',
      'VEN',
      'SAM',
      'DIM',
    ];
    final double max = series.isEmpty
        ? 1
        : series.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 420,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: const <Widget>[
              Text(
                'Analyse des ventes',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              _TabPill(text: 'Semaine', active: true),
              SizedBox(width: 8),
              _TabPill(text: 'Mois', active: false),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Performances des 7 derniers jours',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(7, (int index) {
                final double value = index < series.length ? series[index] : 0;
                final bool highlight = index == 3;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          height: max == 0 ? 10 : (value / max) * 245,
                          decoration: BoxDecoration(
                            color: highlight
                                ? const Color(0xFFFF7315)
                                : const Color(0xFFE3E8F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          days[index],
                          style: TextStyle(
                            color: highlight
                                ? const Color(0xFF111827)
                                : const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEFF2F7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? const Color(0xFF334155) : const Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WebCriticalStockCard extends StatelessWidget {
  const _WebCriticalStockCard({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Stock critique',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'ALERTE',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Articles à commander immédiatement',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun produit en seuil critique.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : Column(
                    children: products.take(4).map((Product product) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 10),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Réf: ${product.id}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${product.stock} unités',
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Voir tout l\'inventaire'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebRecentSalesCard extends StatelessWidget {
  const _WebRecentSalesCard({required this.sales, required this.money});

  final List<Sale> sales;
  final String Function(double value) money;

  @override
  Widget build(BuildContext context) {
    final List<Sale> recent = sales.take(5).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Ventes Récentes',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Exporter CSV')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.point_of_sale_rounded),
                label: const Text('Nouvelle Vente'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Text(
                    'CLIENT',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRODUITS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Aucune vente enregistrée.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ...recent.map((Sale sale) {
              final bool paid = !sale.isCredit;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: const Color(0xFFEFF2F6)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: Text(
                        (sale.client ?? 'Client comptant').trim().isEmpty
                            ? 'Client comptant'
                            : sale.client!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '${sale.productName} x${sale.quantity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF334155)),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        money(sale.amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paid
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          paid ? 'PAYÉ' : 'EN ATTENTE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: paid
                                ? const Color(0xFF166534)
                                : const Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
