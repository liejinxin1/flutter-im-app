import 'dart:async';

import '../app/app_dependencies.dart';
import '../domain/models/chat_conversation.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/friend_request_update.dart';
import '../domain/models/group_member.dart';
import '../domain/models/outbox_message.dart';
import '../domain/models/picked_file.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/voice_recording.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/contact_repository.dart';
import '../domain/repositories/friend_request_store.dart';
import '../domain/repositories/group_repository.dart';
import '../domain/repositories/outbox_repository.dart';
import '../domain/repositories/profile_repository.dart';
import '../domain/repositories/session_repository.dart';
import '../domain/services/media_gateway.dart';
import '../ui/features/auth/view_models/auth_view_model.dart';

/// In-memory fixtures for the Flutter Widget Previewer.
///
/// Deliberately free of SDK, plugin, `dart:io`, and `flutter_test` imports so
/// the previewer can render the real pages without booting the app.
final DateTime previewBaseTime = DateTime(2026, 10, 26, 10, 25);

const _names = [
  'David Wayne',
  'Edward Davidson',
  'Angela Kelly',
  'Jean Dare',
  'Dennis Borer',
  'Cayla Rath',
  'Erin Turcotte',
  'Rodolfo Walter',
];

const _previews = [
  'Thanks a bunch! Have a great day!',
  'Great, thanks so much!',
  'Appreciate it! See you soon!',
  'Hooray!',
  'Your order has been successfully delivered',
  'See you soon!',
  "I'm ready to drop off your delivery.",
  'Appreciate it! Hope you enjoy it!',
];

List<ChatConversation> previewConversations() => [
  for (var index = 0; index < _names.length; index++)
    ChatConversation(
      id: index == 0 ? 'echat001' : 'user$index',
      name: _names[index],
      kind: ChatConversationKind.direct,
      lastMessage: _previews[index],
      lastActivity: previewBaseTime.subtract(Duration(hours: index * 3)),
      unreadCount: index < 3 ? (index + 1) * 4 : 0,
      isPinned: false,
    ),
  ChatConversation(
    id: 'design-team',
    name: 'Design Team',
    kind: ChatConversationKind.group,
    lastMessage: 'Angela: Updated the chat screens',
    lastActivity: previewBaseTime.subtract(const Duration(minutes: 20)),
    unreadCount: 3,
    isPinned: false,
  ),
  ChatConversation(
    id: 'product-squad',
    name: 'Product Squad',
    kind: ChatConversationKind.group,
    lastMessage: 'David: Ship it 🚀',
    lastActivity: previewBaseTime.subtract(const Duration(hours: 2)),
    unreadCount: 0,
    isPinned: false,
  ),
];

Map<String, UserProfile> previewProfiles() => {
  for (var index = 0; index < _names.length; index++)
    (index == 0 ? 'echat001' : 'user$index'): UserProfile(
      userId: index == 0 ? 'echat001' : 'user$index',
      nickname: _names[index],
    ),
  'alice': const UserProfile(userId: 'alice', nickname: 'Alex Chen'),
  'admin': const UserProfile(userId: 'admin', nickname: 'Admin'),
};

Map<String, List<ChatMessage>> previewHistory() => {
  'echat001': [
    ChatMessage(
      id: 'm1',
      conversationId: 'echat001',
      senderId: 'echat001',
      content: const TextMessageContent('What can I say man?'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 8)),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: false,
    ),
    ChatMessage(
      id: 'm2',
      conversationId: 'echat001',
      senderId: 'alice',
      content: const TextMessageContent('manba out!'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 7)),
      deliveryState: ChatMessageDeliveryState.read,
      isOutgoing: true,
    ),
    ChatMessage(
      id: 'm3',
      conversationId: 'echat001',
      senderId: 'alice',
      content: const TextMessageContent('vnm'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 6)),
      deliveryState: ChatMessageDeliveryState.read,
      isOutgoing: true,
    ),
    ChatMessage(
      id: 'm4',
      conversationId: 'echat001',
      senderId: 'echat001',
      content: const TextMessageContent('Cool car'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 5)),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: false,
    ),
    ChatMessage(
      id: 'm5',
      conversationId: 'echat001',
      senderId: 'alice',
      content: const TextMessageContent('你以为'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 4)),
      deliveryState: ChatMessageDeliveryState.read,
      isOutgoing: true,
    ),
    ChatMessage(
      id: 'm6',
      conversationId: 'echat001',
      senderId: 'alice',
      content: const VoiceMessageContent(durationSeconds: 7),
      sentAt: previewBaseTime.subtract(const Duration(hours: 3)),
      deliveryState: ChatMessageDeliveryState.read,
      isOutgoing: true,
    ),
    ChatMessage(
      id: 'm7',
      conversationId: 'echat001',
      senderId: 'echat001',
      content: const TextMessageContent('Appreciate it! Hope you enjoy it!'),
      sentAt: previewBaseTime.subtract(const Duration(hours: 2)),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: false,
    ),
  ],
};

