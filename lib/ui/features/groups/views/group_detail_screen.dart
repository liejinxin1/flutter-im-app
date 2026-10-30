import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/group_member.dart';
import '../../../../domain/models/group_mute_state.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/contact_repository.dart';
import '../../../../domain/repositories/group_repository.dart';
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
    required this.contacts,
    this.currentUserId,
    this.memberCount,
    this.onOpenMember,
  });

  final String groupId;
  final String? groupName;
  final GroupRepository groups;
  final ContactRepository contacts;
  final String? currentUserId;
  final int? memberCount;
  final ValueChanged<String>? onOpenMember;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<GroupMember> _members = const [];
  late String? _groupName = widget.groupName;
  bool _allMuted = false;
  Set<String> _mutedUserIds = const {};
  bool _loading = true;
  String? _error;

  GroupMember? get _me => _members
      .where((member) => member.userId == widget.currentUserId)
      .firstOrNull;

  bool get _canManage => _me?.canManage ?? false;
  bool get _isOwner => _me?.isOwner ?? false;

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
      final members = await widget.groups.loadMembers(widget.groupId);
      GroupMuteState mute = const GroupMuteState(allMuted: false);
      try {
        mute = await widget.groups.loadMuteState(widget.groupId);
      } catch (_) {
        // Mute metadata is optional for members without admin permission.
      }
      if (!mounted) return;
      setState(() {
        _members = members;
        _allMuted = mute.allMuted;
        _mutedUserIds = mute.mutedUserIds;
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

  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _GroupNameDialog(initialValue: _groupName ?? ''),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    try {
      await widget.groups.updateName(widget.groupId, name.trim());
      if (!mounted) return;
      setState(() => _groupName = name.trim());
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await _confirm(
      context.l10n.removeMember,
      context.l10n.removeMemberConfirm(member.profile.displayName),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.groups.removeMember(widget.groupId, member.userId);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _setAdmin(GroupMember member) async {
    try {
      await widget.groups.setAdmin(
        widget.groupId,
        member.userId,
        admin: !member.isAdmin,
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _toggleAllMuted() async {
    try {
      await widget.groups.setAllMuted(widget.groupId, !_allMuted);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _toggleMemberMuted(GroupMember member) async {
    final muted = _mutedUserIds.contains(member.userId);
    try {
      await widget.groups.setMemberMuted(widget.groupId, member.userId, !muted);
      await _load();
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _inviteMembers() async {
    try {
      final contacts = await widget.contacts.loadContacts();
      if (!mounted) return;
      final existing = _members.map((member) => member.userId).toSet();
      final selected = await showModalBottomSheet<Set<String>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (context) => _InviteMembersSheet(
          contacts: contacts
              .where((contact) => !existing.contains(contact.userId))
              .toList(growable: false),
        ),
      );
      if (selected == null || selected.isEmpty || !mounted) return;
      await widget.groups.inviteMembers(widget.groupId, selected.toList());
      if (!mounted) return;
      _showError(context.l10n.inviteSent);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await _confirm(
      context.l10n.leaveGroup,
      context.l10n.leaveGroupConfirm,
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.groups.leaveGroup(widget.groupId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      _showError(context.l10n.requestUpdateFailed);
    }
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.confirm),
        ),
      ],
    ),
  );

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = _groupName?.trim().isNotEmpty == true
        ? _groupName!.trim()
        : widget.groupId;
    final count = _members.isEmpty
        ? (widget.memberCount ?? 0)
        : _members.length;
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
              trailing: _canManage
                  ? PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white,
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'name':
                            _editName();
                          case 'invite':
                            _inviteMembers();
                          case 'mute':
                            _toggleAllMuted();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'name',
                          child: Text(l10n.editGroupName),
                        ),
                        PopupMenuItem(
                          value: 'invite',
                          child: Text(l10n.inviteMembers),
                        ),
                        PopupMenuItem(
                          value: 'mute',
                          child: Text(
                            _allMuted ? l10n.unmuteAll : l10n.muteAll,
                          ),
                        ),
                      ],
                    )
                  : null,
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
                    if (_allMuted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.volume_off_rounded,
                              size: 17,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              l10n.allMembersMuted,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        _MemberTile(
                          member: member,
                          isMe: member.userId == widget.currentUserId,
                          canManage: _canManage,
                          isOwner: _isOwner,
                          isMuted: _mutedUserIds.contains(member.userId),
                          onOpen: widget.onOpenMember == null
                              ? null
                              : () => widget.onOpenMember!(member.userId),
                          onRemove: () => _removeMember(member),
                          onToggleAdmin: () => _setAdmin(member),
                          onToggleMute: () => _toggleMemberMuted(member),
                        ),
                    if (_me != null && !_isOwner) ...[
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _leaveGroup,
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.leaveGroup),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
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

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.canManage,
    required this.isOwner,
    required this.isMuted,
    required this.onOpen,
    required this.onRemove,
    required this.onToggleAdmin,
    required this.onToggleMute,
  });

  final GroupMember member;
  final bool isMe;
  final bool canManage;
  final bool isOwner;
  final bool isMuted;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;
  final VoidCallback onToggleAdmin;
  final VoidCallback onToggleMute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone = member.profile.phone?.trim() ?? '';
    final showActions =
        canManage && !member.isOwner && !isMe && (isOwner || !member.isAdmin);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(
        userId: member.userId,
        radius: 20,
        foregroundImage: member.profile.effectiveAvatarUrl == null
            ? null
            : NetworkImage(member.profile.effectiveAvatarUrl!),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.profile.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.isOwner) _RoleChip(label: l10n.groupOwner),
          if (member.isAdmin) _RoleChip(label: l10n.groupAdmin),
          if (isMuted && !member.isOwner)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(
                Icons.volume_off_rounded,
                size: 14,
                color: AppColors.mutedText,
              ),
            ),
        ],
      ),
      subtitle: Text(phone.isEmpty ? '' : phone),
      trailing: showActions
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') onRemove();
                if (value == 'admin') onToggleAdmin();
                if (value == 'mute') onToggleMute();
              },
              itemBuilder: (context) => [
                if (isOwner)
                  PopupMenuItem(
                    value: 'admin',
                    child: Text(
                      member.isAdmin ? l10n.removeAdmin : l10n.makeAdmin,
                    ),
                  ),
                PopupMenuItem(
                  value: 'mute',
                  child: Text(isMuted ? l10n.unmuteMember : l10n.muteMember),
                ),
                PopupMenuItem(value: 'remove', child: Text(l10n.removeMember)),
              ],
            )
          : null,
      onTap: onOpen,
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 6),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.brandBlueLight.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.brandBlueLight,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _InviteMembersSheet extends StatefulWidget {
  const _InviteMembersSheet({required this.contacts});

  final List<UserProfile> contacts;

  @override
  State<_InviteMembersSheet> createState() => _InviteMembersSheetState();
}

class _InviteMembersSheetState extends State<_InviteMembersSheet> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD5DAE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.inviteMembers,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.inviteMembersHint,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (widget.contacts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noContactsToInvite),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .45,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final contact in widget.contacts)
                      CheckboxListTile(
                        value: _selected.contains(contact.userId),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(contact.userId);
                            } else {
                              _selected.remove(contact.userId);
                            }
                          });
                        },
                        title: Text(contact.displayName),
                        subtitle: Text(contact.phone ?? ''),
                        secondary: UserAvatar(
                          userId: contact.userId,
                          radius: 18,
                          foregroundImage: contact.effectiveAvatarUrl == null
                              ? null
                              : NetworkImage(contact.effectiveAvatarUrl!),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop({..._selected}),
                child: Text(l10n.invite),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.editGroupName),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 64,
      decoration: InputDecoration(hintText: context.l10n.groupNameHint),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: Text(context.l10n.save),
      ),
    ],
  );
}
