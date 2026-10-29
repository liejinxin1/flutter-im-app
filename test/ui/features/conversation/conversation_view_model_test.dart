import 'dart:async';

import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/domain/models/outbox_message.dart';
import 'package:agora_im_flutter/ui/features/conversation/view_models/conversation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('ConversationViewModel', () {
    test('replaces the optimistic message with the server copy', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      final pendingSend = viewModel.send('hello');

      expect(viewModel.messages, hasLength(1));
      expect(
        viewModel.messages.single.deliveryState,
        ChatMessageDeliveryState.sending,
      );

      await pendingSend;

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.id, startsWith('server-'));
      expect(
        viewModel.messages.single.deliveryState,
        ChatMessageDeliveryState.sent,
      );
      expect(repository.sendTextCalls, 1);
    });

    test('marks a failed send and retries the same bubble', () async {
      final repository = FakeChatRepository()..sendTextFails = true;
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.send('will fail');
      final failed = viewModel.messages.single;
      expect(failed.deliveryState, ChatMessageDeliveryState.failed);
      expect(viewModel.error, isNotNull);

      repository.sendTextFails = false;
      await viewModel.retry(failed.id);

      expect(viewModel.messages, hasLength(1));
      expect(
        viewModel.messages.single.deliveryState,
        ChatMessageDeliveryState.sent,
      );
      expect(repository.sendTextCalls, 2);
    });

    test('does not duplicate an SDK echo that shares the client id', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      final gate = Completer<void>();
      repository.sendTextGate = gate;
      final pendingSend = viewModel.send('hello');
      final clientId = viewModel.messages.single.clientId!;

      repository.emitIncoming(
        ChatMessage(
          id: 'server-echo',
          conversationId: 'peer',
          senderId: 'me',
          text: 'hello',
          sentAt: DateTime.now(),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: true,
          clientId: clientId,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.messages, hasLength(1));

      gate.complete();
      await pendingSend;

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.text, 'hello');
    });

    test('pages older history without duplicates', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = List.generate(
        55,
        (index) => ChatMessage(
          id: 'm$index',
          conversationId: 'peer',
          senderId: 'peer',
          text: 'message $index',
          sentAt: DateTime(2026).add(Duration(minutes: index)),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
        ),
      );
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      expect(viewModel.messages, hasLength(30));
      expect(viewModel.messages.first.id, 'm25');
      expect(viewModel.hasMore, isTrue);

      final added = await viewModel.loadOlder();
      expect(added, 25);
      expect(viewModel.messages, hasLength(55));
      expect(viewModel.messages.first.id, 'm0');
      expect(viewModel.hasMore, isFalse);

      expect(await viewModel.loadOlder(), 0);
    });

    test('caches the downloaded local path on the message', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = [
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
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      repository.downloadResult = '/cache/image-1.jpg';

      final path = await viewModel.downloadAttachment(
        viewModel.messages.single,
      );

      expect(path, '/cache/image-1.jpg');
      expect(viewModel.messages.single.localPath, '/cache/image-1.jpg');
    });

    test('auto-downloads thumbnails for received image messages', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.thumbnailResult = '/cache/thumb-1.jpg';
      repository.history['peer'] = [
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
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.thumbnailDownloadCalls, 1);
      expect(
        viewModel.messages.single.thumbnailLocalPath,
        '/cache/thumb-1.jpg',
      );
      expect(viewModel.messages.single.localPath, isNull);
    });

    test('reloads an image whose cached file no longer exists', () async {
      final repository = FakeChatRepository();
      final media = FakeMediaGateway()..missingPaths.add('/local/stale.jpg');
      addTearDown(repository.dispose);
      addTearDown(media.dispose);
      repository.history['peer'] = [
        ChatMessage(
          id: 'image-1',
          conversationId: 'peer',
          senderId: 'peer',
          text: '',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
          kind: ChatMessageKind.image,
          localPath: '/local/stale.jpg',
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
        media: media,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.thumbnailDownloadCalls, 1);
      expect(
        viewModel.messages.single.thumbnailLocalPath,
        '/tmp/thumb-image-1',
      );
    });

    test('auto-downloads received voice messages', () async {
      final repository = FakeChatRepository();
      final media = FakeMediaGateway();
      addTearDown(repository.dispose);
      addTearDown(media.dispose);
      repository.downloadResult = '/cache/voice-1.m4a';
      repository.history['peer'] = [
        ChatMessage(
          id: 'voice-1',
          conversationId: 'peer',
          senderId: 'peer',
          text: '',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
          kind: ChatMessageKind.voice,
          durationSeconds: 3,
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
        media: media,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.attachmentDownloadCalls, 1);
      expect(viewModel.messages.single.localPath, '/cache/voice-1.m4a');
    });

    test('skips the voice download when the local file exists', () async {
      final repository = FakeChatRepository();
      final media = FakeMediaGateway();
      addTearDown(repository.dispose);
      addTearDown(media.dispose);
      repository.history['peer'] = [
        ChatMessage(
          id: 'voice-1',
          conversationId: 'peer',
          senderId: 'peer',
          text: '',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
          kind: ChatMessageKind.voice,
          localPath: '/local/voice-1.m4a',
          durationSeconds: 3,
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
        media: media,
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.attachmentDownloadCalls, 0);
      expect(viewModel.messages.single.localPath, '/local/voice-1.m4a');
    });

    test('falls back to the original image when no thumbnail exists', () async {
      final repository = FakeChatRepository()..thumbnailMissing = true;
      addTearDown(repository.dispose);
      repository.downloadResult = '/cache/full-image.jpg';
      repository.history['peer'] = [
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
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.thumbnailDownloadCalls, 1);
      expect(viewModel.messages.single.thumbnailLocalPath, isNull);
      expect(viewModel.messages.single.localPath, '/cache/full-image.jpg');
    });

    test('skips thumbnail download when the image is already local', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = [
        ChatMessage(
          id: 'image-local',
          conversationId: 'peer',
          senderId: 'me',
          text: '',
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: true,
          kind: ChatMessageKind.image,
          localPath: '/local/image.jpg',
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();

      expect(repository.thumbnailDownloadCalls, 0);
      expect(viewModel.messages.single.localPath, '/local/image.jpg');
    });

    test('resolves the full image path by downloading the original', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = [
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
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();
      await pumpEventQueue();
      repository.downloadResult = '/cache/full-1.jpg';

      final path = await viewModel.resolveImagePath(viewModel.messages.single);

      expect(path, '/cache/full-1.jpg');
      expect(viewModel.messages.single.localPath, '/cache/full-1.jpg');
    });

    test('restores queued outbox messages as failed bubbles', () async {
      final repository = FakeChatRepository();
      final outbox = FakeOutboxRepository();
      addTearDown(repository.dispose);
      await outbox.save(
        'me',
        OutboxMessage(
          clientId: 'queued-1',
          conversationId: 'peer',
          senderId: 'me',
          kind: ChatMessageKind.text,
          conversationKind: ChatConversationKind.direct,
          createdAt: DateTime(2026),
          text: 'queued text',
        ),
      );
      final viewModel = ConversationViewModel(
        repository,
        outbox,
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.text, 'queued text');
      expect(
        viewModel.messages.single.deliveryState,
        ChatMessageDeliveryState.failed,
      );
      expect(viewModel.messages.single.clientId, 'queued-1');
    });

    test('uses cached history without network when disabled', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = [
        ChatMessage(
          id: 'cached-1',
          conversationId: 'peer',
          senderId: 'peer',
          content: const TextMessageContent('cached hello'),
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
        settings: FakeAppSettings(showHistory: false),
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();

      expect(viewModel.messages.single.text, 'cached hello');
      expect(viewModel.isLoading, isFalse);
      expect(repository.loadMessagesCalls, 0);
    });

    test('keeps cached messages when the network page is shorter', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      repository.history['peer'] = [
        ChatMessage(
          id: 'cached-1',
          conversationId: 'peer',
          senderId: 'peer',
          content: const TextMessageContent('cached hello'),
          sentAt: DateTime(2026),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
        ),
      ];
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
        settings: FakeAppSettings(showHistory: true),
      );
      addTearDown(viewModel.dispose);

      await viewModel.loadInitial();

      expect(viewModel.messages, hasLength(1));
      expect(viewModel.messages.single.text, 'cached hello');
      expect(repository.loadMessagesCalls, 1);
    });

    test('sends a quoted reply through the text content', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.send(
        'reply',
        quote: const ChatMessageQuote(
          messageId: 'm1',
          senderId: 'peer',
          kind: ChatMessageKind.text,
          text: 'hello',
        ),
      );

      final content = viewModel.messages.single.content as TextMessageContent;
      expect(content.text, 'reply');
      expect(content.quote?.messageId, 'm1');
      expect(content.quote?.text, 'hello');
    });

    test('deletes a message from the repository and timeline', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.send('delete me');
      final message = viewModel.messages.single;

      await viewModel.deleteMessages([message.id]);

      expect(viewModel.messages, isEmpty);
      expect(repository.deletedIds, contains(message.id));
    });

    test('recalls an outgoing message and renders the system state', () async {
      final repository = FakeChatRepository();
      addTearDown(repository.dispose);
      final viewModel = ConversationViewModel(
        repository,
        FakeOutboxRepository(),
        conversationId: 'peer',
        currentUserId: 'me',
      );
      addTearDown(viewModel.dispose);

      await viewModel.send('recall me');
      final message = viewModel.messages.single;

      await viewModel.recallMessage(message.id);

      expect(repository.recalledIds, contains(message.id));
      expect(viewModel.messages.single.content, isA<SystemMessageContent>());
      expect(
        (viewModel.messages.single.content as SystemMessageContent).systemType,
        'recall',
      );
    });
  });
}
