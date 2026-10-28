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
  /// Text previews keep the message body; every other kind uses a WeChat-style
  /// localized placeholder instead of leaking a generic "message" string.
  String _preview(BuildContext context) {
    final kind = conversation.lastMessageKind;
    if (kind == null || kind == ChatMessageKind.text) {
      return conversation.lastMessage.isNotEmpty
          ? conversation.lastMessage
          : context.l10n.startConversation;
    }
    final l10n = context.l10n;
    return switch (kind) {
      ChatMessageKind.image => l10n.conversationPreviewImage,
      ChatMessageKind.voice => l10n.conversationPreviewVoice,
      ChatMessageKind.file => l10n.conversationPreviewFile,
      ChatMessageKind.video => l10n.conversationPreviewVideo,
      ChatMessageKind.location => l10n.conversationPreviewLocation,
      ChatMessageKind.contact => l10n.conversationPreviewContact,
      ChatMessageKind.custom => l10n.conversationPreviewCustom,
      ChatMessageKind.system =>
        conversation.lastMessageSystemType == 'recall'
            ? l10n.recalledMessage
            : conversation.lastMessage.isNotEmpty
            ? conversation.lastMessage
            : l10n.conversationPreviewSystem,
      ChatMessageKind.unknown => l10n.conversationPreviewUnknown,
      ChatMessageKind.text => conversation.lastMessage,
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
