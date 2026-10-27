import 'dart:async';

import '../../domain/models/chat_message.dart';
import '../../domain/models/friend_request_update.dart';
import '../../domain/services/chat_service.dart';

/// Owns the SDK callback registration and exposes typed broadcast streams.
///
/// Repositories consume these streams; no widget ever subscribes to the SDK.
class ChatConnection {
  ChatConnection(this.service);

  final ChatService service;
  final _incoming = StreamController<ChatMessage>.broadcast();
  final _updates = StreamController<ChatMessage>.broadcast();
  final _conversations = StreamController<void>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  final _invalidated = StreamController<void>.broadcast();
  final _requests = StreamController<FriendRequestUpdate>.broadcast();
  bool _disposed = false;
  Future<void>? _disposeFuture;

  Stream<ChatMessage> get incomingMessages => _incoming.stream;
  Stream<ChatMessage> get messageUpdates => _updates.stream;
  Stream<void> get conversationsChanged => _conversations.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  Stream<void> get sessionInvalidated => _invalidated.stream;
  Stream<FriendRequestUpdate> get friendRequestUpdates => _requests.stream;

  // One connection owns SDK callbacks; repositories only consume its streams.
  Future<String?> restoreSession() {
    _checkOpen();
    return service.restoreSession(
      onMessage: (value) => _emit(_incoming, value),
      onMessageUpdate: (value) => _emit(_updates, value),
      onConversationsChanged: notifyConversationsChanged,
      onConnectionChanged: (value) => _emit(_connection, value),
      onSessionInvalidated: () => _emit(_invalidated, null),
      onFriendRequestUpdate: (value) => _emit(_requests, value),
    );
  }

  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
  }) {
    _checkOpen();
    return service.login(
      userId: userId,
      credential: credential,
      usePassword: usePassword,
      onMessage: (value) => _emit(_incoming, value),
      onMessageUpdate: (value) => _emit(_updates, value),
      onConversationsChanged: notifyConversationsChanged,
      onConnectionChanged: (value) => _emit(_connection, value),
      onSessionInvalidated: () => _emit(_invalidated, null),
      onFriendRequestUpdate: (value) => _emit(_requests, value),
    );
  }

  void notifyConversationsChanged() => _emit(_conversations, null);

  /// Used by outbox replay to publish a server-acknowledged message into the
  /// existing update pipeline (so open timelines replace failed bubbles).
  void notifyMessageUpdate(ChatMessage message) {
    _emit(_updates, message);
    notifyConversationsChanged();
  }

  void _checkOpen() {
    if (_disposed) throw StateError('Chat connection has been disposed.');
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!_disposed) controller.add(value);
  }

  Future<void> dispose() => _disposeFuture ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    try {
      await service.dispose();
    } finally {
      await Future.wait([
        _incoming.close(),
        _updates.close(),
        _conversations.close(),
        _connection.close(),
        _invalidated.close(),
        _requests.close(),
      ]);
    }
  }
}
