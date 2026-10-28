import 'chat_message_kind.dart';

/// Lightweight reference to a message being quoted by a text reply.
class ChatMessageQuote {
  const ChatMessageQuote({
    required this.messageId,
    required this.senderId,
    required this.kind,
    this.text = '',
  });

  final String messageId;
  final String senderId;
  final ChatMessageKind kind;
  final String text;

  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'senderId': senderId,
    'kind': kind.name,
    'text': text,
  };

  factory ChatMessageQuote.fromJson(Map<String, Object?> json) {
    final rawKind = json['kind'];
    var kind = ChatMessageKind.text;
    for (final value in ChatMessageKind.values) {
      if (value.name == rawKind) {
        kind = value;
        break;
      }
    }
    return ChatMessageQuote(
      messageId: json['messageId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      kind: kind,
      text: json['text'] as String? ?? '',
    );
  }
}
