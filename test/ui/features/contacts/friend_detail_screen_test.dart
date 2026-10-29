import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/ui/features/contacts/views/friend_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('renders friend profile and updates remark', (tester) async {
    final profiles = FakeProfileRepository()
      ..profiles['peer'] = const UserProfile(userId: 'peer', nickname: 'Bobby');
    final contacts = FakeContactRepository();

    await tester.pumpWidget(
      testApp(
        FriendDetailScreen(
          userId: 'peer',
          profiles: profiles,
          contacts: contacts,
          onOpenChat: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bobby'), findsOneWidget);
    expect(find.text('暂无备注'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bobby Chan');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('Bobby Chan'), findsWidgets);
    expect(contacts.remarks['peer'], 'Bobby Chan');
  });
}
