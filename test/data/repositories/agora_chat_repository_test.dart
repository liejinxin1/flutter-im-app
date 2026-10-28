import 'package:agora_im_flutter/data/local/chat_cache.dart';
import 'package:agora_im_flutter/data/repositories/agora_chat_repository.dart';
import 'package:agora_im_flutter/data/services/agora_chat_service.dart';
import 'package:agora_im_flutter/data/services/chat_connection.dart';
import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/domain/models/chat_message_envelope.dart';
import 'package:agora_im_flutter/domain/services/message_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  late _FakeChatService service;
  late ChatConnection connection;
  late FakeOutboxRepository outbox;
  late AgoraChatRepository repository;

  setUp(() {
    service = _FakeChatService();
    connection = ChatConnection(service);
    outbox = FakeOutboxRepository();
    repository = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
    );
  });

  tearDown(() async {
    await connection.dispose();
  });

  test('falls back to the account-scoped conversation cache', () async {
    service.conversations = [
      const ChatConversation(
        id: 'peer',
        name: 'Bob',
        kind: ChatConversationKind.direct,
        lastMessage: 'hi',
        lastActivity: null,
        unreadCount: 0,
        isPinned: false,
      ),
    ];
    await repository.loadConversations();
    await Future<void>.delayed(Duration.zero);

    service.failLoads = true;
    final cached = await repository.loadConversations();

    expect(cached, hasLength(1));
    expect(cached.single.name, 'Bob');
  });

  test('keeps a failed send in the outbox and replays it', () async {
    final updates = <ChatMessage>[];
    final subscription = repository.messageUpdates.listen(updates.add);
    addTearDown(subscription.cancel);

    service.failSends = true;
    await expectLater(
      repository.sendText('peer', 'hello', clientId: 'c1'),
      throwsA(isA<Exception>()),
    );
    expect(await outbox.load('alice'), hasLength(1));

    service.failSends = false;
    await repository.flushOutbox('alice');
    await Future<void>.delayed(Duration.zero);

    expect(await outbox.load('alice'), isEmpty);
    expect(updates, hasLength(1));
    expect(updates.single.clientId, 'c1');
  });

  test('removes the outbox entry when a send succeeds immediately', () async {
    await repository.sendText('peer', 'hello', clientId: 'c1');

    expect(await outbox.load('alice'), isEmpty);
  });

  test('restores downloaded attachment paths when history reloads', () async {
    service.history['peer'] = [
      ChatMessage(
        id: 'image-1',
        conversationId: 'peer',
        senderId: 'peer',
        text: '',
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
        kind: ChatMessageKind.image,
      ),
    ];

    final first = await repository.loadMessages('peer');
    expect(first.items.single.thumbnailLocalPath, isNull);

    final path = await repository.downloadThumbnail(first.items.single);
    expect(path, '/cache/thumb.jpg');

    // Reload the same server payload; the local path must be restored.
    final reloaded = await repository.loadMessages('peer');
    expect(reloaded.items.single.thumbnailLocalPath, '/cache/thumb.jpg');
  });

  test('custom transport wraps text in the app envelope', () async {
    final custom = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.custom,
    );

    await custom.sendText('peer', 'hello', clientId: 'custom-text');

    expect(service.customSends, 1);
    expect(service.textSends, 0);
    final envelope = ChatMessageEnvelope.tryDecode(service.lastEnvelopePayload);
    expect(envelope?.content, isA<TextMessageContent>());
    expect((envelope!.content as TextMessageContent).text, 'hello');
  });

  test('quoted reply is encoded in the app envelope', () async {
    final repository = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.custom,
    );

    await repository.sendText(
      'peer',
      'reply',
      quote: const ChatMessageQuote(
        messageId: 'm1',
        senderId: 'peer',
        kind: ChatMessageKind.text,
        text: 'hello',
      ),
      clientId: 'quoted-1',
    );

    expect(service.customSends, 1);
    final envelope = ChatMessageEnvelope.tryDecode(service.lastEnvelopePayload);
    final content = envelope?.content as TextMessageContent;
    expect(content.text, 'reply');
    expect(content.quote?.messageId, 'm1');
    expect(content.quote?.text, 'hello');
  });

  test('deletes and recalls messages through the service', () async {
    final message = ChatMessage(
      id: 'm-delete',
      conversationId: 'peer',
      senderId: 'alice',
      content: const TextMessageContent('bye'),
      sentAt: DateTime(2026),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: true,
    );
    final repository = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
    );

    await repository.deleteMessages([message]);
    await repository.recallMessage(message);

    expect(service.deletedIds, contains('m-delete'));
    expect(service.recalledIds, contains('m-delete'));
  });

  test('forwards a text message to another conversation', () async {
    final message = ChatMessage(
      id: 'm-forward',
      conversationId: 'peer',
      senderId: 'alice',
      content: const TextMessageContent('forward me'),
      sentAt: DateTime(2026),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: true,
    );
    final repository = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.custom,
    );

    final forwarded = await repository.forwardMessage(message, 'other');

    expect(forwarded.conversationId, 'other');
    expect(service.customSends, 1);
    final envelope = ChatMessageEnvelope.tryDecode(service.lastEnvelopePayload);
    expect((envelope?.content as TextMessageContent).text, 'forward me');
  });

  test('hybrid attachment falls back to native without an uploader', () async {
    final hybrid = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.hybrid,
    );

    await hybrid.sendImage('peer', '/tmp/photo.jpg', clientId: 'hybrid-image');

    expect(service.imageSends, 1);
    expect(service.customSends, 0);
  });

  test('hybrid attachment uses custom envelope after OSS upload', () async {
    final uploader = _FakeUploader('https://oss.example/photo.jpg');
    final hybrid = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.hybrid,
      uploader: uploader,
    );

    await hybrid.sendImage('peer', '/tmp/photo.jpg', clientId: 'oss-image');

    expect(service.imageSends, 0);
    expect(service.customSends, 1);
    final envelope = ChatMessageEnvelope.tryDecode(service.lastEnvelopePayload);
    expect(envelope?.content, isA<ImageMessageContent>());
    expect(
      (envelope!.content as ImageMessageContent).remotePath,
      'https://oss.example/photo.jpg',
    );
  });

  test('only selected attachment kinds use custom transport', () async {
    final uploader = _FakeUploader('https://oss.example/file.pdf');
    final hybrid = AgoraChatRepository(
      connection,
      ChatCache(MemoryLocalStore()),
      outbox,
      transportMode: MessageTransportMode.hybrid,
      uploader: uploader,
      customAttachmentKinds: const {ChatMessageKind.file},
    );

    await hybrid.sendImage('peer', '/tmp/photo.jpg', clientId: 'native-image');
    expect(service.imageSends, 1);
    expect(service.customSends, 0);

    await hybrid.sendFile(
      'peer',
      '/tmp/file.pdf',
      fileName: 'file.pdf',
      clientId: 'custom-file',
    );
    expect(service.customSends, 1);
    expect(service.imageSends, 1);
    final envelope = ChatMessageEnvelope.tryDecode(service.lastEnvelopePayload);
    expect(envelope?.content, isA<FileMessageContent>());
  });
}

