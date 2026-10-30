import 'dart:async';

import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/domain/models/friend_request_update.dart';
import 'package:agora_im_flutter/domain/models/group_member.dart';
import 'package:agora_im_flutter/domain/models/group_mute_state.dart';
import 'package:agora_im_flutter/domain/models/outbox_message.dart';
import 'package:agora_im_flutter/domain/models/picked_file.dart';
import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/domain/models/voice_recording.dart';
import 'package:agora_im_flutter/domain/repositories/chat_repository.dart';
import 'package:agora_im_flutter/domain/repositories/contact_repository.dart';
import 'package:agora_im_flutter/domain/repositories/friend_request_store.dart';
import 'package:agora_im_flutter/domain/repositories/group_repository.dart';
import 'package:agora_im_flutter/domain/repositories/outbox_repository.dart';
import 'package:agora_im_flutter/domain/repositories/profile_repository.dart';
import 'package:agora_im_flutter/domain/repositories/session_repository.dart';
import 'package:agora_im_flutter/domain/services/app_settings.dart';
import 'package:agora_im_flutter/domain/services/local_store.dart';
import 'package:agora_im_flutter/domain/services/media_gateway.dart';
import 'package:agora_im_flutter/domain/services/user_directory.dart';

class FakeChatRepository implements ChatRepository {
  final _incoming = StreamController<ChatMessage>.broadcast();
  final _updates = StreamController<ChatMessage>.broadcast();
  final _conversations = StreamController<void>.broadcast();

  List<ChatConversation> conversationItems = const [];
  final Map<String, List<ChatMessage>> history = {};
  bool loadConversationsFails = false;
  bool loadMessagesFails = false;
  bool sendTextFails = false;
  bool sendMediaFails = false;
  Completer<void>? sendTextGate;
  int sendTextCalls = 0;
  int sendFileCalls = 0;
  String? lastSentFileName;
  int loadMessagesCalls = 0;
  int markReadCalls = 0;
  int flushOutboxCalls = 0;
  String? downloadResult;
  String? thumbnailResult;
  bool thumbnailMissing = false;
  int attachmentDownloadCalls = 0;
  int thumbnailDownloadCalls = 0;
  final Set<String> deletedIds = {};
  final Set<String> recalledIds = {};
  final Set<String> forwardedMessageIds = {};
  int _serverSequence = 0;

  @override
  Stream<ChatMessage> get incomingMessages => _incoming.stream;
  @override
  Stream<ChatMessage> get messageUpdates => _updates.stream;
  @override
  Stream<void> get conversationsChanged => _conversations.stream;

  @override
  Future<List<ChatConversation>> loadConversations() async {
    if (loadConversationsFails) throw Exception('load-conversations-failed');
    return conversationItems;
  }

  @override
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async {
    loadMessagesCalls++;
    if (loadMessagesFails) throw Exception('load-messages-failed');
    final all = history[conversationId] ?? const <ChatMessage>[];
    final end = cursor == null ? all.length : int.parse(cursor);
    final start = (end - limit).clamp(0, end).toInt();
    return ChatMessagePage(
      items: all.sublist(start, end),
      cursor: start > 0 ? '$start' : null,
      hasMore: start > 0,
    );
  }

  @override
  Future<ChatMessagePage> loadCachedMessages(
    String conversationId, {
    int limit = 30,
  }) async {
    final all = history[conversationId] ?? const <ChatMessage>[];
    final start = all.length > limit ? all.length - limit : 0;
    return ChatMessagePage(
      items: all.sublist(start),
      cursor: null,
      hasMore: false,
    );
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatMessageQuote? quote,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    sendTextCalls++;
    final gate = sendTextGate;
    if (gate != null) await gate.future;
    if (sendTextFails) throw Exception('send-failed');

    final message = _serverMessage(
      conversationId: conversationId,
      text: text,
      kind: ChatMessageKind.text,
      clientId: clientId,
      quote: quote,
    );
    _record(message);
    return message;
  }

