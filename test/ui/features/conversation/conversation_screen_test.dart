import 'package:agora_im_flutter/ui/features/conversation/views/conversation_screen.dart';
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
}
