import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../domain/models/chat_message.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/local_image.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isPlaying,
    required this.onPlay,
    required this.onOpenImage,
    required this.onDownloadImage,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool isPlaying;
  final VoidCallback onPlay;
  final ValueChanged<ChatMessage> onOpenImage;
  final ValueChanged<ChatMessage> onDownloadImage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mine = message.isOutgoing;
    final bubbleColor = mine ? AppColors.outgoing : Colors.white;
    final contentColor = mine ? Colors.white : const Color(0xFF303440);
    final maxWidth = (MediaQuery.sizeOf(context).width * .76)
        .clamp(260.0, 520.0)
        .toDouble();
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(15),
                    topRight: const Radius.circular(15),
                    bottomLeft: Radius.circular(mine ? 15 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 15),
                  ),
                ),
                child: switch (message.content) {
                  TextMessageContent(:final text) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                  ImageMessageContent content => _imageContent(
                    contentColor,
                    content,
                  ),
                  VoiceMessageContent() => _voiceContent(contentColor),
                  FileMessageContent(:final fileName) => _simpleContent(
                    contentColor,
                    Icons.insert_drive_file_outlined,
                    fileName?.isNotEmpty == true
                        ? fileName!
                        : context.l10n.fileMessage,
                  ),
                  VideoMessageContent() => _simpleContent(
                    contentColor,
                    Icons.videocam_outlined,
                    context.l10n.videoMessage,
                  ),
                  LocationMessageContent(:final title, :final address) =>
                    _simpleContent(
                      contentColor,
                      Icons.location_on_outlined,
                      title?.isNotEmpty == true
                          ? title!
                          : address?.isNotEmpty == true
                          ? address!
                          : context.l10n.locationMessage,
                    ),
                  ContactMessageContent(:final displayName, :final userId) =>
                    _simpleContent(
                      contentColor,
                      Icons.person_outline_rounded,
                      displayName?.isNotEmpty == true ? displayName! : userId,
                    ),
                  CustomMessageContent(:final event) => _simpleContent(
                    contentColor,
                    Icons.bolt_outlined,
                    event.isEmpty ? context.l10n.customMessage : event,
                  ),
                  SystemMessageContent(:final text) => _simpleContent(
                    contentColor,
                    Icons.info_outline_rounded,
                    text.isEmpty ? context.l10n.systemMessage : text,
                  ),
                  UnknownMessageContent() => _simpleContent(
                    contentColor,
                    Icons.help_outline_rounded,
                    context.l10n.unsupportedMessage,
                  ),
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.sentAt),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 5),
                    _DeliveryIndicator(state: message.deliveryState),
                  ],
                ],
              ),
              if (message.deliveryState == ChatMessageDeliveryState.failed)
                TextButton.icon(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.only(top: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(context.l10n.sendFailedRetry),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageContent(Color contentColor, ImageMessageContent content) {
    final path = content.localPath;
    if (path != null && path.isNotEmpty) {
      return _imageThumbnail(path, contentColor);
    }
    // Show the auto-downloaded thumbnail while the original is still remote,
    // so opening the conversation never requires a manual download tap.
    final thumbnailPath = content.thumbnailLocalPath;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      return _imageThumbnail(thumbnailPath, contentColor);
    }
    final remotePath = content.remotePath;
    if (remotePath != null && remotePath.startsWith(RegExp(r'https?://'))) {
      return _networkImage(remotePath, contentColor);
    }
    return _downloadPlaceholder(contentColor);
  }

  Widget _networkImage(String url, Color contentColor) => GestureDetector(
    onTap: () => onOpenImage(message),
    child: Image.network(
      url,
      width: 190,
      height: 132,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _downloadPlaceholder(contentColor),
    ),
  );

  Widget _simpleContent(Color contentColor, IconData icon, String label) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: contentColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: contentColor, fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _imageThumbnail(String path, Color contentColor) => GestureDetector(
    onTap: () => onOpenImage(message),
    child: LocalImage(
      path: path,
      width: 190,
      height: 172,
      // A stale local image (file deleted by the OS) falls back to the cached
      // thumbnail before showing the manual download affordance.
      errorBuilder: (_, _, _) => _thumbnailFallback(contentColor, path),
    ),
  );

  Widget _thumbnailFallback(Color contentColor, String failedPath) {
    final thumbnailPath = message.thumbnailLocalPath;
    if (thumbnailPath != null &&
        thumbnailPath.isNotEmpty &&
        thumbnailPath != failedPath) {
      return LocalImage(
        path: thumbnailPath,
        width: 190,
        height: 172,
        errorBuilder: (_, _, _) => _downloadPlaceholder(contentColor),
      );
    }
    return _downloadPlaceholder(contentColor);
  }

  Widget _downloadPlaceholder(Color contentColor) => InkWell(
    onTap: () => onDownloadImage(message),
    child: SizedBox(
      width: 190,
      height: 132,
      child: Center(
        child: Icon(Icons.download_rounded, color: contentColor, size: 28),
      ),
    ),
  );

  Widget _voiceContent(Color contentColor) => InkWell(
    onTap: onPlay,
    child: SizedBox(
      width: 176,
      height: 42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: contentColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 19,
                color: contentColor,
              ),
            ),
            Text(
              '${message.durationSeconds}s',
              style: TextStyle(color: contentColor, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

class _DeliveryIndicator extends StatelessWidget {
  const _DeliveryIndicator({required this.state});

  final ChatMessageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    if (state == ChatMessageDeliveryState.failed) {
      return const Icon(Icons.error_outline, size: 13, color: AppColors.danger);
    }
    if (state == ChatMessageDeliveryState.sending ||
        state == ChatMessageDeliveryState.created) {
      return const SizedBox(
        width: 11,
        height: 11,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.send,
        ),
      );
    }
    return SvgPicture.asset(
      'assets/icons/read.svg',
      width: 13,
      height: 13,
      colorFilter: const ColorFilter.mode(AppColors.mutedText, BlendMode.srcIn),
    );
  }
}
