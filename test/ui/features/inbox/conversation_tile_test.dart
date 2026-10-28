import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/ui/features/inbox/widgets/conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  testWidgets('shows WeChat-style previews for non-text messages', (
    tester,
  ) async {
    final cases = <(ChatMessageKind, String)>[
      (ChatMessageKind.image, '[图片]'),
      (ChatMessageKind.video, '[视频]'),
      (ChatMessageKind.voice, '[语音]'),
      (ChatMessageKind.file, '[文件]'),
      (ChatMessageKind.custom, '[自定义消息]'),
    ];

    for (final entry in cases) {
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: ConversationTile(
              conversation: _conversation(
                kind: entry.$1,
                lastMessage: 'stale generic preview',
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.$2), findsOneWidget, reason: entry.$1.name);
    }
  });

  testWidgets('shows recalled system messages and plain text', (tester) async {
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: ConversationTile(
            conversation: _conversation(
              kind: ChatMessageKind.system,
              systemType: 'recall',
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('消息已撤回'), findsOneWidget);

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: ConversationTile(
            conversation: _conversation(
              kind: ChatMessageKind.text,
              lastMessage: 'hello there',
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('hello there'), findsOneWidget);
  });
}

ChatConversation _conversation({
  required ChatMessageKind kind,
  String lastMessage = '',
  String? systemType,
}) => ChatConversation(
  id: 'peer',
  name: 'Peer',
  kind: ChatConversationKind.direct,
  lastMessage: lastMessage,
  lastActivity: DateTime(2026),
  unreadCount: 0,
  isPinned: false,
  lastMessageKind: kind,
  lastMessageSystemType: systemType,
);
