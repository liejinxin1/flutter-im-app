import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../../domain/repositories/outbox_repository.dart';
import '../../../../domain/services/media_gateway.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/system_ui/app_system_ui.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/composer_view_model.dart';
import '../view_models/conversation_view_model.dart';
import '../widgets/attachment_panel.dart';
import '../widgets/conversation_header.dart';
import '../widgets/image_preview_dialog.dart';
import '../widgets/message_composer.dart';
import '../widgets/message_timeline.dart';

/// Conversation page.
///
/// Owns two focused ViewModels (timeline + composer) and UI-only concerns
/// (scroll restoration, dialogs, snackbars). No SDK, plugin, or file logic.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.repository,
    required this.media,
    required this.outbox,
    required this.currentUserId,
    required this.peerId,
    this.kind = ChatConversationKind.direct,
    this.peerName,
    this.peerAvatarUrl,
  });

  final ChatRepository repository;
  final MediaGateway media;
  final OutboxRepository outbox;
  final String currentUserId;
  final String peerId;
  final ChatConversationKind kind;
  final String? peerName;
  final String? peerAvatarUrl;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final ConversationViewModel _conversation;
  late final ComposerViewModel _composer;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _requestingOlder = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _conversation = ConversationViewModel(
      widget.repository,
      widget.outbox,
      conversationId: widget.peerId,
      currentUserId: widget.currentUserId,
      kind: widget.kind,
      media: widget.media,
    )..addListener(_onConversationChanged);
    _composer = ComposerViewModel(
      widget.media,
      _conversation.downloadAttachment,
    )..addListener(_onComposerChanged);
    _scrollController.addListener(_onScroll);
    unawaited(_conversation.loadInitial());
  }

  @override
  void dispose() {
    _conversation
      ..removeListener(_onConversationChanged)
      ..dispose();
    _composer
      ..removeListener(_onComposerChanged)
      ..dispose();
    _messageController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onConversationChanged() {
    final messageCount = _conversation.messages.length;
    final messageAdded = messageCount > _lastMessageCount;
    _lastMessageCount = messageCount;
    if (!messageAdded) return;

    final wasAtBottom =
        !_scrollController.hasClients ||
        _scrollController.position.extentAfter < 100;
    if (!wasAtBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _onComposerChanged() {
    final notice = _composer.notice;
    if (notice == null || !mounted) return;
    _composer.consumeNotice();
    _showMessage(localizedError(context.l10n, notice));
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _requestingOlder) return;
    if (_scrollController.position.pixels <= 64 && _conversation.hasMore) {
      unawaited(_loadOlderKeepingPosition());
    }
  }

  Future<void> _loadOlderKeepingPosition() async {
    if (!_scrollController.hasClients || _requestingOlder) return;
    _requestingOlder = true;
    final oldOffset = _scrollController.offset;
    final oldExtent = _scrollController.position.maxScrollExtent;
    await _conversation.loadOlder();
    if (!mounted || !_scrollController.hasClients) {
      _requestingOlder = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        _requestingOlder = false;
        return;
      }
      final addedExtent =
          _scrollController.position.maxScrollExtent - oldExtent;
      _scrollController.jumpTo(
        (oldOffset + addedExtent)
            .clamp(0, _scrollController.position.maxScrollExtent)
            .toDouble(),
      );
      _requestingOlder = false;
    });
  }

  Future<void> _send() async {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;
    _messageController.clear();
    await _conversation.send(text);
  }

  Future<void> _pickImage(MediaImageSource source) async {
    final path = await _composer.pickImage(source);
    if (path == null || !mounted) return;
    await _conversation.sendImage(path);
  }

  Future<void> _toggleRecording() async {
    final recording = await _composer.toggleRecording();
    if (recording == null || !mounted) return;
    await _conversation.sendVoice(recording.path, recording.duration.inSeconds);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Opens the full-size preview, downloading the original attachment first
  /// when only the thumbnail is cached.
  Future<void> _openImage(ChatMessage message) async {
    final path = await _conversation.resolveImagePath(message);
    if (!mounted || path == null || path.isEmpty) return;
    await showImagePreview(context, path);
  }

  void _showRtcMessage(String type) {
    final l10n = context.l10n;
    _showMessage(
      type == 'video' ? l10n.rtcVideoComingSoon : l10n.rtcVoiceComingSoon,
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: AppSystemUi.darkStatus,
    child: Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: AppContentFrame(
          maxWidth: 920,
          child: Column(
            children: [
              ConversationHeader(
                peerId: widget.peerId,
                kind: widget.kind,
                displayName: widget.peerName,
                avatarUrl: widget.peerAvatarUrl,
                onBack: () => Navigator.of(context).pop(),
                onShowDetails: () =>
                    _showMessage(context.l10n.conversationDetailsUnavailable),
                onShowPeerId: () =>
                    _showMessage(context.l10n.userIdValue(widget.peerId)),
                onVideoCall: widget.kind == ChatConversationKind.direct
                    ? () => _showRtcMessage('video')
                    : null,
                onVoiceCall: widget.kind == ChatConversationKind.direct
                    ? () => _showRtcMessage('voice')
                    : null,
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _conversation,
                  builder: (context, _) => MessageTimeline(
                    messages: _conversation.messages,
                    isLoading: _conversation.isLoading,
                    isLoadingOlder: _conversation.isLoadingOlder,
                    error: _conversation.error,
                    playingMessageId: _composer.playingMessageId,
                    scrollController: _scrollController,
                    onPlayVoice: (message) =>
                        unawaited(_composer.togglePlayback(message)),
                    onOpenImage: (message) => unawaited(_openImage(message)),
                    onDownloadImage: (message) =>
                        unawaited(_conversation.downloadAttachment(message)),
                    onRetry: (messageId) =>
                        unawaited(_conversation.retry(messageId)),
                    onReload: () => unawaited(_conversation.loadInitial()),
                    onDismissError: _conversation.clearError,
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: _composer,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_composer.attachmentsExpanded)
                      AttachmentPanel(
                        isRecording: _composer.isRecording,
                        elapsed: _composer.elapsed,
                        isBusy: _composer.isBusy,
                        onCamera: () =>
                            unawaited(_pickImage(MediaImageSource.camera)),
                        onGallery: () =>
                            unawaited(_pickImage(MediaImageSource.gallery)),
                        onRecord: () => unawaited(_toggleRecording()),
                        onContact: () =>
                            _showMessage(context.l10n.contactShareUnavailable),
                        onLocation: () =>
                            _showMessage(context.l10n.locationUnavailable),
                        onDocument: () =>
                            _showMessage(context.l10n.documentUnavailable),
                      ),
                    MessageComposer(
                      controller: _messageController,
                      attachmentsExpanded: _composer.attachmentsExpanded,
                      onToggleAttachments: _composer.toggleAttachments,
                      onSend: () => unawaited(_send()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
