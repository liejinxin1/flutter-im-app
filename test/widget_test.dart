import 'package:agora_im_flutter/app/app.dart';
import 'package:agora_im_flutter/app/app_dependencies.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('shows the Agora Chat sign-in screen', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('zh')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final session = FakeSessionRepository();
    final chat = FakeChatRepository();
    final contacts = FakeContactRepository();
    final media = FakeMediaGateway();
    final dependencies = AppDependencies(
      session: session,
      chat: chat,
      contacts: contacts,
      groups: FakeGroupRepository(),
      media: media,
      outbox: FakeOutboxRepository(),
      profiles: FakeProfileRepository(),
      friendRequests: FakeFriendRequestStore(),
    );

    await tester.pumpWidget(AgoraImApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('登录 Agora Chat'), findsOneWidget);
    expect(find.text('用户 ID'), findsOneWidget);
    expect(find.text('密码登录'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await session.dispose();
    await chat.dispose();
    await contacts.dispose();
    await media.dispose();
  });
}
