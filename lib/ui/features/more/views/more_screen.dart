import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.userId,
    required this.onLogout,
    required this.onFriendRequests,
    required this.onContacts,
    this.friendRequestCount = 0,
    this.displayName,
  });

  final String userId;
  final VoidCallback onLogout;
  final VoidCallback onFriendRequests;
  final VoidCallback onContacts;
  final int friendRequestCount;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          GradientHeader(title: l10n.moreTitle),
          Expanded(
            child: AppContentFrame(
              maxWidth: 760,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.brandBlue, AppColors.brandBlueLight],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'E-Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.signedInAs(
                                  displayName?.trim().isNotEmpty == true
                                      ? displayName!.trim()
                                      : userId,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xDFFFFFFF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MoreGroup(
                    children: [
                      _MoreTile(
                        icon: Icons.contacts_outlined,
                        title: l10n.contacts,
                        onTap: onContacts,
                      ),
                      _MoreTile(
                        icon: Icons.person_add_alt_1_rounded,
                        title: l10n.friendRequests,
                        onTap: onFriendRequests,
                        badgeCount: friendRequestCount,
                      ),
                      _MoreTile(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.privacySecurity,
                        onTap: () => _showComingSoon(context),
                      ),
                      _MoreTile(
                        icon: Icons.storage_outlined,
                        title: l10n.storage,
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MoreGroup(
                    children: [
                      _MoreTile(
                        icon: Icons.help_outline_rounded,
                        title: l10n.helpFeedback,
                        onTap: () => _showComingSoon(context),
                      ),
                      _MoreTile(
                        icon: Icons.info_outline_rounded,
                        title: l10n.aboutEchat,
                        subtitle: l10n.versionLabel('1.0.0'),
                        onTap: () => _showAbout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.signOut),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFDB6262),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.comingSoon),
      content: Text(context.l10n.comingSoonMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.ok),
        ),
      ],
    ),
  );

  void _showAbout(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: 'E-Chat',
    applicationVersion: '1.0.0',
    applicationLegalese: context.l10n.aboutLegalese,
  );
}

class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              indent: 58,
              endIndent: 16,
              color: Color(0xFFF0F2F5),
            ),
          children[i],
        ],
      ],
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeCount = 0,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    leading: Icon(icon, color: AppColors.brandBlueLight),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, style: const TextStyle(fontSize: 11)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (badgeCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5148),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8BDC5)),
      ],
    ),
  );
}
