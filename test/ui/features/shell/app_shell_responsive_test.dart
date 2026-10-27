import 'package:agora_im_flutter/app/app_dependencies.dart';
import 'package:agora_im_flutter/ui/core/widgets/app_bottom_nav.dart';
import 'package:agora_im_flutter/ui/features/auth/view_models/auth_view_model.dart';
import 'package:agora_im_flutter/ui/features/shell/views/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('uses a navigation rail on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deps = _deps();
    final auth = AuthViewModel(deps.session);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      testApp(
        AppShell(
          dependencies: deps,
          authViewModel: auth,
          currentUserId: 'alice',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await deps.dispose();
  });

  testWidgets('uses the bottom navigation on phones', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final deps = _deps();
    final auth = AuthViewModel(deps.session);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      testApp(
        AppShell(
          dependencies: deps,
          authViewModel: auth,
          currentUserId: 'alice',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await deps.dispose();
  });
}

AppDependencies _deps() => AppDependencies(
  session: FakeSessionRepository(),
  chat: FakeChatRepository(),
  contacts: FakeContactRepository(),
  groups: FakeGroupRepository(),
  media: FakeMediaGateway(),
  outbox: FakeOutboxRepository(),
  profiles: FakeProfileRepository(),
  friendRequests: FakeFriendRequestStore(),
);
