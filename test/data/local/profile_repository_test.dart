import 'package:agora_im_flutter/data/local/prefs_profile_repository.dart';
import 'package:agora_im_flutter/domain/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('PrefsProfileRepository', () {
    test('fetches missing profiles once and reuses the cache', () async {
      final directory = FakeUserDirectory()
        ..profiles['peer'] = const UserProfile(
          userId: 'peer',
          nickname: 'Bob',
          avatarUrl: 'https://example.com/bob.png',
        );
      final repository = PrefsProfileRepository(directory, MemoryLocalStore());

      final profiles = await repository.loadAll(['peer', 'missing']);

      expect(profiles['peer']?.nickname, 'Bob');
      expect(profiles['missing']?.displayName, 'missing');
      expect(directory.calls, 1);

      await repository.loadAll(['peer']);
      expect(directory.calls, 1);
    });

    test(
      'preserves a local remark when refreshing from the directory',
      () async {
        final directory = FakeUserDirectory()
          ..profiles['peer'] = const UserProfile(
            userId: 'peer',
            nickname: 'Bob',
            phone: '+44 20 1234 5689',
          );
        final repository = PrefsProfileRepository(
          directory,
          MemoryLocalStore(),
        );
        await repository.updateRemark('peer', 'Boss');

        final profile = await repository.load('peer', forceRefresh: true);

        expect(profile.remark, 'Boss');
        expect(profile.nickname, 'Bob');
        expect(profile.phone, '+44 20 1234 5689');
      },
    );

    test('falls back to userId when the directory is unavailable', () async {
      final directory = FakeUserDirectory()..error = Exception('offline');
      final repository = PrefsProfileRepository(directory, MemoryLocalStore());

      final profile = await repository.load('peer');

      expect(profile.userId, 'peer');
      expect(profile.displayName, 'peer');
    });

    test('persists fetched profiles across repository instances', () async {
      final store = MemoryLocalStore();
      final directory = FakeUserDirectory()
        ..profiles['peer'] = const UserProfile(userId: 'peer', nickname: 'Bob');
      await PrefsProfileRepository(directory, store).loadAll(['peer']);

      final reopened = PrefsProfileRepository(directory, store);
      final profile = await reopened.load('peer');

      expect(profile.nickname, 'Bob');
      expect(directory.calls, 1);
    });
  });
}
