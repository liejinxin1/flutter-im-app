import 'package:flutter/material.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
    leading: UserAvatar(
      userId: conversation.id,
      radius: 30,
      foregroundImage: conversation.avatarUrl == null
          ? null
          : NetworkImage(conversation.avatarUrl!),
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            conversation.name?.isNotEmpty == true
                ? conversation.name!
                : conversation.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (conversation.lastActivity != null)
          Text(
            _formatTime(conversation.lastActivity!),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
      ],
    ),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _preview(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              constraints: const BoxConstraints(minWidth: 20),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  /// Matches the kit: today shows only time, older rows show time + MM/dd.
  String _preview(BuildContext context) {
    if (conversation.lastMessage.isNotEmpty) return conversation.lastMessage;
    return switch (conversation.lastMessageKind) {
      ChatMessageKind.image => context.l10n.imageMessage,
      ChatMessageKind.voice => context.l10n.voiceMessage,
      ChatMessageKind.file => context.l10n.fileMessage,
      ChatMessageKind.video => context.l10n.videoMessage,
      ChatMessageKind.location => context.l10n.locationMessage,
      ChatMessageKind.contact => context.l10n.contactMessage,
      ChatMessageKind.custom => context.l10n.customMessage,
      ChatMessageKind.system => context.l10n.systemMessage,
      ChatMessageKind.unknown => context.l10n.unsupportedMessage,
      _ => context.l10n.startConversation,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(time.year, time.month, time.day);
    final clock =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    if (day == today) return clock;
    return '$clock ${time.month.toString().padLeft(2, '0')}/'
        '${time.day.toString().padLeft(2, '0')}';
  }
}
