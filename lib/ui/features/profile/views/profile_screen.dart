import 'package:flutter/material.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../view_models/profile_view_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.viewModel,
    required this.onLogout,
  });

  final ProfileViewModel viewModel;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: Column(
      children: [
        GradientHeader(title: context.l10n.profileTitle),
        Expanded(
          child: AppContentFrame(
            maxWidth: 760,
            child: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) {
                final profile = viewModel.profile;
                final displayName = profile?.displayName ?? viewModel.userId;
                final avatarUrl = profile?.effectiveAvatarUrl;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D162A44),
                            blurRadius: 16,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          UserAvatar(
                            userId: viewModel.userId,
                            radius: 45,
                            foregroundImage: avatarUrl == null
                                ? null
                                : NetworkImage(avatarUrl),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF252936),
                            ),
                          ),
                          if (displayName != viewModel.userId) ...[
                            const SizedBox(height: 4),
                            Text(
                              viewModel.userId,
                              style: const TextStyle(
                                color: Color(0xFF9297A3),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            context.l10n.agoraChatAccount,
                            style: const TextStyle(
                              color: Color(0xFF9297A3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      title: context.l10n.userIdTitle,
                      subtitle: context.l10n.userIdSubtitle,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      title: context.l10n.accountStatus,
                      subtitle: context.l10n.signedInAs(viewModel.userId),
                    ),
                    const SizedBox(height: 26),
                    OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(context.l10n.signOut),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDD6262),
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFFF0D6D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.brandBlueLight),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF9297A3), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
