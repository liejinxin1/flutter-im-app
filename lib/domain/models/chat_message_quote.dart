import 'chat_message_kind.dart';

/// Lightweight reference to a message being quoted by a text reply.
class ChatMessageQuote {
  const ChatMessageQuote({
    required this.messageId,
    required this.senderId,
    required this.kind,
    this.text = '',
    this.imageUrl,
    this.fileName,
    this.durationSeconds,
    this.thumbnailPath,
    this.width,
    this.height,
  });

  final String messageId;
  final String senderId;
  final ChatMessageKind kind;
  final String text;

  /// HTTPS image/thumbnail URL included in the wire envelope.
  final String? imageUrl;

  /// Local cache path used only for the sender's quote preview.
  ///
  /// It is deliberately omitted from [toJson] so a local path never leaks to
  /// another device or into the custom message payload.
  final String? thumbnailPath;

  final String? fileName;
  final int? durationSeconds;
  final double? width;
  final double? height;

  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'senderId': senderId,
    'kind': kind.name,
    'text': text,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (fileName != null) 'fileName': fileName,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
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
      imageUrl: json['imageUrl'] as String?,
      fileName: json['fileName'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }
}
