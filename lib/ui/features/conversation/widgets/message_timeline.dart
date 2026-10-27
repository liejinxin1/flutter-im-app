import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/chat_message.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import 'message_bubble.dart';

class MessageTimeline extends StatelessWidget {
  const MessageTimeline({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.isLoadingOlder,
    required this.error,
    required this.playingMessageId,
    required this.scrollController,
    required this.onPlayVoice,
    required this.onOpenImage,
    required this.onDownloadImage,
    required this.onRetry,
    required this.onReload,
    required this.onDismissError,
  });

  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingOlder;
  final AppError? error;
  final ValueListenable<String?> playingMessageId;
  final ScrollController scrollController;
  final ValueChanged<ChatMessage> onPlayVoice;
  final ValueChanged<ChatMessage> onOpenImage;
  final ValueChanged<ChatMessage> onDownloadImage;
  final ValueChanged<String> onRetry;
  final VoidCallback onReload;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.messageBackground),
        if (isLoading && messages.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (error != null && messages.isEmpty)
          _TimelineNotice(
            icon: Icons.cloud_off_outlined,
            text: localizedError(l10n, error!),
            action: TextButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          )
        else if (messages.isEmpty)
          _TimelineNotice(
            icon: Icons.waving_hand_outlined,
            text: l10n.startConversation,
          )
        else
          _messageList(),
        if (error != null && messages.isNotEmpty)
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: _ErrorBanner(
              message: localizedError(l10n, error!),
              onDismiss: onDismissError,
            ),
          ),
      ],
    );
  }

  Widget _messageList() => ListView.builder(
    controller: scrollController,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
    itemCount: messages.length + (isLoadingOlder ? 1 : 0),
    itemBuilder: (context, index) {
      if (isLoadingOlder && index == 0) {
        return const Padding(
          padding: EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      final messageIndex = index - (isLoadingOlder ? 1 : 0);
      final message = messages[messageIndex];
      return ValueListenableBuilder<String?>(
        key: ValueKey(message.id),
        valueListenable: playingMessageId,
        builder: (context, playingId, _) => MessageBubble(
          message: message,
          isPlaying: playingId == message.id,
          onPlay: () => onPlayVoice(message),
          onOpenImage: onOpenImage,
          onDownloadImage: onDownloadImage,
          onRetry: () => onRetry(message.id),
        ),
      );
    },
  );
}

class _TimelineNotice extends StatelessWidget {
  const _TimelineNotice({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.outgoing),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(color: AppColors.outgoing),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 6), action!],
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFE5E3),
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF8B2823)),
            ),
          ),
          IconButton(
            tooltip: context.l10n.close,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 17),
            color: const Color(0xFF8B2823),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ),
  );
}
