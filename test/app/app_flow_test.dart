import 'package:agora_im_flutter/app/app.dart';
import 'package:agora_im_flutter/app/app_dependencies.dart';
import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('login redirects to the shell', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final harness = _Harness();
    addTearDown(harness.dispose);

    await tester.pumpWidget(AgoraImApp(dependencies: harness.dependencies));
    await tester.pumpAndSettle();

    expect(find.text('登录 Agora Chat'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'alice');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('E-Chat'), findsOneWidget);
    expect(harness.session.loggedInUserId, 'alice');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens a conversation route with the cached profile name', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final harness = _Harness();
    addTearDown(harness.dispose);
    harness.session.restoreUserId = 'alice';
    harness.chat.conversationItems = [
      ChatConversation(
        id: 'peer',
        name: null,
        kind: ChatConversationKind.direct,
        lastMessage: 'hi',
        lastActivity: DateTime(2026),
        unreadCount: 1,
        isPinned: false,
      ),
    ];
    harness.profiles.profiles['peer'] = const UserProfile(
      userId: 'peer',
      nickname: 'Bob',
    );

    await tester.pumpWidget(AgoraImApp(dependencies: harness.dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();

    expect(find.text('发送一条消息，开始对话'), findsOneWidget);
    expect(find.text('Bob'), findsAtLeastNWidgets(1));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _Harness {
  final session = FakeSessionRepository();
  final chat = FakeChatRepository();
  final contacts = FakeContactRepository();
  final groups = FakeGroupRepository();
  final media = FakeMediaGateway();
  final outbox = FakeOutboxRepository();
  final profiles = FakeProfileRepository();
  final friendRequests = FakeFriendRequestStore();

  late final AppDependencies dependencies = AppDependencies(
    session: session,
    chat: chat,
    contacts: contacts,
    groups: groups,
    media: media,
    outbox: outbox,
    profiles: profiles,
    friendRequests: friendRequests,
  );

  Future<void> dispose() async {
    await session.dispose();
    await chat.dispose();
    await contacts.dispose();
    await media.dispose();
  }
}
