import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/models/user_profile.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../../domain/repositories/outbox_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../domain/services/app_settings.dart';
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
import '../widgets/voice_recording_bar.dart';

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
    this.settings,
    this.profiles,
    this.kind = ChatConversationKind.direct,
    this.memberCount,
    this.peerName,
    this.peerAvatarUrl,
  });

  final ChatRepository repository;
  final MediaGateway media;
  final OutboxRepository outbox;
  final String currentUserId;
  final String peerId;
  final AppSettings? settings;
  final ProfileRepository? profiles;
  final ChatConversationKind kind;
  final int? memberCount;
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
  final _messageFieldKey = GlobalKey();
  final _recordingBarKey = GlobalKey();
  bool _requestingOlder = false;
  int _lastMessageCount = 0;
  String? _lastMessageId;
  bool _atBottom = true;
  int _unseenMessages = 0;
  bool _recordingPromptOpen = false;
  bool _autoSendingRecording = false;
  bool _selectionMode = false;
  final Set<String> _selectedMessageIds = {};
  ChatMessage? _quotedMessage;
  Map<String, UserProfile> _senderProfiles = const {};
  UserProfile? _peerProfile;
  final Set<String> _loadingSenderIds = {};
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  GlobalKey _messageKey(String messageId) =>
      _messageKeys.putIfAbsent(messageId, GlobalKey.new);

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
      settings: widget.settings,
    )..addListener(_onConversationChanged);
    _composer = ComposerViewModel(
      widget.media,
      _conversation.downloadAttachment,
    )..addListener(_onComposerChanged);
    _scrollController.addListener(_onScroll);
    unawaited(_conversation.loadInitial());
    unawaited(_loadSenderProfiles());
    unawaited(_loadPeerProfile());
  }

  Future<void> _loadPeerProfile() async {
    final repository = widget.profiles;
    if (repository == null || widget.kind != ChatConversationKind.direct) {
      return;
    }
    try {
      final profile = await repository.load(widget.peerId);
      if (!mounted) return;
      setState(() => _peerProfile = profile);
    } catch (_) {
      // Keep the title fallback if the directory is unavailable.
    }
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
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _onConversationChanged() {
    unawaited(_loadSenderProfiles());
    final messages = _conversation.messages;
    final messageCount = messages.length;
    final added = messageCount - _lastMessageCount;
    final latestId = messages.isEmpty ? null : messages.last.id;
    final latestChanged = latestId != null && latestId != _lastMessageId;
    _lastMessageCount = messageCount;
    _lastMessageId = latestId;
    if (added <= 0) return;

    if (_atBottom) {
      if (_unseenMessages != 0) {
        setState(() => _unseenMessages = 0);
      }
      _scrollToBottomSoon();
      return;
    }
    if (!latestChanged) return;
    setState(() => _unseenMessages += added);
  }

  void _onComposerChanged() {
    if (_composer.isRecording &&
        _composer.elapsed >= ComposerViewModel.maxRecordingDuration &&
        !_autoSendingRecording) {
      _autoSendingRecording = true;
      unawaited(_finishAtLimit());
    } else if (!_composer.isRecording) {
      _autoSendingRecording = false;
    }

    final notice = _composer.notice;
    if (notice == null || !mounted) return;
    _composer.consumeNotice();
    _showMessage(localizedError(context.l10n, notice));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.extentAfter < 80;
    if (atBottom != _atBottom) {
      _atBottom = atBottom;
      if (atBottom && _unseenMessages != 0) {
        setState(() => _unseenMessages = 0);
      }
    }
    if (_requestingOlder) return;
    if (_scrollController.position.pixels <= 64 && _conversation.hasMore) {
      unawaited(_loadOlderKeepingPosition());
    }
  }

  void _scrollToBottomSoon({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  void _scrollToBottom({bool animate = true}) {
    if (_unseenMessages != 0) setState(() => _unseenMessages = 0);
    _scrollToBottomSoon(animate: animate);
  }

  bool _isInside(GlobalKey key, Offset globalPosition) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.contains(globalPosition);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_composer.isRecording) {
      if (_isInside(_recordingBarKey, event.position)) return;
      unawaited(_promptRecordingExit());
      return;
    }
    if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;
    if (_isInside(_messageFieldKey, event.position)) return;
    _dismissKeyboard();
  }

  Future<void> _promptRecordingExit() async {
    if (!_composer.isRecording || _recordingPromptOpen) return;
    _recordingPromptOpen = true;
    final recording = await _composer.finishRecording();
    if (!mounted) {
      _recordingPromptOpen = false;
      if (recording != null) {
        await _composer.discardFinishedRecording(recording);
      }
      return;
    }
    if (recording == null) {
      _recordingPromptOpen = false;
      return;
    }

    final send = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.recordingExitTitle),
        content: Text(context.l10n.recordingExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.withdrawRecording),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.send),
          ),
        ],
      ),
    );
    _recordingPromptOpen = false;
    if (!mounted) return;
    if (send == true) {
      await _conversation.sendVoice(
        recording.path,
        recording.duration.inSeconds,
      );
      if (mounted) _scrollToBottom();
    } else {
      await _composer.discardFinishedRecording(recording);
    }
  }

  Future<void> _finishAtLimit() async {
    if (mounted) _showMessage(context.l10n.voiceLimitReached);
    final recording = await _composer.finishRecording();
    if (recording == null || !mounted) return;
    await _conversation.sendVoice(recording.path, recording.duration.inSeconds);
    if (mounted) _scrollToBottom();
  }

  Future<void> _loadSenderProfiles() async {
    final repository = widget.profiles;
    if (repository == null || widget.kind != ChatConversationKind.group) {
      return;
    }
    final ids = _conversation.messages
        .where((message) => !message.isOutgoing)
        .map((message) => message.senderId)
        .where(
          (id) =>
              id.isNotEmpty &&
              !_senderProfiles.containsKey(id) &&
              !_loadingSenderIds.contains(id),
        )
        .toSet();
    if (ids.isEmpty) return;
    _loadingSenderIds.addAll(ids);
    try {
      final loaded = await repository.loadAll(ids);
      if (!mounted) return;
      setState(() {
        _senderProfiles = {..._senderProfiles, ...loaded};
      });
    } catch (_) {
      // Sender names are decoration; keep the sender ID fallback.
    } finally {
      _loadingSenderIds.removeAll(ids);
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
    if (mounted) _scrollToBottom();
  }

  Future<void> _pickImage(MediaImageSource source) async {
    _dismissKeyboard();
    final path = await _composer.pickImage(source);
    if (path == null || !mounted) return;
    await _conversation.sendImage(path);
    if (mounted) _scrollToBottom();
  }

  Future<void> _pickFile() async {
    _dismissKeyboard();
    final file = await _composer.pickFile();
    if (file == null || !mounted) return;
    await _conversation.sendFile(
      file.path,
      fileName: file.name,
      fileSizeBytes: file.sizeBytes,
      mimeType: file.mimeType,
    );
    if (mounted) _scrollToBottom();
  }

  Future<void> _startVoice() async {
    _dismissKeyboard();
    await _composer.startRecordingMode();
  }

  Future<void> _sendRecording() async {
    final recording = await _composer.finishRecording();
    if (recording == null || !mounted) return;
    await _conversation.sendVoice(recording.path, recording.duration.inSeconds);
    if (mounted) _scrollToBottom();
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

  Future<void> _openFile(ChatMessage message) async {
    final path = await _conversation.downloadAttachment(message);
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      _showMessage(context.l10n.fileDownloadFailed);
      return;
    }
    final content = message.content;
    final name = content is FileMessageContent && content.fileName != null
        ? content.fileName!
        : context.l10n.fileMessage;
    try {
      await widget.media.openFile(path);
      if (!mounted) return;
      _showMessage(context.l10n.fileOpened(name));
    } catch (_) {
      if (!mounted) return;
      _showMessage(context.l10n.fileOpenFailed);
    }
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
    String? imageUrl;
    String? thumbnailPath;
    String? fileName;
    int? durationSeconds;
    double? width;
    double? height;
    switch (content) {
      case ImageMessageContent():
        imageUrl = content.remotePath;
        thumbnailPath = content.thumbnailLocalPath ?? content.localPath;
        width = content.width;
        height = content.height;
      case VoiceMessageContent():
        durationSeconds = content.durationSeconds;
      case FileMessageContent():
        fileName = content.fileName;
      case VideoMessageContent():
        imageUrl = content.remotePath;
        thumbnailPath = content.thumbnailLocalPath;
        durationSeconds = content.durationSeconds;
        width = content.width;
        height = content.height;
      default:
        break;
    }
    return ChatMessageQuote(
      messageId: message.id,
      senderId: message.senderId,
      kind: content.kind,
      text: content is TextMessageContent ? content.text : '',
      imageUrl: imageUrl,
      thumbnailPath: thumbnailPath,
      fileName: fileName,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
    );
  }

  bool _canRecall(ChatMessage message) =>
      message.isOutgoing &&
      message.content is! SystemMessageContent &&
      (message.deliveryState == ChatMessageDeliveryState.sent ||
          message.deliveryState == ChatMessageDeliveryState.delivered ||
          message.deliveryState == ChatMessageDeliveryState.read) &&
      DateTime.now().difference(message.sentAt) < const Duration(minutes: 2);

  Future<void> _onMessageLongPress(ChatMessage message, Offset position) async {
    if (message.content case SystemMessageContent(systemType: 'recall')) {
      return;
    }
    if (_selectionMode) {
      _toggleSelection(message);
      return;
    }
    final action = await _showFloatingActions(
      message,
      position,
      canRecall: _canRecall(message),
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

  Future<void> _scrollToMessage(String messageId) async {
    var found = _conversation.messages.any(
      (message) => message.id == messageId,
    );
    var attempts = 0;
    while (!found && _conversation.hasMore && attempts < 20) {
      final added = await _conversation.loadOlder();
      if (!mounted || added == 0) break;
      attempts++;
      found = _conversation.messages.any((message) => message.id == messageId);
    }
    if (!mounted) return;
    if (!found) {
      _showMessage(context.l10n.quotedMessageNotFound);
      return;
    }

    _highlightTimer?.cancel();
    FocusScope.of(context).unfocus();
    setState(() => _highlightedMessageId = messageId);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final targetContext = _messageKeys[messageId]?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.4,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
    if (!mounted) return;
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _highlightedMessageId = null);
    });
  }

  Future<_MessageAction?> _showFloatingActions(
    ChatMessage message,
    Offset position, {
    required bool canRecall,
  }) {
    final size = MediaQuery.sizeOf(context);
    final menuWidth = math.min(size.width - 16, 344.0);
    const menuHeight = 72.0;
    final left = (position.dx - menuWidth / 2)
        .clamp(8.0, math.max(8.0, size.width - menuWidth - 8))
        .toDouble();
    var top = position.dy - menuHeight - 10;
    if (top < 8) top = position.dy + 14;
    top = top
        .clamp(8.0, math.max(8.0, size.height - menuHeight - 8))
        .toDouble();
    return showGeneralDialog<_MessageAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (context, animation, secondaryAnimation) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: menuWidth,
            child: FadeTransition(
              opacity: animation,
              child: Material(
                color: Colors.transparent,
                child: _FloatingMessageActions(
                  canCopy: message.content is TextMessageContent,
                  canRecall: canRecall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
    child: Listener(
      onPointerDown: _onPointerDown,
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
                  memberCount: widget.memberCount,
                  displayName: widget.peerName,
                  avatarUrl: widget.peerAvatarUrl,
                  peerPhone: _peerProfile?.phone,
                  onBack: () {
                    if (_selectionMode) {
                      _exitSelection();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  onShowDetails: () {
                    if (widget.kind == ChatConversationKind.group) {
                      final query = <String, String>{
                        if (widget.peerName != null) 'name': widget.peerName!,
                        if (widget.memberCount != null)
                          'members': '${widget.memberCount}',
                        'me': widget.currentUserId,
                      };
                      context.push<void>(
                        '/groups/${Uri.encodeComponent(widget.peerId)}'
                        '${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}',
                      );
                    } else if (widget.kind == ChatConversationKind.direct) {
                      context.push<void>(
                        '/friends/${Uri.encodeComponent(widget.peerId)}',
                      );
                    } else {
                      _showMessage(context.l10n.conversationDetailsUnavailable);
                    }
                  },
                  onVideoCall: widget.kind != ChatConversationKind.chatRoom
                      ? () => _showRtcMessage('video')
                      : null,
                  onVoiceCall: widget.kind != ChatConversationKind.chatRoom
                      ? () => _showRtcMessage('voice')
                      : null,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ListenableBuilder(
                          listenable: _conversation,
                          builder: (context, _) => MessageTimeline(
                            messages: _conversation.messages,
                            isLoading: _conversation.isLoading,
                            isLoadingOlder: _conversation.isLoadingOlder,
                            hasMore: _conversation.hasMore,
                            error: _conversation.error,
                            playingMessageId: _composer.playingMessageId,
                            scrollController: _scrollController,
                            onPlayVoice: (message) =>
                                unawaited(_composer.togglePlayback(message)),
                            onOpenImage: (message) =>
                                unawaited(_openImage(message)),
                            onDownloadImage: (message) => unawaited(
                              _conversation.downloadAttachment(message),
                            ),
                            onRetry: (messageId) =>
                                unawaited(_conversation.retry(messageId)),
                            onReload: () =>
                                unawaited(_conversation.loadInitial()),
                            onDismissError: _conversation.clearError,
                            onLongPress: (message, position) => unawaited(
                              _onMessageLongPress(message, position),
                            ),
                            selectionMode: _selectionMode,
                            selectedIds: _selectedMessageIds,
                            onToggleSelection: _toggleSelection,
                            onQuoteTap: (messageId) =>
                                unawaited(_scrollToMessage(messageId)),
                            highlightedMessageId: _highlightedMessageId,
                            keyForMessage: _messageKey,
                            showSenderNames:
                                widget.kind == ChatConversationKind.group,
                            senderProfiles: _senderProfiles,
                            onOpenSender: (userId) => context.push<void>(
                              '/friends/${Uri.encodeComponent(userId)}',
                            ),
                            onOpenFile: (message) =>
                                unawaited(_openFile(message)),
                          ),
                        ),
                      ),
                      if (_unseenMessages > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child: Center(
                            child: _NewMessagesPill(
                              count: _unseenMessages,
                              onTap: () => _scrollToBottom(),
                            ),
                          ),
                        ),
                    ],
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
                      else if (_composer.isRecording)
                        VoiceRecordingBar(
                          key: _recordingBarKey,
                          elapsed: _composer.elapsed,
                          isPaused: _composer.isPaused,
                          isBusy: _composer.isBusy,
                          onPause: () => unawaited(_composer.togglePause()),
                          onCancel: () =>
                              unawaited(_composer.cancelRecording()),
                          onSend: () => unawaited(_sendRecording()),
                        )
                      else ...[
                        MessageComposer(
                          fieldKey: _messageFieldKey,
                          controller: _messageController,
                          isGroup: widget.kind == ChatConversationKind.group,
                          attachmentsExpanded: _composer.attachmentsExpanded,
                          onToggleAttachments: () {
                            _dismissKeyboard();
                            _composer.toggleAttachments();
                          },
                          onCamera: () =>
                              unawaited(_pickImage(MediaImageSource.camera)),
                          onVoice: () => unawaited(_startVoice()),
                          onSend: () {
                            _dismissKeyboard();
                            unawaited(_send());
                          },
                          quote: _quoteFor(_quotedMessage),
                          onCancelQuote: () =>
                              setState(() => _quotedMessage = null),
                          onQuoteTap: () {
                            final quoted = _quotedMessage;
                            if (quoted != null) {
                              unawaited(_scrollToMessage(quoted.id));
                            }
                          },
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: _composer.attachmentsExpanded
                              ? AttachmentPanel(
                                  onCamera: () => unawaited(
                                    _pickImage(MediaImageSource.camera),
                                  ),
                                  onGallery: () => unawaited(
                                    _pickImage(MediaImageSource.gallery),
                                  ),
                                  onRecord: () => unawaited(_startVoice()),
                                  onContact: () => _showMessage(
                                    context.l10n.contactShareUnavailable,
                                  ),
                                  onLocation: () => _showMessage(
                                    context.l10n.locationUnavailable,
                                  ),
                                  onDocument: () => unawaited(_pickFile()),
                                )
                              : const SizedBox.shrink(),
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
    ),
  );
}

enum _MessageAction { copy, quote, forward, recall, delete, select }

class _NewMessagesPill extends StatelessWidget {
  const _NewMessagesPill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.brandBlueLight,
    borderRadius: BorderRadius.circular(18),
    elevation: 3,
    shadowColor: const Color(0x33000000),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.newMessages(count),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FloatingMessageActions extends StatelessWidget {
  const _FloatingMessageActions({
    required this.canCopy,
    required this.canRecall,
  });

  final bool canCopy;
  final bool canRecall;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canCopy)
                _FloatingAction(
                  icon: Icons.copy_rounded,
                  label: l10n.copy,
                  action: _MessageAction.copy,
                ),
              _FloatingAction(
                icon: Icons.format_quote_rounded,
                label: l10n.quote,
                action: _MessageAction.quote,
              ),
              _FloatingAction(
                icon: Icons.forward_rounded,
                label: l10n.forward,
                action: _MessageAction.forward,
              ),
              if (canRecall)
                _FloatingAction(
                  icon: Icons.undo_rounded,
                  label: l10n.recall,
                  action: _MessageAction.recall,
                ),
              _FloatingAction(
                icon: Icons.checklist_rounded,
                label: l10n.select,
                action: _MessageAction.select,
              ),
              _FloatingAction(
                icon: Icons.delete_outline_rounded,
                label: l10n.delete,
                action: _MessageAction.delete,
                color: AppColors.danger,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingAction extends StatelessWidget {
  const _FloatingAction({
    required this.icon,
    required this.label,
    required this.action,
    this.color,
  });

  final IconData icon;
  final String label;
  final _MessageAction action;
  final Color? color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).pop(action),
    child: SizedBox(
      width: 54,
      height: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color ?? const Color(0xFF303440)),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? const Color(0xFF303440),
            ),
          ),
        ],
      ),
    ),
  );
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
