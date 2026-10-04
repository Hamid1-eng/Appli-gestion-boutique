import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class AdminSidebarItem {
  const AdminSidebarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
    this.primaryItemCount,
    this.adminName,
    this.adminEmail,
  });

  final List<AdminSidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;
  final int? primaryItemCount;
  final String? adminName;
  final String? adminEmail;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final int splitIndex = primaryItemCount == null
        ? items.length
        : primaryItemCount!.clamp(0, items.length);
    final List<AdminSidebarItem> primaryItems = items.sublist(0, splitIndex);
    final List<AdminSidebarItem> secondaryItems = items.sublist(splitIndex);

    return Container(
      width: 288,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2740),
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7315),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'AppliGestion',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.sidebarTagline.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF8EA0BF),
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ..._buildSection(primaryItems, 0, selectedIndex),
                  if (secondaryItems.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFF2D3A57)),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          color: Color(0xFF6D7E9B),
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._buildSection(secondaryItems, splitIndex, selectedIndex),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if ((adminName ?? '').isNotEmpty || (adminEmail ?? '').isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF22314E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFFF7315),
                    child: Text(
                      (adminName ?? 'A').trim().isEmpty
                          ? 'A'
                          : (adminName ?? 'A').trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          adminName ?? 'Administrateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          adminEmail ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8EA0BF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onLogout,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC4D0E6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.sidebarLogout),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSection(
    List<AdminSidebarItem> sectionItems,
    int baseIndex,
    int selectedIndex,
  ) {
    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < sectionItems.length; i++) {
      final int absoluteIndex = baseIndex + i;
      final bool selected = selectedIndex == absoluteIndex;
      final AdminSidebarItem item = sectionItems[i];

      widgets.add(
        Material(
          color: selected ? const Color(0xFFFF7315) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(absoluteIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: <Widget>[
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: selected ? Colors.white : const Color(0xFFB5C4DD),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFD7E1F2),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (i < sectionItems.length - 1) {
        widgets.add(const SizedBox(height: 6));
      }
    }
    return widgets;
  }
}
