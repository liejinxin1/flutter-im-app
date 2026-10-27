import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

abstract interface class ChatRepository {
  Stream<ChatMessage> get incomingMessages;
  Stream<ChatMessage> get messageUpdates;
  Stream<void> get conversationsChanged;

  Future<List<ChatConversation>> loadConversations();
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  });
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  });
  Future<String?> downloadAttachment(ChatMessage message);

  /// Downloads the thumbnail of an image message and returns its local path.
  ///
  /// Returns `null` when the message carries no downloadable thumbnail.
  Future<String?> downloadThumbnail(ChatMessage message);
  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  });

  /// Replays persisted outbox entries for [userId]. Safe to call repeatedly;
  /// failures stay queued for the next connectivity change.
  Future<void> flushOutbox(String userId);
}
