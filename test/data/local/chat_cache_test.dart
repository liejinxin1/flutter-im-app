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
