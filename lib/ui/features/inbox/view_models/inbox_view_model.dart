import 'dart:async';

import '../../../../domain/models/chat_conversation.dart';
import '../../../../domain/models/chat_message.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../../../domain/repositories/session_repository.dart';
import '../../../core/localization/app_error.dart';
import '../../../core/view_model.dart';

/// Conversation list state, unread badges, connection status, and in-app
/// incoming-message notices.
class InboxViewModel extends ViewModel {
  InboxViewModel(this._chat, this._session, this._profiles) {
    _incomingSubscription = _chat.incomingMessages.listen(_onMessage);
    _conversationsSubscription = _chat.conversationsChanged.listen(
      (_) => refresh(showLoading: false),
    );
    _connectionSubscription = _session.connectionChanges.listen((value) {
      _isConnected = value;
      notifyListeners();
    });
  }

  void start() => unawaited(refresh());

  final ChatRepository _chat;
  final SessionRepository _session;
  final ProfileRepository _profiles;
  late final StreamSubscription<ChatMessage> _incomingSubscription;
  late final StreamSubscription<void> _conversationsSubscription;
  late final StreamSubscription<bool> _connectionSubscription;

  List<ChatConversation> _conversations = const [];
  List<ChatConversation> get conversations => _conversations;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  AppError? _error;
  AppError? get error => _error;
  ChatMessage? _incomingToast;
  ChatMessage? get incomingToast => _incomingToast;
  String? _activeConversationId;
  int _refreshVersion = 0;

  int get directUnreadCount => _unreadCount(ChatConversationKind.direct);
  int get groupUnreadCount => _unreadCount(ChatConversationKind.group);

  int _unreadCount(ChatConversationKind kind) => _conversations
      .where((item) => item.kind == kind)
      .fold(0, (total, item) => total + item.unreadCount);

  List<ChatConversation> conversationsOf(ChatConversationKind kind) =>
      _conversations
          .where((conversation) => conversation.kind == kind)
          .toList(growable: false);

  ChatConversation? conversationById(String conversationId) {
    for (final conversation in _conversations) {
      if (conversation.id == conversationId) return conversation;
    }
    return null;
  }

  /// Suppresses unread increments and toasts while the user is reading a chat.
  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  void consumeIncomingToast() {
    _incomingToast = null;
  }

  void markReadLocally(String conversationId) {
    _conversations = _conversations
        .map(
          (item) =>
              item.id == conversationId ? item.copyWith(unreadCount: 0) : item,
        )
        .toList(growable: false);
    notifyListeners();
  }

  Future<void> refresh({bool showLoading = true}) async {
    final version = ++_refreshVersion;
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }
    try {
      final conversations = await _chat.loadConversations();
      final enriched = await _enrichWithProfiles(conversations);
      if (isDisposed || version != _refreshVersion) return;
      _conversations = enriched;
      _error = null;
    } catch (error) {
      if (isDisposed || version != _refreshVersion) return;
      _error = AppError.from(error);
    } finally {
      if (!isDisposed && version == _refreshVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<List<ChatConversation>> _enrichWithProfiles(
    List<ChatConversation> conversations,
  ) async {
    final directIds = conversations
        .where((item) => item.kind == ChatConversationKind.direct)
        .map((item) => item.id)
        .toSet();
    if (directIds.isEmpty) return conversations;
    try {
      final profiles = await _profiles.loadAll(directIds);
      return conversations
          .map((conversation) {
            if (conversation.kind != ChatConversationKind.direct) {
              return conversation;
            }
            final profile = profiles[conversation.id];
            if (profile == null) return conversation;
            return conversation.copyWith(
              name: profile.displayName,
              avatarUrl: profile.effectiveAvatarUrl,
            );
          })
          .toList(growable: false);
    } catch (_) {
      return conversations;
    }
  }

  void _onMessage(ChatMessage message) {
    final isActive = message.conversationId == _activeConversationId;
    final index = _conversations.indexWhere(
      (item) => item.id == message.conversationId,
    );

    if (index == -1) {
      unawaited(refresh(showLoading: false));
    } else {
      final current = _conversations[index];
      final unread = message.isOutgoing || isActive
          ? current.unreadCount
          : current.unreadCount + 1;
      final updated = current.copyWith(
        lastMessage: message.kind == ChatMessageKind.text ? message.text : '',
        lastMessageKind: message.kind,
        lastMessageSystemType: message.content is SystemMessageContent
            ? (message.content as SystemMessageContent).systemType
            : null,
        lastActivity: message.sentAt,
        unreadCount: unread,
      );
      _conversations = [
        updated,
        ..._conversations.where((item) => item.id != message.conversationId),
      ];
    }

    if (!message.isOutgoing && !isActive) _incomingToast = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _incomingSubscription.cancel();
    _conversationsSubscription.cancel();
    _connectionSubscription.cancel();
    super.dispose();
  }
}