class PreviewChatRepository implements ChatRepository {
  PreviewChatRepository({
    List<ChatConversation>? conversations,
    Map<String, List<ChatMessage>>? history,
  }) : _conversations = conversations ?? previewConversations(),
       _history = history ?? previewHistory();

  final List<ChatConversation> _conversations;
  final Map<String, List<ChatMessage>> _history;
  int _sequence = 0;

  @override
  Stream<ChatMessage> get incomingMessages => Stream<ChatMessage>.empty();
  @override
  Stream<ChatMessage> get messageUpdates => Stream<ChatMessage>.empty();
  @override
  Stream<void> get conversationsChanged => Stream<void>.empty();

  @override
  Future<List<ChatConversation>> loadConversations() async => _conversations;

  @override
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async => ChatMessagePage(
    items: _history[conversationId] ?? const [],
    cursor: null,
    hasMore: false,
  );

  @override
  Future<ChatMessagePage> loadCachedMessages(
    String conversationId, {
    int limit = 30,
  }) async => ChatMessagePage(
    items: _history[conversationId] ?? const [],
    cursor: null,
    hasMore: false,
  );

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatMessageQuote? quote,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async => _message(conversationId, text, clientId, quote: quote);

  @override
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async => _message(conversationId, '', clientId);

  @override
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async => _message(conversationId, '', clientId);

  @override
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSizeBytes,
    String? mimeType,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async => _message(conversationId, '', clientId);

  ChatMessage _message(
    String conversationId,
    String text,
    String clientId, {
    ChatMessageQuote? quote,
  }) => ChatMessage(
    id: 'preview-${++_sequence}',
    conversationId: conversationId,
    senderId: 'alice',
    content: TextMessageContent(text, quote: quote),
    sentAt: previewBaseTime,
    deliveryState: ChatMessageDeliveryState.sent,
    isOutgoing: true,
    clientId: clientId,
  );

  @override
  Future<String?> downloadAttachment(ChatMessage message) async => null;

  @override
  Future<String?> downloadThumbnail(ChatMessage message) async => null;

  @override
  Future<void> deleteMessages(
    List<ChatMessage> messages, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {}

  @override
  Future<void> recallMessage(ChatMessage message) async {}

  @override
  Future<ChatMessage> forwardMessage(
    ChatMessage message,
    String toConversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async => _message(toConversationId, message.text, 'forward-preview');

  @override
  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {}

  @override
  Future<void> flushOutbox(String userId) async {}
}

class PreviewSessionRepository implements SessionRepository {
  @override
  Stream<bool> get connectionChanges => Stream<bool>.empty();
  @override
  Stream<void> get sessionInvalidated => Stream<void>.empty();
  @override
  Future<String?> restoreSession() async => null;
  @override
  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
  }) async {}
  @override
  Future<void> logout() async {}
}

class PreviewContactRepository implements ContactRepository {
  PreviewContactRepository({List<UserProfile>? contacts})
    : _contacts = contacts ?? previewProfiles().values.toList();

  final List<UserProfile> _contacts;

  @override
  Stream<FriendRequestUpdate> get friendRequestUpdates =>
      Stream<FriendRequestUpdate>.empty();
  @override
  Future<List<UserProfile>> loadContacts() async => _contacts;
  @override
  Future<void> addContact(String userId) async {}
  @override
  Future<void> acceptContactRequest(String userId) async {}
  @override
  Future<void> declineContactRequest(String userId) async {}
  @override
  Future<void> updateRemark(String userId, String remark) async {}
  @override
  Future<void> acceptGroupInvitation(String groupId, String inviter) async {}
  @override
  Future<void> declineGroupInvitation(String groupId, String inviter) async {}
}

