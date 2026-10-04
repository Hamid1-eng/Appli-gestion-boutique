import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../providers/app_settings_provider.dart';
import '../providers/suppliers_provider.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key, this.onAddSupplierPressed});

  final VoidCallback? onAddSupplierPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1360;
    final bool isCompact = MediaQuery.sizeOf(context).width < 380;
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final SuppliersProvider suppliersProvider = context
        .watch<SuppliersProvider>();
    final List<Supplier> suppliers = suppliersProvider.suppliers;
    final double totalDebt = suppliersProvider.totalDebt;
    final int totalActiveOrders = suppliersProvider.totalActiveOrders;

    if (isDesktop) {
      return _buildDesktop(
        context,
        appSettings: appSettings,
        suppliers: suppliers,
        totalDebt: totalDebt,
        totalActiveOrders: totalActiveOrders,
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
            Text(
              'Gestion des Fournisseurs',
              style: TextStyle(
                fontSize: isCompact ? 22 : 26,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.03),
            const SizedBox(height: 4),
            const Text(
              'Gerez vos relations et dettes fournisseurs',
              style: TextStyle(color: Color(0xFF475569), fontSize: 14),
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFFFF7A12),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF9A3412).withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'TOTAL DETTE FOURNISSEUR',
                    style: TextStyle(
                      color: Color(0xFF7C2D12),
                      letterSpacing: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appSettings.formatMoney(totalDebt, decimals: 0),
                    style: TextStyle(
                      color: const Color(0xFF431407),
                      fontSize: isCompact ? 40 : 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '-12% vs mois dernier',
                    style: TextStyle(
                      color: Color(0xFF431407),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 360.ms),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _statCard(
                    title: 'FOURNISSEURS',
                    value: suppliers.length.toString().padLeft(2, '0'),
                    suffix: 'actifs',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: 'COMMANDES',
                    value: totalActiveOrders.toString().padLeft(2, '0'),
                    suffix: 'en cours',
                  ),
                ),
              ],
            ).animate(delay: 180.ms).fadeIn(duration: 360.ms),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A12),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: () {
                  if (onAddSupplierPressed != null) {
                    onAddSupplierPressed!();
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ajout fournisseur indisponible.'),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  'Ajouter Fournisseur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ).animate(delay: 230.ms).fadeIn(),
            const SizedBox(height: 22),
            Row(
              children: const <Widget>[
                Expanded(
                  child: Text(
                    'LISTE DES PARTENAIRES',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
              ],
            ).animate(delay: 260.ms).fadeIn(),
            const SizedBox(height: 12),
            ...suppliers.asMap().entries.map(
              (MapEntry<int, Supplier> entry) =>
                  _supplierCard(context, entry.value, entry.key, appSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(
    BuildContext context, {
    required AppSettingsProvider appSettings,
    required List<Supplier> suppliers,
    required double totalDebt,
    required int totalActiveOrders,
  }) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF3F4F7),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 120),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _desktopTopCard(
                    title: 'DETTES FOURNISSEURS TOTALES',
                    value: appSettings.formatMoney(totalDebt, decimals: 0),
                    subtitle: '+12% depuis le mois dernier',
                    accent: const Color(0xFFFF7315),
                    textLight: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _desktopTopCard(
                    title: 'NOMBRE TOTAL',
                    value: '${suppliers.length} Fournisseurs',
                    subtitle: 'Partenaires actifs',
                    accent: const Color(0xFFFFFFFF),
                    textLight: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _desktopTopCard(
                    title: 'COMMANDES EN COURS',
                    value: '$totalActiveOrders',
                    subtitle: '65% de la capacité logistique atteinte',
                    accent: const Color(0xFFBFDBFE),
                    textLight: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Partenaires Commerciaux',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos relations d\'approvisionnement et paiements.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddSupplierPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7315),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Ajouter Fournisseur',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: suppliers.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (BuildContext context, int index) {
                if (index == suppliers.length) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD1D5DB),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: onAddSupplierPressed,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFE2E8F0),
                              child: Icon(
                                Icons.add_rounded,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Ajouter un nouveau fournisseur',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final Supplier supplier = suppliers[index];
                return _desktopSupplierCard(supplier, appSettings);
              },
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
                          flex: 3,
                          child: Text(
                            'FOURNISSEUR',
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
                  ...suppliers.take(3).toList().asMap().entries.map((entry) {
                    final Supplier supplier = entry.value;
                    final String status = supplier.currentDebt > 0
                        ? 'EN ATTENTE'
                        : 'PAYÉ';
                    final Color statusBg = supplier.currentDebt > 0
                        ? const Color(0xFFFFF7ED)
                        : const Color(0xFFECFDF3);
                    final Color statusFg = supplier.currentDebt > 0
                        ? const Color(0xFFB45309)
                        : const Color(0xFF047857);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 3,
                            child: Text(
                              supplier.name,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '0${entry.key + 5} Oct 2023',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              appSettings.formatMoney(
                                (supplier.currentDebt * 0.2).clamp(450, 12000),
                                decimals: 0,
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
                                color: statusBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: statusFg,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _desktopTopCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accent,
    required bool textLight,
  }) {
    final bool orange = accent == const Color(0xFFFF7315);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: orange ? const Color(0xFFFF7315) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: orange ? const Color(0xFFFF7315) : const Color(0xFFE8ECF3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: textLight
                  ? const Color(0xFFFFEDD5)
                  : const Color(0xFF94A3B8),
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textLight ? Colors.white : const Color(0xFF111827),
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: textLight
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSupplierCard(
    Supplier supplier,
    AppSettingsProvider appSettings,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF111827),
                child: Text(
                  supplier.badgeText,
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    supplier.category.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            supplier.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            supplier.email ?? supplier.phone ?? 'Contact indisponible',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFEFF2F6)),
          const SizedBox(height: 8),
          const Text(
            'SOLDE DÛ',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appSettings.formatMoney(supplier.currentDebt, decimals: 0),
            style: TextStyle(
              color: supplier.currentDebt > 0
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF111827),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF2),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.6,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 42,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supplierCard(
    BuildContext context,
    Supplier supplier,
    int index,
    AppSettingsProvider appSettings,
  ) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFD),
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF111827),
                    ),
                    child: Center(
                      child: Text(
                        supplier.badgeText,
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          supplier.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplier.category,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert_rounded),
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'DETTE ACTUELLE',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appSettings.formatMoney(
                            supplier.currentDebt,
                            decimals: 0,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w800,
                            fontSize: 38,
                            height: 0.95,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _actionCircle(
                    icon: Icons.mail_outline_rounded,
                    onTap: () {
                      final String? email = supplier.email;
                      if (email == null || email.isEmpty) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Email: $email')));
                    },
                  ),
                  const SizedBox(width: 10),
                  _actionCircle(
                    icon: Icons.call_rounded,
                    onTap: () {
                      final String? phone = supplier.phone;
                      if (phone == null || phone.isEmpty) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Telephone: $phone')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: (320 + (index * 60)).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.04, curve: Curves.easeOut);
  }

  Widget _actionCircle({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFFE8ECF0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Color(0xFF475569), size: 22),
      ),
    );
  }
}
