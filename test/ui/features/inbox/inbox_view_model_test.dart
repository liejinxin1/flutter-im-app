import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/ui/features/inbox/view_models/inbox_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('InboxViewModel', () {
    test(
      'increments unread and exposes a toast for background messages',
      () async {
        final chat = FakeChatRepository()
          ..conversationItems = [_conversation()];
        final session = FakeSessionRepository();
        final viewModel = InboxViewModel(
          chat,
          session,
          FakeProfileRepository(),
        );
        addTearDown(chat.dispose);
        addTearDown(session.dispose);
        addTearDown(viewModel.dispose);

        await viewModel.refresh();
        expect(viewModel.conversations, hasLength(1));

        chat.emitIncoming(_message('m1'));
        await Future<void>.delayed(Duration.zero);

        expect(viewModel.conversations.single.unreadCount, 1);
        expect(viewModel.incomingToast?.id, 'm1');
      },
    );

    test('suppresses unread and toast for the open conversation', () async {
      final chat = FakeChatRepository()..conversationItems = [_conversation()];
      final session = FakeSessionRepository();
      final viewModel = InboxViewModel(chat, session, FakeProfileRepository());
      addTearDown(chat.dispose);
      addTearDown(session.dispose);
      addTearDown(viewModel.dispose);

      await viewModel.refresh();
      viewModel.setActiveConversation('peer');

      chat.emitIncoming(_message('m1'));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.conversations.single.unreadCount, 0);
      expect(viewModel.incomingToast, isNull);
    });

    test('tracks connection state from the session repository', () async {
      final chat = FakeChatRepository();
      final session = FakeSessionRepository();
      final viewModel = InboxViewModel(chat, session, FakeProfileRepository());
      addTearDown(chat.dispose);
      addTearDown(session.dispose);
      addTearDown(viewModel.dispose);

      session.setConnected(false);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isConnected, isFalse);
    });
  });
}

ChatConversation _conversation() => const ChatConversation(
  id: 'peer',
  name: null,
  kind: ChatConversationKind.direct,
  lastMessage: '',
  lastActivity: null,
  unreadCount: 0,
  isPinned: false,
);

ChatMessage _message(String id) => ChatMessage(
  id: id,
  conversationId: 'peer',
  senderId: 'peer',
  text: 'hello',
  sentAt: DateTime(2026),
  deliveryState: ChatMessageDeliveryState.sent,
  isOutgoing: false,
);
