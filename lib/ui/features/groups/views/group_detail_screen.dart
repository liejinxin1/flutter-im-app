import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/group_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.groups,
    required this.profiles,
    this.memberCount,
    this.onOpenMember,
  });

  final String groupId;
  final String? groupName;
  final GroupRepository groups;
  final ProfileRepository profiles;
  final int? memberCount;
  final ValueChanged<String>? onOpenMember;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<UserProfile> _members = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await widget.groups.loadMemberIds(widget.groupId);
      final profiles = await widget.profiles.loadAll(ids);
      if (!mounted) return;
      setState(() {
        _members = ids
            .map((id) => profiles[id] ?? UserProfile(userId: id))
            .toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.contactsLoadFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.groupName?.trim().isNotEmpty == true
        ? widget.groupName!.trim()
        : widget.groupId;
    final count = widget.memberCount ?? _members.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightStatus,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        bottomNavigationBar: const SystemNavBarInset(),
        body: Column(
          children: [
            GradientHeader(
              title: l10n.groupProfile,
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    Row(
                      children: [
                        UserAvatar(userId: widget.groupId, radius: 30),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.groupMembers(count),
                                style: const TextStyle(
                                  color: AppColors.mutedText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      l10n.groupMembersTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Center(
                        child: TextButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(_error!),
                        ),
                      )
                    else
                      for (final member in _members)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(
                            userId: member.userId,
                            radius: 20,
                            foregroundImage: member.effectiveAvatarUrl == null
                                ? null
                                : NetworkImage(member.effectiveAvatarUrl!),
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(member.userId),
                          onTap: widget.onOpenMember == null
                              ? null
                              : () => widget.onOpenMember!(member.userId),
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
