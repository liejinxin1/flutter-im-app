import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/ui/features/profile/view_models/profile_view_model.dart';
import 'package:agora_im_flutter/ui/features/profile/views/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';
import '../../../support/test_app.dart';

void main() {
  testWidgets('edits the signed-in user profile', (tester) async {
    final profiles = FakeProfileRepository()
      ..profiles['me'] = const UserProfile(
        userId: 'me',
        nickname: 'Old Name',
        phone: '+44 20 1234 5689',
        email: 'old@example.com',
        gender: 1,
        birthday: '1997-01-12',
      );
    final viewModel = ProfileViewModel(profiles, 'me');
    addTearDown(viewModel.dispose);
    await viewModel.load();

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: ProfileScreen(viewModel: viewModel, onLogout: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Old Name'), findsOneWidget);
    expect(find.text('+44 20 1234 5689'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '编辑资料'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'New Name');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(profiles.profiles['me']?.nickname, 'New Name');
    expect(find.text('New Name'), findsOneWidget);
  });
}
