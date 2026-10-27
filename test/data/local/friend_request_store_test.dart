import 'package:agora_im_flutter/data/local/prefs_friend_request_store.dart';
import 'package:agora_im_flutter/domain/models/friend_request_update.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('PrefsFriendRequestStore', () {
    test('round-trips requests per account', () async {
      final store = MemoryLocalStore();
      final requestStore = PrefsFriendRequestStore(store);
      final request = FriendRequestUpdate(
        userId: 'peer',
        type: FriendRequestUpdateType.received,
        reason: 'hello',
      );

      await requestStore.save('alice', [request]);

      final loaded = await requestStore.load('alice');
      expect(loaded, hasLength(1));
      expect(loaded.single.userId, 'peer');
      expect(loaded.single.reason, 'hello');
      expect(await requestStore.load('bob'), isEmpty);
    });

    test('clears storage when the list becomes empty', () async {
      final store = MemoryLocalStore();
      final requestStore = PrefsFriendRequestStore(store);
      await requestStore.save('alice', [
        const FriendRequestUpdate(
          userId: 'peer',
          type: FriendRequestUpdateType.received,
        ),
      ]);

      await requestStore.save('alice', const []);

      expect(await requestStore.load('alice'), isEmpty);
      expect(store.values, isEmpty);
    });
  });
}
