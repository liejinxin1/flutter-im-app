import 'package:flutter/material.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';

/// Title row + peer header for a conversation.
///
/// Pure presentation: call intents are forwarded to the screen, which owns
/// navigation and (later) the RTC call coordinator.
class ConversationHeader extends StatelessWidget {
  const ConversationHeader({
    super.key,
    required this.peerId,
    required this.kind,
    required this.onBack,
    required this.onShowDetails,
    required this.onShowPeerId,
    this.onVoiceCall,
    this.onVideoCall,
    this.displayName,
    this.avatarUrl,
    this.memberCount,
  });

  final String peerId;
  final ChatConversationKind kind;
  final VoidCallback onBack;
  final VoidCallback onShowDetails;
  final VoidCallback onShowPeerId;
  final VoidCallback? onVoiceCall;
  final VoidCallback? onVideoCall;
  final String? displayName;
  final String? avatarUrl;
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.back,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                color: const Color(0xFF262B36),
              ),
              Expanded(
                child: Text(
                  l10n.chatTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF242833),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.more,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF252A34),
                ),
                onSelected: (action) {
                  if (action == 'peerId') {
                    onShowPeerId();
                  } else {
                    onShowDetails();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'details',
                    child: Text(l10n.conversationDetails),
                  ),
                  PopupMenuItem(value: 'peerId', child: Text(l10n.showUserId)),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              UserAvatar(
                userId: peerId,
                radius: 24,
                foregroundImage: avatarUrl == null
                    ? null
                    : NetworkImage(avatarUrl!),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName?.trim().isNotEmpty == true
                          ? displayName!.trim()
                          : peerId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF252A34),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kind == ChatConversationKind.group
                          ? (memberCount != null
                                ? l10n.groupMembers(memberCount!)
                                : l10n.groupChat)
                          : peerId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onVideoCall != null)
                IconButton(
                  tooltip: l10n.videoCall,
                  onPressed: onVideoCall,
                  icon: const Icon(Icons.videocam_outlined, size: 23),
                  color: const Color(0xFF28303B),
                ),
              if (onVoiceCall != null)
                IconButton(
                  tooltip: l10n.voiceCall,
                  onPressed: onVoiceCall,
                  icon: const Icon(Icons.call_outlined, size: 21),
                  color: const Color(0xFF28303B),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
