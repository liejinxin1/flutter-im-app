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
import '../widgets/message_selection_bar.dart';
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
  bool _selectionMode = false;
  final Set<String> _selectedMessageIds = {};
  ChatMessage? _quotedMessage;

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
    final quoted = _quotedMessage;
    _messageController.clear();
    setState(() => _quotedMessage = null);
    await _conversation.send(text, quote: _quoteFor(quoted));
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

  ChatMessageQuote? _quoteFor(ChatMessage? message) {
    if (message == null) return null;
    final content = message.content;
    return ChatMessageQuote(
      messageId: message.id,
      senderId: message.senderId,
      kind: content.kind,
      text: content is TextMessageContent ? content.text : '',
    );
  }

  bool _canRecall(ChatMessage message) =>
      message.isOutgoing &&
      message.content is! SystemMessageContent &&
      (message.deliveryState == ChatMessageDeliveryState.sent ||
          message.deliveryState == ChatMessageDeliveryState.delivered ||
          message.deliveryState == ChatMessageDeliveryState.read) &&
      DateTime.now().difference(message.sentAt) < const Duration(minutes: 2);

  Future<void> _onMessageLongPress(ChatMessage message) async {
    if (message.content case SystemMessageContent(systemType: 'recall')) {
      return;
    }
    if (_selectionMode) {
      _toggleSelection(message);
      return;
    }
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => _MessageActionsSheet(
        message: message,
        canRecall: _canRecall(message),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MessageAction.copy:
        await _copyMessages([message]);
        break;
      case _MessageAction.quote:
        setState(() => _quotedMessage = message);
        break;
      case _MessageAction.forward:
        await _forwardMessages({message.id});
        break;
      case _MessageAction.recall:
        await _recall(message);
        break;
      case _MessageAction.delete:
        await _deleteMessages({message.id});
        break;
      case _MessageAction.select:
        if (!mounted) return;
        FocusScope.of(context).unfocus();
        setState(() {
          _selectionMode = true;
          _selectedMessageIds.add(message.id);
        });
        break;
    }
  }

  void _toggleSelection(ChatMessage message) {
    setState(() {
      if (!_selectedMessageIds.add(message.id)) {
        _selectedMessageIds.remove(message.id);
      }
      if (_selectedMessageIds.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelection() {
    if (!_selectionMode && _selectedMessageIds.isEmpty) return;
    setState(() {
      _selectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  Future<void> _copyMessages(Iterable<ChatMessage> messages) async {
    final text = messages
        .where((message) => message.content is TextMessageContent)
        .map((message) => (message.content as TextMessageContent).text)
        .where((value) => value.isNotEmpty)
        .join('\n');
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showMessage(context.l10n.copied);
  }

  Future<void> _copySelection() async {
    await _copyMessages(
      _conversation.messages.where(
        (message) => _selectedMessageIds.contains(message.id),
      ),
    );
    _exitSelection();
  }

  Future<void> _deleteMessages(Set<String> ids) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.deleteMessagesTitle,
      body: l10n.deleteMessagesBody,
      action: l10n.delete,
    );
    if (!confirmed || !mounted) return;
    final deleted = await _conversation.deleteMessages(ids);
    if (!mounted) return;
    _exitSelection();
    if (deleted) _showMessage(l10n.deleted);
  }

  Future<void> _recall(ChatMessage message) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.recallMessageTitle,
      body: l10n.recallMessageBody,
      action: l10n.recall,
    );
    if (!confirmed || !mounted) return;
    final recalled = await _conversation.recallMessage(message.id);
    if (mounted && recalled) _showMessage(l10n.recalledMessage);
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _forwardMessages(Set<String> ids) async {
    if (ids.isEmpty) return;
    final target = await showModalBottomSheet<ChatConversation>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ForwardTargetSheet(
        conversations: widget.repository.loadConversations(),
      ),
    );
    if (!mounted || target == null) return;
    final forwarded = await _conversation.forwardMessages(
      ids,
      target.id,
      kind: target.kind,
    );
    if (!mounted) return;
    _exitSelection();
    if (forwarded > 0) _showMessage(context.l10n.forwarded);
  }

  Future<void> _deleteSelection() => _deleteMessages({..._selectedMessageIds});

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
                onBack: () {
                  if (_selectionMode) {
                    _exitSelection();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
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
                    onLongPress: (message) =>
                        unawaited(_onMessageLongPress(message)),
                    selectionMode: _selectionMode,
                    selectedIds: _selectedMessageIds,
                    onToggleSelection: _toggleSelection,
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: _composer,
                builder: (context, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectionMode)
                      MessageSelectionBar(
                        count: _selectedMessageIds.length,
                        onClose: _exitSelection,
                        onCopy: () => unawaited(_copySelection()),
                        onForward: () => unawaited(
                          _forwardMessages({..._selectedMessageIds}),
                        ),
                        onDelete: () => unawaited(_deleteSelection()),
                      )
                    else ...[
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
                          onContact: () => _showMessage(
                            context.l10n.contactShareUnavailable,
                          ),
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
                        quote: _quoteFor(_quotedMessage),
                        onCancelQuote: () =>
                            setState(() => _quotedMessage = null),
                      ),
                    ],
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

enum _MessageAction { copy, quote, forward, recall, delete, select }

class _MessageActionsSheet extends StatelessWidget {
  const _MessageActionsSheet({required this.message, required this.canRecall});

  final ChatMessage message;
  final bool canRecall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canCopy = message.content is TextMessageContent;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canCopy)
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.copy),
              onTap: () => Navigator.of(context).pop(_MessageAction.copy),
            ),
          ListTile(
            leading: const Icon(Icons.format_quote_outlined),
            title: Text(l10n.quote),
            onTap: () => Navigator.of(context).pop(_MessageAction.quote),
          ),
          ListTile(
            leading: const Icon(Icons.forward_outlined),
            title: Text(l10n.forward),
            onTap: () => Navigator.of(context).pop(_MessageAction.forward),
          ),
          if (canRecall)
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: Text(l10n.recall),
              onTap: () => Navigator.of(context).pop(_MessageAction.recall),
            ),
          ListTile(
            leading: const Icon(Icons.checklist_rounded),
            title: Text(l10n.select),
            onTap: () => Navigator.of(context).pop(_MessageAction.select),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () => Navigator.of(context).pop(_MessageAction.delete),
          ),
        ],
      ),
    );
  }
}

class _ForwardTargetSheet extends StatelessWidget {
  const _ForwardTargetSheet({required this.conversations});

  final Future<List<ChatConversation>> conversations;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height: 360,
      child: FutureBuilder<List<ChatConversation>>(
        future: conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? const <ChatConversation>[];
          if (items.isEmpty) {
            return Center(child: Text(context.l10n.noConversations));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final conversation = items[index];
              final name = conversation.name?.isNotEmpty == true
                  ? conversation.name!
                  : conversation.id;
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                title: Text(name),
                subtitle: Text(conversation.id),
                onTap: () => Navigator.of(context).pop(conversation),
              );
            },
          );
        },
      ),
    ),
  );
}
