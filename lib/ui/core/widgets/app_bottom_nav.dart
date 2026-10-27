import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    this.chatsBadgeCount = 0,
    this.groupsBadgeCount = 0,
    this.moreBadgeCount = 0,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int chatsBadgeCount;
  final int groupsBadgeCount;
  final int moreBadgeCount;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x140B2A45),
              blurRadius: 18,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            _NavItem(
              label: context.l10n.chatsTab,
              icon: Icons.chat_bubble_rounded,
              selected: index == 0,
              badgeCount: chatsBadgeCount,
              onTap: () => onChanged(0),
            ),
            _NavItem(
              label: context.l10n.groupsTab,
              icon: Icons.groups_rounded,
              selected: index == 1,
              badgeCount: groupsBadgeCount,
              onTap: () => onChanged(1),
            ),
            _NavItem(
              label: context.l10n.profileTab,
              icon: Icons.account_circle_outlined,
              selected: index == 2,
              badgeCount: 0,
              onTap: () => onChanged(2),
            ),
            _NavItem(
              label: context.l10n.moreTab,
              icon: Icons.menu_rounded,
              selected: index == 3,
              badgeCount: moreBadgeCount,
              onTap: () => onChanged(3),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlueLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -7,
                    right: -11,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 15),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5148),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
