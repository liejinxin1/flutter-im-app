import 'chat_message_kind.dart';

enum ChatConversationKind { direct, group, chatRoom }

class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.name,
    required this.kind,
    required this.lastMessage,
    required this.lastActivity,
    required this.unreadCount,
    required this.isPinned,
    this.avatarUrl,
    this.lastMessageKind,
    this.lastMessageSystemType,
  });

  final String id;
  final String? name;
  final ChatConversationKind kind;
  final String lastMessage;
  final DateTime? lastActivity;
  final int unreadCount;
  final bool isPinned;
  final String? avatarUrl;

  /// Type of the latest message so the view can render a localized preview
  /// for image/voice messages without storing UI strings in the model.
  final ChatMessageKind? lastMessageKind;

  /// For system messages: `recall` currently distinguishes a recall preview
  /// from a generic system notice.
  final String? lastMessageSystemType;

  ChatConversation copyWith({
    String? id,
    String? name,
    ChatConversationKind? kind,
    String? lastMessage,
    DateTime? lastActivity,
    int? unreadCount,
    bool? isPinned,
    String? avatarUrl,
    ChatMessageKind? lastMessageKind,
    String? lastMessageSystemType,
  }) => ChatConversation(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    lastMessage: lastMessage ?? this.lastMessage,
    lastActivity: lastActivity ?? this.lastActivity,
    unreadCount: unreadCount ?? this.unreadCount,
    isPinned: isPinned ?? this.isPinned,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    lastMessageKind: lastMessageKind ?? this.lastMessageKind,
    lastMessageSystemType: lastMessageSystemType ?? this.lastMessageSystemType,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'lastMessage': lastMessage,
    'lastActivity': lastActivity?.millisecondsSinceEpoch,
    'unreadCount': unreadCount,
    'isPinned': isPinned,
    'avatarUrl': avatarUrl,
    'lastMessageKind': lastMessageKind?.name,
    'lastMessageSystemType': lastMessageSystemType,
  };

  factory ChatConversation.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'];
    var kind = ChatConversationKind.direct;
    for (final value in ChatConversationKind.values) {
      if (value.name == kindName) {
        kind = value;
        break;
      }
    }
    final lastActivity = (json['lastActivity'] as num?)?.toInt();
    final lastMessageKindName = json['lastMessageKind'];
    ChatMessageKind? lastMessageKind;
    for (final value in ChatMessageKind.values) {
      if (value.name == lastMessageKindName) {
        lastMessageKind = value;
        break;
      }
    }
    return ChatConversation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      kind: kind,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastActivity: lastActivity == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastActivity),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      avatarUrl: json['avatarUrl'] as String?,
      lastMessageKind: lastMessageKind,
      lastMessageSystemType: json['lastMessageSystemType'] as String?,
    );
  }
}
