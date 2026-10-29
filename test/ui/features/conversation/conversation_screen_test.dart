import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/ui/features/conversation/views/conversation_screen.dart';
import 'package:agora_im_flutter/ui/features/conversation/widgets/quoted_message_preview.dart';
import 'package:agora_im_flutter/ui/features/conversation/widgets/voice_recording_bar.dart';
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

  testWidgets('opens the attachment grid and records from the sheet', (
    tester,
  ) async {
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

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();

    expect(find.text('拍摄'), findsOneWidget);
    expect(find.text('录音'), findsOneWidget);
    expect(find.text('联系人'), findsOneWidget);
    expect(find.text('相册'), findsOneWidget);
    expect(find.text('我的位置'), findsOneWidget);
    expect(find.text('文件'), findsOneWidget);

    await tester.tap(find.text('录音'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(VoiceRecordingBar), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceRecordingBar), findsNothing);
    expect(media.startRecordingCalls, 1);
    expect(media.stopRecordingCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('prompts to send or withdraw when tapping outside recording', (
    tester,
  ) async {
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

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('录音'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(VoiceRecordingBar), findsOneWidget);

    await tester.tapAt(const Offset(220, 120));
    await tester.pumpAndSettle();

    expect(find.text('发送语音？'), findsOneWidget);
    expect(media.stopRecordingCalls, 1);

    await tester.tap(find.text('撤回'));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceRecordingBar), findsNothing);
    expect(media.discardedPaths, contains('/tmp/voice.m4a'));

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('stops and sends a recording at the 60 second limit', (
    tester,
  ) async {
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

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('录音'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pump(const Duration(seconds: 61));
    await tester.pumpAndSettle();

    expect(find.byType(VoiceRecordingBar), findsNothing);
    expect(media.stopRecordingCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('shows a new message pill when reading older messages', (
    tester,
  ) async {
    final chat = FakeChatRepository();
    final media = FakeMediaGateway();
    chat.history['peer'] = [
      for (var i = 0; i < 40; i++)
        ChatMessage(
          id: 'old-$i',
          conversationId: 'peer',
          senderId: i.isEven ? 'peer' : 'me',
          content: TextMessageContent('message $i'),
          sentAt: DateTime.now().subtract(Duration(minutes: 40 - i)),
          deliveryState: ChatMessageDeliveryState.sent,
          isOutgoing: i.isOdd,
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

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
    await tester.pumpAndSettle();

    chat.emitIncoming(
      ChatMessage(
        id: 'incoming-new',
        conversationId: 'peer',
        senderId: 'peer',
        content: const TextMessageContent('new message'),
        sentAt: DateTime.now(),
        deliveryState: ChatMessageDeliveryState.sent,
        isOutgoing: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 条新消息'), findsOneWidget);

    await tester.tap(find.text('1 条新消息'));
    await tester.pumpAndSettle();

    expect(find.text('1 条新消息'), findsNothing);
    expect(find.text('new message'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('picks and sends a file from the attachment grid', (
    tester,
  ) async {
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

    await tester.tap(find.byIcon(Icons.attach_file_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('文件'));
    await tester.pumpAndSettle();

    expect(media.pickFileCalls, 1);
    expect(chat.sendFileCalls, 1);
    expect(chat.lastSentFileName, 'contract.pdf');
    expect(find.text('contract.pdf'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await chat.dispose();
    await media.dispose();
  });

  testWidgets('downloads a file message when tapped', (tester) async {
    final chat = FakeChatRepository()..downloadResult = '/tmp/received.pdf';
    final media = FakeMediaGateway();
    chat.history['peer'] = [
      ChatMessage(
        id: 'file-in',
        conversationId: 'peer',
        senderId: 'peer',
        content: const FileMessageContent(
          fileName: 'received.pdf',
          fileSizeBytes: 4096,
        ),
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

    await tester.tap(find.text('received.pdf'));
    await tester.pumpAndSettle();

    expect(find.textContaining('已打开'), findsOneWidget);

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

    expect(find.text('没有更多消息了'), findsOneWidget);
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
