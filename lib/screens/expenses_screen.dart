import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/app_settings_provider.dart';
import '../providers/expenses_provider.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1360;
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final expensesProvider = context.watch<ExpensesProvider>();
    final List<Expense> expenses = expensesProvider.expenses;
    final DateTime now = DateTime.now();

    final double currentMonthTotal = _sumForMonth(
      expenses,
      year: now.year,
      month: now.month,
    );
    final DateTime previousMonthRef = DateTime(now.year, now.month - 1, 1);
    final double previousMonthTotal = _sumForMonth(
      expenses,
      year: previousMonthRef.year,
      month: previousMonthRef.month,
    );

    final double variation = previousMonthTotal == 0
        ? 0
        : ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100;
    final double todayTotal = expenses
        .where(
          (Expense expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day,
        )
        .fold<double>(0, (double sum, Expense expense) => sum + expense.amount);

    final String topCategory = _topCategory(expenses);

    if (isDesktop) {
      return _buildDesktop(
        context,
        appSettings: appSettings,
        expenses: expenses,
        currentMonthTotal: currentMonthTotal,
        variation: variation,
        todayTotal: todayTotal,
        topCategory: topCategory,
      );
    }

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF2F4F7),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 20,
            14,
            isCompact ? 16 : 20,
            120,
          ),
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFB44700), Color(0xFFE85A14)],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF7C2D12).withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'TOTAL CE MOIS',
                    style: TextStyle(
                      color: Color(0xFFFFEDD5),
                      letterSpacing: 1.8,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appSettings.formatMoney(currentMonthTotal, decimals: 0),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 36 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(0)}% vs mois dernier',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.03),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _statCard(
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFFEA580C),
                    title: 'AUJOURD\'HUI',
                    value: appSettings.formatMoney(todayTotal, decimals: 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFFEA580C),
                    title: 'TOP CATÉGORIE',
                    value: topCategory,
                  ),
                ),
              ],
            ).animate(delay: 120.ms).fadeIn(duration: 360.ms),
            const SizedBox(height: 20),
            Row(
              children: const <Widget>[
                Expanded(
                  child: Text(
                    'Dépenses Récentes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  'Tout voir',
                  style: TextStyle(
                    color: Color(0xFFFF7315),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ).animate(delay: 180.ms).fadeIn(),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Aucune dépense enregistrée.',
                    style: TextStyle(color: const Color(0xFF94A3B8)),
                  ),
                ),
              ).animate(delay: 220.ms).fadeIn()
            else
              ...expenses.asMap().entries.map(
                (MapEntry<int, Expense> entry) =>
                    _expenseTile(context, entry.value, entry.key, appSettings),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required AppSettingsProvider appSettings,
    required List<Expense> expenses,
    required double currentMonthTotal,
    required double variation,
    required double todayTotal,
    required String topCategory,
  }) {
    final List<Expense> recent = expenses.take(8).toList();

    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF3F4F7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Tableau de Bord Financier',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Surveillez et gérez vos flux de trésorerie en temps réel.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7315),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text(
                    'Nouvelle Dépense',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _DesktopExpenseStat(
                    title: 'TOTAL DÉPENSES DU MOIS',
                    value: appSettings.formatMoney(
                      currentMonthTotal,
                      decimals: 2,
                    ),
                    subtitle:
                        '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(0)}% vs mois dernier',
                    subtitleColor: variation <= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    icon: Icons.receipt_long_rounded,
                    iconBg: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DesktopExpenseStat(
                    title: 'DÉPENSES DU JOUR',
                    value: appSettings.formatMoney(todayTotal, decimals: 2),
                    subtitle: 'Mise à jour en temps réel',
                    subtitleColor: const Color(0xFF64748B),
                    icon: Icons.today_rounded,
                    iconBg: const Color(0xFFE0F2FE),
                    iconColor: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DesktopExpenseStat(
                    title: 'CATÉGORIE LA PLUS COÛTEUSE',
                    value: topCategory,
                    subtitle: 'Donnée sur la période récente',
                    subtitleColor: const Color(0xFF64748B),
                    icon: Icons.category_rounded,
                    iconBg: const Color(0xFFE2E8F0),
                    iconColor: const Color(0xFF64748B),
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 2,
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
                          flex: 4,
                          child: Text(
                            'DESCRIPTION',
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
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEFF2F6)),
                  if (recent.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Text(
                        'Aucune dépense enregistrée.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ...recent.map((Expense expense) {
                      final ({IconData icon, Color color}) iconInfo =
                          _iconForType(expense.type);
                      final ({String label, Color textColor, Color bgColor})
                      status = _statusForExpense(expense);

                      final String description =
                          (expense.note != null &&
                              expense.note!.trim().isNotEmpty)
                          ? expense.note!.trim()
                          : expense.type;

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
                              flex: 2,
                              child: Text(
                                _dateLabel(expense.date),
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      iconInfo.icon,
                                      color: iconInfo.color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  expense.type,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF334155),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                appSettings.formatMoney(
                                  expense.amount,
                                  decimals: 2,
                                ),
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
                                  color: status.bgColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  status.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: status.textColor,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Affichage de 1 à ${recent.length} sur ${expenses.length} dépenses',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _pageButton('<', active: false),
                        const SizedBox(width: 6),
                        _pageButton('1', active: true),
                        const SizedBox(width: 6),
                        _pageButton('2', active: false),
                        const SizedBox(width: 6),
                        _pageButton('>', active: false),
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8ECF3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Répartition par Catégorie',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'VOIR LE RAPPORT COMPLET',
                              style: TextStyle(
                                color: Color(0xFFC2410C),
                                fontSize: 11,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 210,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFFED7AA),
                                Color(0xFFFCE7F3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'TENDANCE TRIMESTRIELLE\nOptimisation de 15%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7C2D12),
                                fontSize: 24,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 280,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF0F172A), Color(0xFF001A3D)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.insights_rounded, color: Color(0xFFFF7315)),
                        SizedBox(height: 12),
                        Text(
                          'IA Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Votre catégorie moyenne “Logistique” a diminué de 4% ce mois-ci grâce à la renégociation des contrats.',
                          style: TextStyle(
                            color: Color(0xFFBFDBFE),
                            fontSize: 14,
                            height: 1.5,
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

  Widget _pageButton(String label, {required bool active}) {
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

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseTile(
    BuildContext context,
    Expense expense,
    int index,
    AppSettingsProvider appSettings,
  ) {
    final ({IconData icon, Color color}) iconInfo = _iconForType(expense.type);
    final ({String label, Color textColor, Color bgColor}) status =
        _statusForExpense(expense);

    final String title =
        (expense.note != null && expense.note!.trim().isNotEmpty)
        ? expense.note!.trim()
        : expense.type;

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFD),
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              if (index == 0)
                Container(
                  width: 4,
                  height: 94,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                )
              else
                const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(iconInfo.icon, color: iconInfo.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${expense.type} • ${_dateLabel(expense.date)}',
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            appSettings.formatMoney(
                              expense.amount,
                              decimals: 0,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: status.bgColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status.label,
                              style: TextStyle(
                                color: status.textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
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
        )
        .animate(delay: (220 + (index * 50)).ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, curve: Curves.easeOut);
  }

  static double _sumForMonth(
    List<Expense> expenses, {
    required int year,
    required int month,
  }) {
    return expenses
        .where((Expense e) => e.date.year == year && e.date.month == month)
        .fold<double>(0, (double sum, Expense e) => sum + e.amount);
  }

  static String _topCategory(List<Expense> expenses) {
    if (expenses.isEmpty) {
      return 'Aucune';
    }

    final Map<String, double> byType = <String, double>{};
    for (final Expense expense in expenses) {
      byType[expense.type] = (byType[expense.type] ?? 0) + expense.amount;
    }

    final List<MapEntry<String, double>> sorted = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  static ({IconData icon, Color color}) _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'transport':
      case 'logistics':
        return (
          icon: Icons.local_shipping_rounded,
          color: const Color(0xFF64748B),
        );
      case 'loyer':
      case 'bureau':
        return (icon: Icons.apartment_rounded, color: const Color(0xFF64748B));
      case 'salaire':
      case 'paie':
        return (icon: Icons.badge_rounded, color: const Color(0xFF64748B));
      case 'courant':
      case 'electricite':
      case 'électricité':
      case 'utilities':
        return (icon: Icons.bolt_rounded, color: const Color(0xFF64748B));
      case 'tech':
      case 'informatique':
        return (icon: Icons.laptop_rounded, color: const Color(0xFF64748B));
      default:
        return (
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF64748B),
        );
    }
  }

  static ({String label, Color textColor, Color bgColor}) _statusForExpense(
    Expense expense,
  ) {
    final String raw = (expense.note ?? '').toLowerCase();

    if (raw.contains('refused') || raw.contains('refuse')) {
      return (
        label: 'REFUSED',
        textColor: const Color(0xFFBE123C),
        bgColor: const Color(0xFFFFF1F2),
      );
    }

    if (raw.contains('pending') || raw.contains('en attente')) {
      return (
        label: 'PENDING',
        textColor: const Color(0xFFB45309),
        bgColor: const Color(0xFFFFF7ED),
      );
    }

    return (
      label: 'PAID',
      textColor: const Color(0xFF047857),
      bgColor: const Color(0xFFECFDF3),
    );
  }

  static String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Hier';
    }

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

    return '${date.day} ${months[date.month - 1]}';
  }
}

class _DesktopExpenseStat extends StatelessWidget {
  const _DesktopExpenseStat({
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
