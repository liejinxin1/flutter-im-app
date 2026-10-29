import 'package:agora_im_flutter/data/local/chat_cache.dart';
import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('ChatCache', () {
    test('round-trips conversation and message snapshots', () async {
      final store = MemoryLocalStore();
      final cache = ChatCache(store);
      final conversation = ChatConversation(
        id: 'peer',
        name: 'Bob',
        kind: ChatConversationKind.direct,
        lastMessage: 'hello',
        lastActivity: DateTime(2026),
        unreadCount: 2,
        isPinned: false,
        avatarUrl: 'https://example.com/bob.png',
      );
      final message = ChatMessage(
        id: 'm1',
        conversationId: 'peer',
        senderId: 'peer',
        text: 'hello',
        sentAt: DateTime(2026),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
        kind: ChatMessageKind.text,
      );

      await cache.saveConversations('alice', [conversation]);
      await cache.saveMessages('alice', 'peer', [message]);

      final conversations = await cache.loadConversations('alice');
      final page = await cache.loadMessages('alice', 'peer');

      expect(conversations, hasLength(1));
      expect(conversations.single.name, 'Bob');
      expect(conversations.single.avatarUrl, 'https://example.com/bob.png');
      expect(page.items, hasLength(1));
      expect(page.items.single.text, 'hello');
      expect(page.hasMore, isFalse);
    });

    test('keeps deleted messages hidden after a server refresh', () async {
      final store = MemoryLocalStore();
      final cache = ChatCache(store);
      final messages = [
        ChatMessage(
          id: 'm1',
          conversationId: 'peer',
          senderId: 'peer',
          text: 'delete me',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
          kind: ChatMessageKind.text,
        ),
        ChatMessage(
          id: 'm2',
          conversationId: 'peer',
          senderId: 'peer',
          text: 'keep me',
          sentAt: DateTime(2026, 1, 2),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
          kind: ChatMessageKind.text,
        ),
      ];
      await cache.saveMessages('alice', 'peer', messages);
      await cache.removeMessages('alice', 'peer', {'m1'});

      expect((await cache.loadMessages('alice', 'peer')).items, hasLength(1));
      expect(
        (await cache.applyOverrides('alice', 'peer', messages)).single.id,
        'm2',
      );

      await cache.saveMessages('alice', 'peer', messages);
      final page = await cache.loadMessages('alice', 'peer');
      expect(page.items.map((message) => message.id), ['m2']);
    });

    test(
      'restores recall state instead of the original message body',
      () async {
        final store = MemoryLocalStore();
        final cache = ChatCache(store);
        final original = ChatMessage(
          id: 'm1',
          conversationId: 'peer',
          senderId: 'me',
          text: 'recall me',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: true,
          kind: ChatMessageKind.text,
        );
        await cache.saveMessages('alice', 'peer', [original]);
        await cache.markRecalled('alice', 'peer', 'm1');

        final cached = await cache.loadMessages('alice', 'peer');
        expect(cached.items.single.content, isA<SystemMessageContent>());
        expect(
          (cached.items.single.content as SystemMessageContent).systemType,
          'recall',
        );

        final server = await cache.applyOverrides('alice', 'peer', [original]);
        expect(server.single.content, isA<SystemMessageContent>());
      },
    );

    test('never returns another account cache', () async {
      final store = MemoryLocalStore();
      final cache = ChatCache(store);
      await cache.saveConversations('alice', [
        const ChatConversation(
          id: 'peer',
          name: 'Bob',
          kind: ChatConversationKind.direct,
          lastMessage: 'secret',
          lastActivity: null,
          unreadCount: 0,
          isPinned: false,
        ),
      ]);

      expect(await cache.loadConversations('bob'), isEmpty);
      expect((await cache.loadMessages('bob', 'peer')).items, isEmpty);
    });

    test('restores attachment paths merged into reloaded messages', () async {
      final store = MemoryLocalStore();
      final cache = ChatCache(store);
      await cache.saveAttachmentPath(
        'alice',
        'image-1',
        thumbnailLocalPath: '/cache/thumb.jpg',
      );
      await cache.saveAttachmentPath(
        'alice',
        'image-1',
        localPath: '/cache/full.jpg',
      );

      final paths = await cache.loadAttachmentPaths('alice');
      expect(paths['image-1']?['localPath'], '/cache/full.jpg');
      expect(paths['image-1']?['thumbnailLocalPath'], '/cache/thumb.jpg');

      final merged = await cache.mergeAttachmentPaths('alice', [
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
      ]);

      expect(merged.single.localPath, '/cache/full.jpg');
      expect(merged.single.thumbnailLocalPath, '/cache/thumb.jpg');
      expect(await cache.loadAttachmentPaths('bob'), isEmpty);
    });
  });
}
