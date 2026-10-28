import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/ui/features/conversation/views/conversation_screen.dart';
import 'package:agora_im_flutter/ui/features/conversation/widgets/quoted_message_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('sends a text message from the composer', (tester) async {
    final chat = FakeChatRepository();
    final media = FakeMediaGateway();

    await tester.pumpWidget(
      testApp(
        ConversationScreen(
          repository: chat,
          media: media,
          outbox: FakeOutboxRepository(),
          currentUserId: 'me',
          peerId: 'peer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('发送一条消息，开始对话'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    expect(chat.sendTextCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('retries a failed message and clears the error banner', (
    tester,
  ) async {
    final chat = FakeChatRepository()..sendTextFails = true;
    final media = FakeMediaGateway();

    await tester.pumpWidget(
      testApp(
        ConversationScreen(
          repository: chat,
          media: media,
          outbox: FakeOutboxRepository(),
          currentUserId: 'me',
          peerId: 'peer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'try again');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('发送失败，重试'), findsOneWidget);
    expect(find.textContaining('send-failed'), findsOneWidget);

    chat.sendTextFails = false;
    await tester.tap(find.text('发送失败，重试'));
    await tester.pumpAndSettle();

    expect(find.text('发送失败，重试'), findsNothing);
    expect(find.textContaining('send-failed'), findsNothing);
    expect(find.text('try again'), findsOneWidget);
    expect(chat.sendTextCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('opens message actions and enters multi-select', (tester) async {
    final chat = FakeChatRepository();
    final media = FakeMediaGateway();
    chat.history['peer'] = [
      ChatMessage(
        id: 'm1',
        conversationId: 'peer',
        senderId: 'peer',
        content: const TextMessageContent('hello'),
        sentAt: DateTime.now(),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
      ),
    ];

    await tester.pumpWidget(
      testApp(
        ConversationScreen(
          repository: chat,
          media: media,
          outbox: FakeOutboxRepository(),
          currentUserId: 'me',
          peerId: 'peer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('hello'));
    await tester.pumpAndSettle();

    expect(find.text('复制'), findsOneWidget);
    expect(find.text('引用'), findsOneWidget);
    expect(find.text('转发'), findsOneWidget);
    expect(find.text('多选'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('多选'));
    await tester.pumpAndSettle();

    expect(find.text('已选择 1 条'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('recalls a recent outgoing message', (tester) async {
    final chat = FakeChatRepository();
    final media = FakeMediaGateway();
    chat.history['peer'] = [
      ChatMessage(
        id: 'm-recall',
        conversationId: 'peer',
        senderId: 'me',
        content: const TextMessageContent('recall me'),
        sentAt: DateTime.now(),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: true,
      ),
    ];

    await tester.pumpWidget(
      testApp(
        ConversationScreen(
          repository: chat,
          media: media,
          outbox: FakeOutboxRepository(),
          currentUserId: 'me',
          peerId: 'peer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('recall me'));
    await tester.pumpAndSettle();
    expect(find.text('撤回'), findsOneWidget);

    await tester.tap(find.text('撤回'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '撤回'));
    await tester.pumpAndSettle();

    expect(chat.recalledIds, contains('m-recall'));
    expect(find.text('消息已撤回'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('scrolls to the quoted message when the quote is tapped', (
    tester,
  ) async {
    final chat = FakeChatRepository();
    final media = FakeMediaGateway();
    final now = DateTime.now();
    chat.history['peer'] = [
      for (var index = 0; index < 29; index++)
        ChatMessage(
          id: 'm$index',
          conversationId: 'peer',
          senderId: 'peer',
          content: TextMessageContent('message $index'),
          sentAt: now.subtract(Duration(minutes: 30 - index)),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: false,
        ),
      ChatMessage(
        id: 'reply',
        conversationId: 'peer',
        senderId: 'me',
        content: const TextMessageContent(
          'reply',
          quote: ChatMessageQuote(
            messageId: 'm0',
            senderId: 'peer',
            kind: ChatMessageKind.text,
            text: 'message 0',
          ),
        ),
        sentAt: now,
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: true,
      ),
    ];

    await tester.pumpWidget(
      testApp(
        ConversationScreen(
          repository: chat,
          media: media,
          outbox: FakeOutboxRepository(),
          currentUserId: 'me',
          peerId: 'peer',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(QuotedMessagePreview));
    await tester.pumpAndSettle();

    final target = tester.getCenter(find.text('message 0').first);
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(target.dy, greaterThan(0));
    expect(target.dy, lessThan(screenHeight));

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });
}
