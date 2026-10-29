import 'package:agora_im_flutter/previews/app_previews.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final previews = <String, Widget Function()>{
    'login': loginPreview,
    'chats': chatsPreview,
    'groups': groupsPreview,
    'profile tab': profileTabPreview,
    'more tab': moreTabPreview,
    'conversation': conversationPreview,
    'group conversation': groupConversationPreview,
    'attachment sheet': attachmentSheetPreview,
    'voice recording': voiceRecordingPreview,
    'contacts': contactsPreview,
    'friend requests': friendRequestsPreview,
    'add friend': addFriendPreview,
    'create group': createGroupPreview,
    'profile page': profilePagePreview,
    'more page': morePagePreview,
  };

  for (final entry in previews.entries) {
    testWidgets('preview ${entry.key} renders without exceptions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(entry.value());
      await tester.pumpAndSettle();

      final error = tester.takeException();
      if (error is FlutterError) {
        debugPrint(error.toStringDeep());
      }
      expect(error, isNull);
    });
  }
}