class _FakeUploader implements AttachmentUploader {
  _FakeUploader(this.url);

  final String url;

  @override
  Future<AttachmentUploadResult?> upload(
    AttachmentUploadRequest request,
  ) async => AttachmentUploadResult(url: url);
}

class _FakeChatService extends AgoraChatService {
  String? userId = 'alice';
  bool failLoads = false;
  bool failSends = false;
  int textSends = 0;
  int imageSends = 0;
  int customSends = 0;
  final Set<String> deletedIds = {};
  final Set<String> recalledIds = {};
  String? lastEnvelopePayload;
  int _sequence = 0;
  List<ChatConversation> conversations = const [];
  final Map<String, List<ChatMessage>> history = {};

  @override
  bool get isSupported => true;

  @override
  String? get currentUserId => userId;

  @override
  Future<List<ChatConversation>> loadConversations() async {
    if (failLoads) throw Exception('offline');
    return conversations;
  }

  @override
  Future<ChatMessagePage> loadMessages(
    String conversationId, {
    ChatConversationKind kind = ChatConversationKind.direct,
    String? cursor,
    int limit = 30,
  }) async {
    if (failLoads) throw Exception('offline');
    final items = history[conversationId] ?? const <ChatMessage>[];
    return ChatMessagePage(items: items, cursor: null, hasMore: false);
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (failSends) throw Exception('send-failed');
    textSends++;
    return _message(conversationId, text, clientId);
  }

  @override
  Future<ChatMessage> sendImage(
    String conversationId,
    String path, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (failSends) throw Exception('send-failed');
    imageSends++;
    return _message(conversationId, '', clientId);
  }

  @override
  Future<ChatMessage> sendVoice(
    String conversationId,
    String path, {
    required int durationSeconds,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (failSends) throw Exception('send-failed');
    return _message(conversationId, '', clientId);
  }

  @override
  Future<ChatMessage> sendCustom(
    String conversationId,
    String event,
    Map<String, String> params, {
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (failSends) throw Exception('send-failed');
    customSends++;
    lastEnvelopePayload = params['payload'];
    final envelope = ChatMessageEnvelope.tryDecode(params['payload']);
    return ChatMessage(
      id: 'server-${++_sequence}',
      conversationId: conversationId,
      senderId: userId ?? '',
      content: envelope?.content ?? const TextMessageContent(''),
      sentAt: DateTime(2026),
      deliveryState: ChatMessageDeliveryState.sent,
      isOutgoing: true,
      clientId: clientId,
    );
  }

  @override
  Future<ChatMessage> sendFile(
    String conversationId,
    String path, {
    String? fileName,
    int? fileSize,
    ChatConversationKind kind = ChatConversationKind.direct,
    required String clientId,
  }) async {
    if (failSends) throw Exception('send-failed');
    return _message(conversationId, '', clientId);
  }

  @override
  Future<String?> downloadAttachment(String messageId) async =>
      '/cache/full.jpg';

  @override
  Future<String?> downloadThumbnail(String messageId) async =>
      '/cache/thumb.jpg';

  @override
  Future<void> deleteMessage(
    String conversationId,
    String messageId, {
    ChatConversationKind kind = ChatConversationKind.direct,
  }) async {
    deletedIds.add(messageId);
  }

  @override
  Future<void> recallMessage(String messageId) async {
    recalledIds.add(messageId);
  }

  ChatMessage _message(String conversationId, String text, String clientId) =>
      ChatMessage(
        id: 'server-${++_sequence}',
        conversationId: conversationId,
        senderId: userId ?? '',
        text: text,
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: true,
        clientId: clientId,
      );

  @override
  Future<void> dispose() async {}
}
