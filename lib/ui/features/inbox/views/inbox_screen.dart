import 'package:flutter/material.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/inbox_view_model.dart';
import '../widgets/conversation_tile.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({
    super.key,
    required this.viewModel,
    required this.kind,
    required this.onOpenConversation,
    required this.onAdd,
  });

  final InboxViewModel viewModel;
  final ChatConversationKind kind;
  final void Function(ChatConversation conversation) onOpenConversation;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final conversations = viewModel.conversationsOf(kind);
    if (viewModel.isLoading && viewModel.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null && viewModel.conversations.isEmpty) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.conversationsUnavailable,
        detail: localizedError(l10n, viewModel.error!),
        action: TextButton.icon(
          onPressed: viewModel.refresh,
          icon: const Icon(Icons.refresh),
          label: Text(l10n.retry),
        ),
      );
    }
    if (conversations.isEmpty) {
      final isDirect = kind == ChatConversationKind.direct;
      return _EmptyState(
        icon: isDirect
            ? Icons.chat_bubble_outline_rounded
            : Icons.groups_2_outlined,
        title: isDirect ? l10n.noChats : l10n.noGroups,
        detail: isDirect ? l10n.noChatsDetail : l10n.noGroupsDetail,
        action: FilledButton.icon(
          onPressed: onAdd,
          icon: Icon(
            isDirect ? Icons.person_add_alt_1_rounded : Icons.group_add_rounded,
          ),
          label: Text(isDirect ? l10n.addFriendAction : l10n.createGroupAction),
        ),
      );
    }

    return AppContentFrame(
      maxWidth: 820,
      child: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () => onOpenConversation(conversation),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.shell,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777986), height: 1.4),
          ),
          const SizedBox(height: 18),
          action,
        ],
      ),
    ),
  );
}
