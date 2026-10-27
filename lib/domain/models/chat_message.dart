import 'chat_message_content.dart';
import 'chat_message_kind.dart';

export 'chat_message_content.dart';
export 'chat_message_kind.dart';

enum ChatMessageDeliveryState {
  created,
  sending,
  sent,
  delivered,
  read,
  failed,
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    ChatMessageContent? content,
    String text = '',
    ChatMessageKind kind = ChatMessageKind.text,
    String? localPath,
    int durationSeconds = 0,
    String? remotePath,
    String? secret,
    String? thumbnailLocalPath,
    required this.sentAt,
    required this.deliveryState,
    required this.isOutgoing,
    this.clientId,
  }) : content =
           content ??
           chatMessageContentFromLegacy(
             kind: kind,
             text: text,
             localPath: localPath,
             durationSeconds: durationSeconds,
             remotePath: remotePath,
             secret: secret,
             thumbnailLocalPath: thumbnailLocalPath,
           );

  final String id;
  final String conversationId;
  final String senderId;
  final ChatMessageContent content;
  final DateTime sentAt;
  final ChatMessageDeliveryState deliveryState;
  final bool isOutgoing;
  final String? clientId;

  ChatMessageKind get kind => content.kind;

  /// Compatibility getters for lightweight consumers. New code should switch
  /// on [content] so future message types are handled explicitly.
  String get text => switch (content) {
    TextMessageContent(:final text) => text,
    SystemMessageContent(:final text) => text,
    _ => '',
  };

  String? get localPath => switch (content) {
    AttachmentMessageContent(:final localPath) => localPath,
    _ => null,
  };

  String? get remotePath => switch (content) {
    AttachmentMessageContent(:final remotePath) => remotePath,
    _ => null,
  };

  String? get secret => switch (content) {
    AttachmentMessageContent(:final secret) => secret,
    _ => null,
  };

  String? get thumbnailLocalPath => switch (content) {
    ImageMessageContent(:final thumbnailLocalPath) => thumbnailLocalPath,
    VideoMessageContent(:final thumbnailLocalPath) => thumbnailLocalPath,
    _ => null,
  };

  int get durationSeconds => switch (content) {
    VoiceMessageContent(:final durationSeconds) => durationSeconds,
    VideoMessageContent(:final durationSeconds) => durationSeconds,
    _ => 0,
  };

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    ChatMessageContent? content,
    DateTime? sentAt,
    ChatMessageDeliveryState? deliveryState,
    bool? isOutgoing,
    String? clientId,
  }) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    sentAt: sentAt ?? this.sentAt,
    deliveryState: deliveryState ?? this.deliveryState,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    clientId: clientId ?? this.clientId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': content.toJson(),
    'sentAt': sentAt.millisecondsSinceEpoch,
    'deliveryState': deliveryState.name,
    'isOutgoing': isOutgoing,
    'clientId': clientId,
  };

  factory ChatMessage.fromJson(Map<String, Object?> json) {
    final rawContent = json['content'];
    final content = rawContent is Map
        ? ChatMessageContent.fromJson({
            for (final entry in rawContent.entries) '${entry.key}': entry.value,
          })
        : chatMessageContentFromLegacy(
            kind: _enumByName(
              ChatMessageKind.values,
              json['kind'],
              ChatMessageKind.text,
            ),
            text: json['text'] as String? ?? '',
            localPath: json['localPath'] as String?,
            durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
            remotePath: json['remotePath'] as String?,
            secret: json['secret'] as String?,
            thumbnailLocalPath: json['thumbnailLocalPath'] as String?,
          );
    return ChatMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: content,
      sentAt: DateTime.fromMillisecondsSinceEpoch(
        (json['sentAt'] as num?)?.toInt() ?? 0,
      ),
      deliveryState: _enumByName(
        ChatMessageDeliveryState.values,
        json['deliveryState'],
        ChatMessageDeliveryState.sent,
      ),
      isOutgoing: json['isOutgoing'] as bool? ?? false,
      clientId: json['clientId'] as String?,
    );
  }
}

/// Builds a content object from the flat pre-content-model fields.
ChatMessageContent chatMessageContentFromLegacy({
  required ChatMessageKind kind,
  String text = '',
  String? localPath,
  int durationSeconds = 0,
  String? remotePath,
  String? secret,
  String? thumbnailLocalPath,
}) {
  return switch (kind) {
    ChatMessageKind.text => TextMessageContent(text),
    ChatMessageKind.image => ImageMessageContent(
      localPath: localPath,
      remotePath: remotePath,
      secret: secret,
      thumbnailLocalPath: thumbnailLocalPath,
    ),
    ChatMessageKind.voice => VoiceMessageContent(
      localPath: localPath,
      remotePath: remotePath,
      secret: secret,
      durationSeconds: durationSeconds,
    ),
    ChatMessageKind.file => FileMessageContent(
      localPath: localPath,
      remotePath: remotePath,
      secret: secret,
    ),
    ChatMessageKind.video => VideoMessageContent(
      localPath: localPath,
      remotePath: remotePath,
      secret: secret,
      thumbnailLocalPath: thumbnailLocalPath,
      durationSeconds: durationSeconds,
    ),
    ChatMessageKind.location => const LocationMessageContent(
      latitude: 0,
      longitude: 0,
    ),
    ChatMessageKind.contact => const ContactMessageContent(userId: ''),
    ChatMessageKind.custom => const CustomMessageContent(event: ''),
    ChatMessageKind.system => TextMessageContent(text),
    ChatMessageKind.unknown => UnknownMessageContent(rawType: kind.name),
  };
}

class ChatMessagePage {
  const ChatMessagePage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<ChatMessage> items;
  final String? cursor;
  final bool hasMore;

  Map<String, Object?> toJson() => {
    'items': items.map((message) => message.toJson()).toList(growable: false),
    'cursor': cursor,
    'hasMore': hasMore,
  };

  factory ChatMessagePage.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    return ChatMessagePage(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ChatMessage.fromJson(
                    item.map((key, value) => MapEntry('$key', value)),
                  ),
                )
                .toList(growable: false)
          : const [],
      cursor: json['cursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
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
