import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/friend_request_update.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/user_avatar.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({
    super.key,
    required this.requests,
    required this.onRespond,
  });

  final List<FriendRequestUpdate> requests;
  final Future<bool> Function(
    FriendRequestUpdate request, {
    required bool accept,
  })
  onRespond;

  @override
  Widget build(BuildContext context) {
    final sorted = [...requests]
      ..sort(
        (a, b) => (b.occurredAt ?? DateTime(0)).compareTo(
          a.occurredAt ?? DateTime(0),
        ),
      );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightStatus,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        bottomNavigationBar: const SystemNavBarInset(),
        body: Column(
          children: [
            GradientHeader(
              title: context.l10n.friendRequestsTitle,
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
                child: sorted.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.noPendingFriendRequests,
                          style: const TextStyle(color: AppColors.mutedText),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: sorted.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _RequestTile(
                          request: sorted[index],
                          onRespond: onRespond,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({required this.request, required this.onRespond});

  final FriendRequestUpdate request;
  final Future<bool> Function(
    FriendRequestUpdate request, {
    required bool accept,
  })
  onRespond;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    final success = await widget.onRespond(widget.request, accept: accept);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.requestUpdateFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final l10n = context.l10n;
    final pending = request.type == FriendRequestUpdateType.received;
    final title = request.isGroup
        ? (request.groupName?.isNotEmpty == true
              ? request.groupName!
              : request.groupId ?? request.userId)
        : request.userId;
    final subtitle = request.isGroup
        ? [
            l10n.groupInvitation,
            if (request.inviter?.isNotEmpty == true)
              l10n.invitedByUser(request.inviter!),
            if (request.reason?.isNotEmpty == true) request.reason!,
          ].join(' · ')
        : (request.reason?.isNotEmpty == true
              ? request.reason!
              : l10n.friendRequestLabel);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (request.isGroup)
            const CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.brandBlueLight,
              child: Icon(Icons.groups_2_rounded, color: Colors.white),
            )
          else
            UserAvatar(userId: request.userId, radius: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (request.isGroup) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.group_outlined,
                        size: 15,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (pending) ...[
            IconButton(
              tooltip: l10n.decline,
              onPressed: () => _respond(false),
              icon: const Icon(Icons.close_rounded, color: Color(0xFFD56969)),
            ),
            IconButton(
              tooltip: l10n.accept,
              onPressed: () => _respond(true),
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF35B883),
              ),
            ),
          ] else
            _StatusChip(type: request.type),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.type});

  final FriendRequestUpdateType type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = switch (type) {
      FriendRequestUpdateType.accepted => (
        l10n.requestStatusAccepted,
        const Color(0xFF35B883),
        Icons.check_circle_rounded,
      ),
      FriendRequestUpdateType.declined => (
        l10n.requestStatusDeclined,
        const Color(0xFFD56969),
        Icons.cancel_rounded,
      ),
      FriendRequestUpdateType.contactAdded => (
        l10n.requestStatusAdded,
        AppColors.brandBlueLight,
        Icons.person_add_alt_1_rounded,
      ),
      FriendRequestUpdateType.received => (
        l10n.requestStatusPending,
        AppColors.mutedText,
        Icons.schedule_rounded,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
