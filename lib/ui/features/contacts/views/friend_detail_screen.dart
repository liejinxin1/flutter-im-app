import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';
import '../widgets/remark_dialog.dart';

class FriendDetailScreen extends StatefulWidget {
  const FriendDetailScreen({
    super.key,
    required this.userId,
    required this.profiles,
    required this.contacts,
    required this.onOpenChat,
  });

  final String userId;
  final ProfileRepository profiles;
  final ContactRepository contacts;
  final ValueChanged<String> onOpenChat;

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    final profile = await widget.profiles.load(
      widget.userId,
      forceRefresh: refresh,
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  Future<void> _editRemark() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => RemarkDialog(initialRemark: _profile?.remark),
    );
    if (value == null || !mounted) return;
    try {
      await widget.contacts.updateRemark(widget.userId, value);
      await widget.profiles.updateRemark(widget.userId, value);
      if (!mounted) return;
      setState(() {
        _profile = (_profile ?? UserProfile(userId: widget.userId)).copyWith(
          remark: value,
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.remarkUpdated)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.requestUpdateFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = _profile;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightStatus,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        bottomNavigationBar: const SystemNavBarInset(),
        body: Column(
          children: [
            GradientHeader(
              title: l10n.friendProfile,
              leading: IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .18),
                ),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            Expanded(
              child: AppContentFrame(
                maxWidth: 760,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                        children: [
                          Center(
                            child: UserAvatar(
                              userId: widget.userId,
                              radius: 48,
                              foregroundImage:
                                  profile?.effectiveAvatarUrl == null
                                  ? null
                                  : NetworkImage(profile!.effectiveAvatarUrl!),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Text(
                              profile?.displayName ?? widget.userId,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              widget.userId,
                              style: const TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _InfoCard(
                            label: l10n.remark,
                            value: profile?.remark?.trim().isNotEmpty == true
                                ? profile!.remark!
                                : l10n.noRemark,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      widget.onOpenChat(widget.userId),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                  label: Text(l10n.sendMessage),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _editRemark,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: Text(l10n.editRemark),
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
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    ),
  );
}