  @override
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (sendMediaFails) throw Exception('send-media-failed');
    final message = _serverMessage(
      conversationId: conversationId,
      text: '',
      kind: ChatMessageKind.image,
      clientId: clientId,
      localPath: path,
    );
    _record(message);
    return message;
  }

  @override
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (sendMediaFails) throw Exception('send-media-failed');
    final message = _serverMessage(
      conversationId: conversationId,
      text: '',
      kind: ChatMessageKind.voice,
      clientId: clientId,
      localPath: path,
      durationSeconds: durationSeconds,
    );
    _record(message);
    return message;
  }

  @override
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSizeBytes,
    String? mimeType,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (sendMediaFails) throw Exception('send-media-failed');
    sendFileCalls++;
    lastSentFileName = fileName;
    final message = ChatMessage(
      id: 'server-${++_serverSequence}',
      conversationId: conversationId,
      senderId: 'me',
      content: FileMessageContent(
        localPath: path,
        fileName: fileName,
        fileSizeBytes: fileSizeBytes ?? 0,
        mimeType: mimeType,
      ),
      sentAt: DateTime.now(),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: true,
      clientId: clientId,
    );
    _record(message);
    return message;
  }

  ChatMessage _serverMessage({
    required String conversationId,
    required String text,
    required ChatMessageKind kind,
    required String clientId,
    String? localPath,
    int durationSeconds = 0,
    ChatMessageQuote? quote,
  }) => ChatMessage(
    id: 'server-${++_serverSequence}',
    conversationId: conversationId,
    senderId: 'me',
    content: kind == ChatMessageKind.text
        ? TextMessageContent(text, quote: quote)
        : null,
    text: text,
    sentAt: DateTime.now(),
    deliveryState: ChatMessageDeliveryState.sent,
    isOutgoing: true,
    clientId: clientId,
    kind: kind,
    localPath: localPath,
    durationSeconds: durationSeconds,
  );

  void _record(ChatMessage message) {
    history.putIfAbsent(message.conversationId, () => []).add(message);
  }

  @override
  Future<String?> downloadAttachment(ChatMessage message) async {
    attachmentDownloadCalls++;
    final path = downloadResult;
    if (path != null) return path;
    return '/tmp/${message.id}';
  }

  @override
  Future<String?> downloadThumbnail(ChatMessage message) async {
    thumbnailDownloadCalls++;
    if (thumbnailMissing) return null;
    final path = thumbnailResult;
    if (path != null) return path;
    return '/tmp/thumb-${message.id}';
  }

  @override
  Future<void> deleteMessages(
    List<ChatMessage> messages, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    for (final message in messages) {
      deletedIds.add(message.id);
      final items = history[message.conversationId];
      if (items == null) continue;
      history[message.conversationId] = items
          .where((item) => item.id != message.id)
          .toList(growable: false);
    }
  }

  @override
  Future<void> recallMessage(ChatMessage message) async {
    recalledIds.add(message.id);
  }

  @override
  Future<ChatMessage> forwardMessage(
    ChatMessage message,
    String toConversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    forwardedMessageIds.add(message.id);
    final sent = _serverMessage(
      conversationId: toConversationId,
      text: message.text,
      kind: message.kind,
      clientId: 'forward-${++_serverSequence}',
    );
    _record(sent);
    return sent;
  }

  @override
  Future<void> markConversationRead(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    markReadCalls++;
  }

  @override
  Future<void> flushOutbox(String userId) async {
    flushOutboxCalls++;
  }

  void emitIncoming(ChatMessage message) {
    _record(message);
    _incoming.add(message);
  }

  void emitUpdate(ChatMessage message) => _updates.add(message);

  void notifyConversationsChanged() => _conversations.add(null);

  Future<void> dispose() async {
    await _incoming.close();
    await _updates.close();
    await _conversations.close();
  }
}

class FakeSessionRepository implements SessionRepository {
  final _connection = StreamController<bool>.broadcast();
  final _invalidated = StreamController<void>.broadcast();

  String? restoreUserId;
  String? loggedInUserId;
  Object? loginError;
  bool loggedOut = false;
  int loginCalls = 0;

  @override
  Stream<bool> get connectionChanges => _connection.stream;
  @override
  Stream<void> get sessionInvalidated => _invalidated.stream;

  @override
  Future<String?> restoreSession() async => restoreUserId;

  @override
  Future<void> login({
    required String userId,
    required String credential,
    required bool usePassword,
  }) async {
    loginCalls++;
    final error = loginError;
    if (error != null) throw error;
    loggedInUserId = userId;
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    loggedInUserId = null;
  }

  void setConnected(bool value) => _connection.add(value);

  void invalidate() => _invalidated.add(null);

  Future<void> dispose() async {
    await _connection.close();
    await _invalidated.close();
  }
}

