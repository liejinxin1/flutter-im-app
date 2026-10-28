import 'package:flutter/material.dart';

import '../../../../domain/models/chat_message.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/local_image.dart';

/// Renders the quoted-message card used by both the composer and bubbles.
class QuotedMessagePreview extends StatelessWidget {
  const QuotedMessagePreview({
    super.key,
    required this.quote,
    this.onDark = false,
  });

  final ChatMessageQuote quote;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = switch (quote.kind) {
      ChatMessageKind.text => quote.text,
      ChatMessageKind.image => l10n.imageMessage,
      ChatMessageKind.voice =>
        quote.durationSeconds != null && quote.durationSeconds! > 0
            ? '${quote.durationSeconds}s'
            : l10n.voiceMessage,
      ChatMessageKind.file =>
        quote.fileName?.isNotEmpty == true ? quote.fileName! : l10n.fileMessage,
      ChatMessageKind.video => l10n.videoMessage,
      ChatMessageKind.location => l10n.locationMessage,
      ChatMessageKind.contact => l10n.contactMessage,
      ChatMessageKind.custom => l10n.customMessage,
      ChatMessageKind.system => l10n.systemMessage,
      _ => l10n.unsupportedMessage,
    };
    final textColor = onDark
        ? const Color(0xE6FFFFFF)
        : const Color(0xFF666B78);
    final showThumbnail = quote.kind != ChatMessageKind.text;
    return Row(
      children: [
        if (showThumbnail) ...[
          _Thumbnail(quote: quote, onDark: onDark),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quote.senderId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                preview.isNotEmpty ? preview : l10n.quotedMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.quote, required this.onDark});

  final ChatMessageQuote quote;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isMedia =
        quote.kind == ChatMessageKind.image ||
        quote.kind == ChatMessageKind.video;
    final icon = switch (quote.kind) {
      ChatMessageKind.voice => Icons.mic_none_rounded,
      ChatMessageKind.file => Icons.insert_drive_file_outlined,
      _ => Icons.image_outlined,
    };
    final background = onDark
        ? const Color(0x33FFFFFF)
        : const Color(0xFFE9EDF2);
    final foreground = onDark ? Colors.white : AppColors.mutedText;

    Widget fallback() => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 20, color: foreground),
    );

    if (!isMedia) return fallback();

    final imageUrl = quote.imageUrl;
    final path = quote.thumbnailPath;
    final image = imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : path != null && path.isNotEmpty
        ? LocalImage(
            path: path,
            width: 38,
            height: 38,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback(),
          )
        : fallback();

    return ClipRRect(borderRadius: BorderRadius.circular(6), child: image);
  }
}
