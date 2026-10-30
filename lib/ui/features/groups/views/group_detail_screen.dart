import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/group_member.dart';
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
    this.currentUserId,
    this.memberCount,
    this.onOpenMember,
  });

  final String groupId;
  final String? groupName;
  final GroupRepository groups;
  final String? currentUserId;
  final int? memberCount;
  final ValueChanged<String>? onOpenMember;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  List<GroupMember> _members = const [];
  late String? _groupName = widget.groupName;
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
      if (!mounted) return;
      setState(() {
        _members = members;
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
                  ? IconButton(
                      tooltip: l10n.editGroupName,
                      onPressed: _editName,
                      icon: const Icon(Icons.edit_outlined),
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
                          onOpen: widget.onOpenMember == null
                              ? null
                              : () => widget.onOpenMember!(member.userId),
                          onRemove: () => _removeMember(member),
                          onToggleAdmin: () => _setAdmin(member),
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
    required this.onOpen,
    required this.onRemove,
    required this.onToggleAdmin,
  });

  final GroupMember member;
  final bool isMe;
  final bool canManage;
  final bool isOwner;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;
  final VoidCallback onToggleAdmin;

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
        ],
      ),
      subtitle: Text(phone.isEmpty ? '' : phone),
      trailing: showActions
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'remove') onRemove();
                if (value == 'admin') onToggleAdmin();
              },
              itemBuilder: (context) => [
                if (isOwner)
                  PopupMenuItem(
                    value: 'admin',
                    child: Text(
                      member.isAdmin ? l10n.removeAdmin : l10n.makeAdmin,
                    ),
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
