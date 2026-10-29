import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../domain/models/chat_message.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import 'quoted_message_preview.dart';

/// Message input row. Stateless by design: text state lives in the owning
/// screen's [TextEditingController], and sends are forwarded upward.
class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.attachmentsExpanded,
    required this.onToggleAttachments,
    required this.onSend,
    this.quote,
    this.onCancelQuote,
    this.onQuoteTap,
    this.isGroup = false,
    this.onCamera,
    this.onVoice,
    this.fieldKey,
  });

  final TextEditingController controller;
  final bool attachmentsExpanded;
  final VoidCallback onToggleAttachments;
  final VoidCallback onSend;
  final ChatMessageQuote? quote;
  final VoidCallback? onCancelQuote;
  final VoidCallback? onQuoteTap;
  final bool isGroup;
  final VoidCallback? onCamera;
  final VoidCallback? onVoice;
  final GlobalKey? fieldKey;

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (quote != null) ...[
          _QuoteBar(quote: quote!, onCancel: onCancelQuote, onTap: onQuoteTap),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isGroup) ...[
              SizedBox(
                width: 38,
                height: 38,
                child: IconButton(
                  tooltip: context.l10n.addAttachment,
                  onPressed: onToggleAttachments,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.send,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  icon: Icon(
                    attachmentsExpanded
                        ? Icons.close_rounded
                        : Icons.add_rounded,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 9),
            ],
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                decoration: BoxDecoration(
                  color: isGroup ? const Color(0xFFF3F4F6) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isGroup
                      ? null
                      : Border.all(color: const Color(0xFFE5E8EC)),
                ),
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(
                    color: Color(0xFF252936),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.messageHint,
                    hintStyle: const TextStyle(
                      color: AppColors.hint,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    suffixIcon: isGroup
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (onCamera != null)
                                IconButton(
                                  tooltip: context.l10n.camera,
                                  onPressed: onCamera,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 21,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              IconButton(
                                tooltip: context.l10n.addAttachment,
                                onPressed: onToggleAttachments,
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  attachmentsExpanded
                                      ? Icons.close_rounded
                                      : Icons.attach_file_rounded,
                                  size: 21,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 42,
              height: 42,
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty;
                  if (!isGroup && !canSend && onVoice != null) {
                    return IconButton.filled(
                      tooltip: context.l10n.holdToTalk,
                      onPressed: onVoice,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.send,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.mic_none_rounded, size: 22),
                    );
                  }
                  return FilledButton(
                    onPressed: canSend ? onSend : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.send,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFDCE3E8),
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: SvgPicture.asset(
                      isGroup
                          ? 'assets/icons/send.svg'
                          : 'assets/icons/send.svg',
                      width: 19,
                      height: 19,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuoteBar extends StatelessWidget {
  const _QuoteBar({required this.quote, this.onCancel, this.onTap});

  final ChatMessageQuote quote;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.messageBackground,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.brandBlueLight, width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: QuotedMessagePreview(quote: quote, onTap: onTap),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: onCancel,
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }
}
