import 'package:agora_im_flutter/domain/models/friend_request_update.dart';
import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:agora_im_flutter/ui/features/contacts/view_models/contacts_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fakes.dart';

void main() {
  group('ContactsViewModel', () {
    test('restores pending requests from the store', () async {
      final store = FakeFriendRequestStore()
        ..values['alice'] = [
          const FriendRequestUpdate(
            userId: 'peer',
            type: FriendRequestUpdateType.received,
            reason: 'hi',
          ),
        ];
      final viewModel = ContactsViewModel(
        FakeContactRepository(),
        FakeProfileRepository(),
        store,
        'alice',
      );
      addTearDown(viewModel.dispose);

      await Future<void>.delayed(Duration.zero);

      expect(viewModel.pendingFriendRequests, hasLength(1));
      expect(viewModel.pendingFriendRequests.single.userId, 'peer');
    });

    test('enriches contacts with remarks and profile data', () async {
      final contacts = FakeContactRepository()
        ..contactItems = const [UserProfile(userId: 'peer', remark: 'Bobby')];
      final profiles = FakeProfileRepository()
        ..profiles['peer'] = const UserProfile(userId: 'peer', nickname: 'Bob');
      final viewModel = ContactsViewModel(
        contacts,
        profiles,
        FakeFriendRequestStore(),
        'alice',
      );
      addTearDown(viewModel.dispose);

      await viewModel.load();

      expect(viewModel.items, hasLength(1));
      expect(viewModel.items.single.displayName, 'Bobby');
      expect(viewModel.items.single.userId, 'peer');
    });

    test('accepting a request removes and persists it', () async {
      final store = FakeFriendRequestStore()
        ..values['alice'] = [
          const FriendRequestUpdate(
            userId: 'peer',
            type: FriendRequestUpdateType.received,
          ),
        ];
      final contacts = FakeContactRepository();
      final viewModel = ContactsViewModel(
        contacts,
        FakeProfileRepository(),
        store,
        'alice',
      );
      addTearDown(viewModel.dispose);
      await Future<void>.delayed(Duration.zero);

      final success = await viewModel.respondToFriendRequest(
        'peer',
        accept: true,
      );

      expect(success, isTrue);
      expect(contacts.accepted, ['peer']);
      expect(viewModel.pendingFriendRequests, isEmpty);
      await Future<void>.delayed(Duration.zero);
      expect(store.values['alice'], isEmpty);
    });
  });
}
