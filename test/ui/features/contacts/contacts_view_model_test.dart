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

    test('accepting a request keeps processed history', () async {
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
      expect(viewModel.requestHistory, hasLength(1));
      expect(
        viewModel.requestHistory.single.type,
        FriendRequestUpdateType.accepted,
      );
      await Future<void>.delayed(Duration.zero);
      expect(store.values['alice'], hasLength(1));
      expect(
        store.values['alice']!.single.type,
        FriendRequestUpdateType.accepted,
      );
    });

    test('accepts a group invitation and keeps group metadata', () async {
      final store = FakeFriendRequestStore();
      final contacts = FakeContactRepository();
      final viewModel = ContactsViewModel(
        contacts,
        FakeProfileRepository(),
        store,
        'alice',
      );
      addTearDown(viewModel.dispose);
      await Future<void>.delayed(Duration.zero);

      contacts.emitRequest(
        FriendRequestUpdate(
          userId: 'owner',
          targetType: FriendRequestTargetType.group,
          groupId: 'group-1',
          groupName: 'Flutter',
          inviter: 'owner',
          type: FriendRequestUpdateType.received,
          occurredAt: DateTime(2026),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.pendingFriendRequests, hasLength(1));
      expect(viewModel.requestHistory, hasLength(1));

      final success = await viewModel.respondToRequest(
        viewModel.pendingFriendRequests.single,
        accept: true,
      );

      expect(success, isTrue);
      expect(contacts.acceptedGroups, ['group-1']);
      expect(viewModel.pendingFriendRequests, isEmpty);
      expect(
        viewModel.requestHistory.single.type,
        FriendRequestUpdateType.accepted,
      );
      expect(viewModel.requestHistory.single.groupName, 'Flutter');
    });

    test('updates a contact remark through the repository', () async {
      final contacts = FakeContactRepository()
        ..contactItems = const [UserProfile(userId: 'peer')];
      final viewModel = ContactsViewModel(
        contacts,
        FakeProfileRepository(),
        FakeFriendRequestStore(),
        'alice',
      );
      addTearDown(viewModel.dispose);
      await viewModel.load();

      final success = await viewModel.updateRemark('peer', 'Bobby');

      expect(success, isTrue);
      expect(contacts.remarks['peer'], 'Bobby');
      expect(viewModel.profileById('peer')?.remark, 'Bobby');
      expect(viewModel.profileById('peer')?.displayName, 'Bobby');
    });

    test('keeps only the latest status for the same group', () async {
      final contacts = FakeContactRepository();
      final viewModel = ContactsViewModel(
        contacts,
        FakeProfileRepository(),
        FakeFriendRequestStore(),
        'alice',
      );
      addTearDown(viewModel.dispose);
      await Future<void>.delayed(Duration.zero);

      contacts.emitRequest(
        FriendRequestUpdate(
          userId: 'owner',
          targetType: FriendRequestTargetType.group,
          groupId: 'group-1',
          groupName: 'Flutter',
          inviter: 'owner',
          type: FriendRequestUpdateType.received,
          occurredAt: DateTime(2026, 1, 2),
        ),
      );
      contacts.emitRequest(
        FriendRequestUpdate(
          userId: 'owner',
          targetType: FriendRequestTargetType.group,
          groupId: 'group-1',
          groupName: 'Flutter',
          inviter: 'owner',
          type: FriendRequestUpdateType.accepted,
          occurredAt: DateTime(2026, 1, 3),
        ),
      );
      contacts.emitRequest(
        FriendRequestUpdate(
          userId: 'owner',
          targetType: FriendRequestTargetType.group,
          groupId: 'group-1',
          groupName: 'Flutter',
          inviter: 'owner',
          type: FriendRequestUpdateType.received,
          occurredAt: DateTime(2026, 1, 1),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.requestHistory, hasLength(1));
      expect(
        viewModel.requestHistory.single.type,
        FriendRequestUpdateType.accepted,
      );
      expect(viewModel.pendingFriendRequests, isEmpty);
    });
  });
}