class FakeContactRepository implements ContactRepository {
  final _requests = StreamController<FriendRequestUpdate>.broadcast();

  List<UserProfile> contactItems = const [];
  Object? loadError;
  final List<String> added = [];
  final List<String> accepted = [];
  final List<String> declined = [];
  final List<String> acceptedGroups = [];
  final List<String> declinedGroups = [];
  final Map<String, String> remarks = {};

  @override
  Stream<FriendRequestUpdate> get friendRequestUpdates => _requests.stream;

  @override
  Future<List<UserProfile>> loadContacts() async {
    final error = loadError;
    if (error != null) throw error;
    return contactItems;
  }

  @override
  Future<void> addContact(String userId) async => added.add(userId);

  @override
  Future<void> acceptContactRequest(String userId) async =>
      accepted.add(userId);

  @override
  Future<void> declineContactRequest(String userId) async =>
      declined.add(userId);

  @override
  Future<void> updateRemark(String userId, String remark) async {
    remarks[userId] = remark;
  }

  @override
  Future<void> acceptGroupInvitation(String groupId, String inviter) async {
    acceptedGroups.add(groupId);
  }

  @override
  Future<void> declineGroupInvitation(String groupId, String inviter) async {
    declinedGroups.add(groupId);
  }

  void emitRequest(FriendRequestUpdate update) => _requests.add(update);

  Future<void> dispose() => _requests.close();
}

class FakeGroupRepository implements GroupRepository {
  final List<List<String>> createdMemberIds = [];
  List<GroupMember> members = const [];
  Object? createError;
  final List<String> leftGroups = [];
  final List<String> removedMembers = [];
  final List<String> adminChanges = [];
  final List<String> invitedMembers = [];
  GroupMuteState muteState = const GroupMuteState(allMuted: false);
  String? updatedName;
  @override
  Future<String> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    final error = createError;
    if (error != null) throw error;
    createdMemberIds.add(memberIds);
    return 'group-${createdMemberIds.length}';
  }

  @override
  Future<List<GroupMember>> loadMembers(String groupId) async => members;

  @override
  Future<void> updateName(String groupId, String name) async {
    updatedName = name;
  }

  @override
  Future<void> leaveGroup(String groupId) async => leftGroups.add(groupId);

  @override
  Future<void> removeMember(String groupId, String userId) async =>
      removedMembers.add(userId);

  @override
  Future<void> setAdmin(
    String groupId,
    String userId, {
    required bool admin,
  }) async => adminChanges.add('$userId:${admin ? 'admin' : 'member'}');

  @override
  Future<void> inviteMembers(String groupId, List<String> userIds) async =>
      invitedMembers.addAll(userIds);

  @override
  Future<GroupMuteState> loadMuteState(String groupId) async => muteState;

  @override
  Future<void> setAllMuted(String groupId, bool muted) async {
    muteState = GroupMuteState(
      allMuted: muted,
      mutedUserIds: muteState.mutedUserIds,
    );
  }

  @override
  Future<void> setMemberMuted(String groupId, String userId, bool muted) async {
    final ids = {...muteState.mutedUserIds};
    if (muted) {
      ids.add(userId);
    } else {
      ids.remove(userId);
    }
    muteState = GroupMuteState(allMuted: muteState.allMuted, mutedUserIds: ids);
  }
}

class FakeProfileRepository implements ProfileRepository {
  final Map<String, UserProfile> profiles = {};
  int loadAllCalls = 0;

  @override
  Future<UserProfile> load(String userId, {bool forceRefresh = false}) async =>
      profiles[userId] ?? UserProfile(userId: userId);

  @override
  Future<Map<String, UserProfile>> loadAll(
    Iterable<String> userIds, {
    bool forceRefresh = false,
  }) async {
    loadAllCalls++;
    return {
      for (final id in userIds) id: profiles[id] ?? UserProfile(userId: id),
    };
  }

  @override
  Future<void> updateRemark(String userId, String remark) async {
    profiles[userId] = (profiles[userId] ?? UserProfile(userId: userId))
        .copyWith(remark: remark);
  }

  @override
  Future<void> updateOwnProfile(UserProfile profile) async {
    profiles[profile.userId] = profile;
  }
}

class FakeOutboxRepository implements OutboxRepository {
  final Map<String, List<OutboxMessage>> entries = {};

