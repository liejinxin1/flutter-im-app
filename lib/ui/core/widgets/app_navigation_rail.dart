import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_theme.dart';

class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return NavigationRail(
      selectedIndex: index,
      onDestinationSelected: onChanged,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.brandBlueLight.withValues(alpha: .14),
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.only(top: 12, bottom: 18),
        child: Icon(Icons.forum_rounded, color: AppColors.brandBlue, size: 30),
      ),
      destinations: [
        _destination(
          icon: Icons.chat_bubble_rounded,
          label: l10n.chatsTab,
          badgeCount: chatsBadgeCount,
        ),
        _destination(
          icon: Icons.groups_rounded,
          label: l10n.groupsTab,
          badgeCount: groupsBadgeCount,
        ),
        _destination(
          icon: Icons.account_circle_outlined,
          label: l10n.profileTab,
        ),
        _destination(
          icon: Icons.menu_rounded,
          label: l10n.moreTab,
          badgeCount: moreBadgeCount,
        ),
      ],
    );
  }

  NavigationRailDestination _destination({
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) => NavigationRailDestination(
    icon: _badged(icon: icon, badgeCount: badgeCount),
    selectedIcon: _badged(
      icon: icon,
      badgeCount: badgeCount,
      color: AppColors.brandBlueLight,
    ),
    label: Text(label),
  );

  Widget _badged({
    required IconData icon,
    required int badgeCount,
    Color? color,
  }) {
    final child = Icon(icon, color: color);
    if (badgeCount <= 0) return child;
    return Badge.count(
      count: badgeCount,
      backgroundColor: const Color(0xFFFF5148),
      child: child,
    );
  }
}