class PreviewProfileRepository implements ProfileRepository {
  PreviewProfileRepository({Map<String, UserProfile>? profiles})
    : _profiles = profiles ?? previewProfiles();

  final Map<String, UserProfile> _profiles;

  @override
  Future<UserProfile> load(String userId, {bool forceRefresh = false}) async =>
      _profiles[userId] ?? UserProfile(userId: userId);

  @override
  Future<Map<String, UserProfile>> loadAll(
    Iterable<String> userIds, {
    bool forceRefresh = false,
  }) async => {
    for (final id in userIds) id: _profiles[id] ?? UserProfile(userId: id),
  };

  @override
  Future<void> updateRemark(String userId, String remark) async {
    _profiles[userId] = (_profiles[userId] ?? UserProfile(userId: userId))
        .copyWith(remark: remark);
  }

  @override
  Future<void> updateOwnProfile(UserProfile profile) async {
    _profiles[profile.userId] = profile;
  }
}

class PreviewFriendRequestStore implements FriendRequestStore {
  @override
  Future<List<FriendRequestUpdate>> load(String userId) async => const [
    FriendRequestUpdate(
      userId: 'david',
      type: FriendRequestUpdateType.received,
      reason: 'Hi, I am David',
    ),
  ];
  @override
  Future<void> save(String userId, List<FriendRequestUpdate> requests) async {}
}

class PreviewOutboxRepository implements OutboxRepository {
  @override
  Future<List<OutboxMessage>> load(
    String userId, {
    String? conversationId,
  }) async => const [];
  @override
  Future<void> save(String userId, OutboxMessage message) async {}
  @override
  Future<void> remove(String userId, String clientId) async {}
}

class PreviewGroupRepository implements GroupRepository {
  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async => 'preview-group';

  @override
  Future<List<GroupMember>> loadMembers(String groupId) async => const [
    GroupMember(
      profile: UserProfile(userId: 'alice', nickname: 'Alice'),
      role: GroupMemberRole.owner,
    ),
    GroupMember(
      profile: UserProfile(userId: 'bob', nickname: 'Bob'),
      role: GroupMemberRole.admin,
    ),
    GroupMember(
      profile: UserProfile(userId: 'charlie', nickname: 'Charlie'),
      role: GroupMemberRole.member,
    ),
  ];

  @override
  Future<void> updateName(String groupId, String name) async {}

  @override
  Future<void> leaveGroup(String groupId) async {}

  @override
  Future<void> removeMember(String groupId, String userId) async {}

  @override
  Future<void> setAdmin(
    String groupId,
    String userId, {
    required bool admin,
  }) async {}
}

class PreviewMediaGateway implements MediaGateway {
  @override
  Stream<void> get playbackCompleted => Stream<void>.empty();
  @override
  Future<String?> pickImage({required MediaImageSource source}) async => null;
  @override
  Future<PickedFile?> pickFile() async => const PickedFile(
    path: '/tmp/preview.pdf',
    name: 'preview.pdf',
    sizeBytes: 1200,
  );
  @override
  Future<bool> hasMicrophonePermission() async => false;
  @override
  Future<void> startRecording() async {}
  @override
  Future<void> pauseRecording() async {}
  @override
  Future<void> resumeRecording() async {}
  @override
  Future<VoiceRecording?> stopRecording() async => null;
  @override
  Future<void> discardRecording(String path) async {}
  @override
  Future<bool> fileExists(String path) async => false;
  @override
  Future<void> openFile(String path) async {}
  @override
  Future<void> playAudio(String path) async {}
  @override
  Future<void> stopAudio() async {}
  @override
  Future<void> dispose() async {}
}

AppDependencies previewDependencies() => AppDependencies(
  session: PreviewSessionRepository(),
  chat: PreviewChatRepository(),
  contacts: PreviewContactRepository(),
  groups: PreviewGroupRepository(),
  media: PreviewMediaGateway(),
  outbox: PreviewOutboxRepository(),
  profiles: PreviewProfileRepository(),
  friendRequests: PreviewFriendRequestStore(),
);

AuthViewModel previewAuthViewModel() =>
    AuthViewModel(PreviewSessionRepository());
