import 'package:agora_im_flutter/domain/models/friend_request_update.dart';
import 'package:agora_im_flutter/ui/features/contacts/views/friend_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';

void main() {
  testWidgets('shows group invitations and processed request status', (
    tester,
  ) async {
    final responded = <FriendRequestUpdate>[];
    await tester.pumpWidget(
      testApp(
        FriendRequestsScreen(
          requests: [
            FriendRequestUpdate(
              userId: 'owner',
              targetType: FriendRequestTargetType.group,
              groupId: 'group-1',
              groupName: 'Flutter 学习群',
              inviter: 'owner',
              reason: '一起交流',
              type: FriendRequestUpdateType.received,
              occurredAt: DateTime(2026, 1, 2),
            ),
            FriendRequestUpdate(
              userId: 'peer',
              type: FriendRequestUpdateType.accepted,
              occurredAt: DateTime(2026, 1, 1),
            ),
            FriendRequestUpdate(
              userId: 'other',
              type: FriendRequestUpdateType.declined,
              occurredAt: DateTime(2025, 12, 31),
            ),
          ],
          onRespond: (request, {required accept}) async {
            responded.add(request);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('好友申请与群邀请'), findsOneWidget);
    expect(find.text('Flutter 学习群'), findsOneWidget);
    expect(find.textContaining('群聊邀请'), findsOneWidget);
    expect(find.text('已同意'), findsOneWidget);
    expect(find.text('已拒绝'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.check_circle_rounded).first);
    await tester.pumpAndSettle();

    expect(responded, hasLength(1));
    expect(responded.single.groupId, 'group-1');
    expect(responded.single.isGroup, isTrue);
  });
}
