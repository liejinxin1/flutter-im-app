import 'package:agora_im_flutter/domain/models/group_member.dart';
import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/ui/features/groups/views/group_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('loads group members with roles and opens a profile', (
    tester,
  ) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          profile: UserProfile(
            userId: 'alice',
            nickname: 'Alice',
            phone: '+44 20 1234 5689',
          ),
          role: GroupMemberRole.admin,
        ),
        GroupMember(
          profile: UserProfile(userId: 'bob', remark: 'Bobby'),
          role: GroupMemberRole.member,
        ),
      ];
    String? opened;

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          memberCount: 3,
          currentUserId: 'me',
          groups: groups,
          contacts: FakeContactRepository(),
          onOpenMember: (userId) => opened = userId,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bobby'), findsOneWidget);
    expect(find.text('群主'), findsOneWidget);
    expect(find.text('管理员'), findsOneWidget);
    expect(find.text('+44 20 1234 5689'), findsOneWidget);

    await tester.tap(find.text('Alice'));
    expect(opened, 'alice');
  });

  testWidgets('owner can remove another member', (tester) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          profile: UserProfile(userId: 'bob', nickname: 'Bob'),
          role: GroupMemberRole.member,
        ),
      ];

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          currentUserId: 'me',
          groups: groups,
          contacts: FakeContactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('移出群聊'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(groups.removedMembers, ['bob']);
  });

  testWidgets('member can leave the group', (tester) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'owner', nickname: 'Owner'),
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.member,
        ),
      ];

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          currentUserId: 'me',
          groups: groups,
          contacts: FakeContactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, '退出群聊'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(groups.leftGroups, ['group-1']);
  });

  testWidgets('owner can mute all members', (tester) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          profile: UserProfile(userId: 'bob', nickname: 'Bob'),
          role: GroupMemberRole.member,
        ),
      ];

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          currentUserId: 'me',
          groups: groups,
          contacts: FakeContactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('全员禁言'));
    await tester.pumpAndSettle();

    expect(groups.muteState.allMuted, isTrue);
  });

  testWidgets('owner can mute a member', (tester) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.owner,
        ),
        GroupMember(
          profile: UserProfile(userId: 'bob', nickname: 'Bob'),
          role: GroupMemberRole.member,
        ),
      ];

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          currentUserId: 'me',
          groups: groups,
          contacts: FakeContactRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('禁言成员'));
    await tester.pumpAndSettle();

    expect(groups.muteState.mutedUserIds, contains('bob'));
  });

  testWidgets('owner can invite a contact', (tester) async {
    final groups = FakeGroupRepository()
      ..members = const [
        GroupMember(
          profile: UserProfile(userId: 'me', nickname: 'Me'),
          role: GroupMemberRole.owner,
        ),
      ];
    final contacts = FakeContactRepository()
      ..contactItems = const [
        UserProfile(userId: 'charlie', nickname: 'Charlie'),
      ];

    await tester.pumpWidget(
      testApp(
        GroupDetailScreen(
          groupId: 'group-1',
          groupName: 'Game',
          currentUserId: 'me',
          groups: groups,
          contacts: contacts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('邀请成员'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Charlie'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '邀请'));
    await tester.pumpAndSettle();

    expect(groups.invitedMembers, ['charlie']);
  });
}