  @override
  Future<List<OutboxMessage>> load(
    String userId, {
    String? conversationId,
  }) async {
    final all = entries[userId] ?? const <OutboxMessage>[];
    if (conversationId == null) return List.of(all);
    return all
        .where((entry) => entry.conversationId == conversationId)
        .toList(growable: false);
  }

  @override
  Future<void> save(String userId, OutboxMessage message) async {
    final list = entries.putIfAbsent(userId, () => []);
    list.removeWhere((entry) => entry.clientId == message.clientId);
    list.add(message);
  }

  @override
  Future<void> remove(String userId, String clientId) async {
    entries[userId]?.removeWhere((entry) => entry.clientId == clientId);
  }
}

class FakeFriendRequestStore implements FriendRequestStore {
  final Map<String, List<FriendRequestUpdate>> values = {};

  @override
  Future<List<FriendRequestUpdate>> load(String userId) async =>
      List.of(values[userId] ?? const []);

  @override
  Future<void> save(String userId, List<FriendRequestUpdate> requests) async {
    values[userId] = List.of(requests);
  }
}

class MemoryLocalStore implements LocalStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

class FakeUserDirectory implements UserDirectory {
  final Map<String, UserProfile> profiles = {};
  Object? error;
  int calls = 0;

  @override
  String? currentUserId = 'me';

  @override
  Future<Map<String, UserProfile>> loadUserProfiles(
    List<String> userIds,
  ) async {
    calls++;
    final failure = error;
    if (failure != null) throw failure;
    return {
      for (final id in userIds)
        if (profiles[id] != null) id: profiles[id]!,
    };
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    profiles[profile.userId] = profile;
  }
}

class FakeAppSettings implements AppSettings {
  FakeAppSettings({this.showHistory = true});

  bool showHistory;

  @override
  Future<bool> showNetworkHistory(String userId) async => showHistory;

  @override
  Future<void> setShowNetworkHistory(String userId, bool value) async {
    showHistory = value;
  }
}

class FakeMediaGateway implements MediaGateway {
  final _completed = StreamController<void>.broadcast();

  String? imagePath = '/tmp/picked.jpg';
  Object? pickImageError;
  bool microphonePermission = true;
  Completer<bool>? permissionGate;
  Completer<void>? startRecordingGate;
  Object? startRecordingError;
  VoiceRecording? nextRecording = const VoiceRecording(
    path: '/tmp/voice.m4a',
    duration: Duration(seconds: 2),
  );
  final List<String> playedPaths = [];
  final List<String> discardedPaths = [];
  final Set<String> missingPaths = {};
  bool filesExist = true;
  int pickImageCalls = 0;
  PickedFile? nextFile = const PickedFile(
    path: '/tmp/document.pdf',
    name: 'contract.pdf',
    sizeBytes: 2048,
  );
  Object? pickFileError;
  int pickFileCalls = 0;
  int startRecordingCalls = 0;
  int stopRecordingCalls = 0;
  bool stoppedAudio = false;
  bool disposed = false;

  @override
  Stream<void> get playbackCompleted => _completed.stream;

  @override
  Future<String?> pickImage({required MediaImageSource source}) async {
    pickImageCalls++;
    final error = pickImageError;
    if (error != null) throw error;
    return imagePath;
  }

  @override
  Future<PickedFile?> pickFile() async {
    pickFileCalls++;
    final error = pickFileError;
    if (error != null) throw error;
    return nextFile;
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    final gate = permissionGate;
    if (gate != null) return gate.future;
    return microphonePermission;
  }

  @override
  Future<void> startRecording() async {
    startRecordingCalls++;
    final error = startRecordingError;
    if (error != null) throw error;
    final gate = startRecordingGate;
    if (gate != null) await gate.future;
  }

  @override
  Future<void> pauseRecording() async {}

  @override
  Future<void> resumeRecording() async {}

  @override
  Future<VoiceRecording?> stopRecording() async {
    stopRecordingCalls++;
    return nextRecording;
  }

  @override
  Future<void> discardRecording(String path) async => discardedPaths.add(path);

  @override
  Future<bool> fileExists(String path) async =>
      filesExist && !missingPaths.contains(path);

  @override
  Future<void> openFile(String path) async {}

  @override
  Future<void> playAudio(String path) async => playedPaths.add(path);

  @override
  Future<void> stopAudio() async => stoppedAudio = true;

  void completePlayback() => _completed.add(null);

  @override
  Future<void> dispose() async {
    disposed = true;
    await _completed.close();
  }
}
