import 'chat_conversation.dart';
import 'chat_message.dart';

/// A message that has not been acknowledged by the server yet.
///
/// Persisted per account so a send survives app restarts and can be replayed
/// when connectivity returns.
class OutboxMessage {
  OutboxMessage({
    required this.clientId,
    required this.conversationId,
    required this.senderId,
    ChatMessageContent? content,
    ChatMessageKind kind = ChatMessageKind.text,
    String text = '',
    String? localPath,
    int durationSeconds = 0,
    required this.conversationKind,
    required this.createdAt,
  }) : content =
           content ??
           chatMessageContentFromLegacy(
             kind: kind,
             text: text,
             localPath: localPath,
             durationSeconds: durationSeconds,
           );

  final String clientId;
  final String conversationId;
  final String senderId;
  final ChatMessageContent content;
  final ChatConversationKind conversationKind;
  final DateTime createdAt;

  ChatMessageKind get kind => content.kind;

  String get text => switch (content) {
    TextMessageContent(:final text) => text,
    _ => '',
  };

  ChatMessage toPendingMessage() => ChatMessage(
    id: clientId,
    conversationId: conversationId,
    senderId: senderId,
    content: content,
    sentAt: createdAt,
    deliveryState: ChatMessageDeliveryState.failed,
    isOutgoing: true,
    clientId: clientId,
  );

  Map<String, Object?> toJson() => {
    'clientId': clientId,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': content.toJson(),
    'conversationKind': conversationKind.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory OutboxMessage.fromJson(Map<String, Object?> json) {
    final rawContent = json['content'];
    final content = rawContent is Map
        ? ChatMessageContent.fromJson({
            for (final entry in rawContent.entries) '${entry.key}': entry.value,
          })
        : ChatMessage.fromJson(json).content;
    return OutboxMessage(
      clientId: json['clientId'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: content,
      conversationKind: _enumByName(
        ChatConversationKind.values,
        json['conversationKind'],
        ChatConversationKind.direct,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final name = raw is String ? raw : null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
