import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/ui/features/groups/views/group_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('loads group members and opens a member profile', (tester) async {
    final groups = FakeGroupRepository()..memberIds = ['alice', 'bob'];
    final profiles = FakeProfileRepository()
      ..profiles['alice'] = const UserProfile(
        userId: 'alice',
        nickname: 'Alice',
      )
      ..profiles['bob'] = const UserProfile(userId: 'bob', remark: 'Bobby');
    String? opened;

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          memberCount: 2,
          groups: groups,
          profiles: profiles,
          onOpenMember: (userId) => opened = userId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bobby'), findsOneWidget);

    await tester.tap(find.text('Alice'));
    expect(opened, 'alice');
  });
}
