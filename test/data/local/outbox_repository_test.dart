import 'package:agora_im_flutter/data/local/prefs_outbox_repository.dart';
import 'package:agora_im_flutter/domain/models/chat_conversation.dart';
import 'package:agora_im_flutter/domain/models/chat_message.dart';
import 'package:agora_im_flutter/domain/models/outbox_message.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  OutboxMessage entry(String clientId, {String text = 'hi'}) => OutboxMessage(
    clientId: clientId,
    conversationId: 'peer',
    senderId: 'alice',
    kind: ChatMessageKind.text,
    conversationKind: ChatConversationKind.direct,
    createdAt: DateTime(2026),
    text: text,
  );

  group('PrefsOutboxRepository', () {
    test('persists entries and updates by client id', () async {
      final store = MemoryLocalStore();
      final repository = PrefsOutboxRepository(store);

      await repository.save('alice', entry('c1', text: 'first'));
      await repository.save('alice', entry('c1', text: 'edited'));
      await repository.save('alice', entry('c2'));

      final loaded = await repository.load('alice');
      expect(loaded, hasLength(2));
      expect(loaded.firstWhere((item) => item.clientId == 'c1').text, 'edited');

      final reopened = PrefsOutboxRepository(store);
      expect(await reopened.load('alice'), hasLength(2));
    });

    test('serializes concurrent saves without losing entries', () async {
      final repository = PrefsOutboxRepository(MemoryLocalStore());

      await Future.wait([
        for (var index = 0; index < 20; index++)
          repository.save('alice', entry('c$index')),
      ]);

      expect(await repository.load('alice'), hasLength(20));
    });

    test('filters by conversation and removes only the target entry', () async {
      final repository = PrefsOutboxRepository(MemoryLocalStore());
      await repository.save('alice', entry('c1'));
      await repository.save('alice', entry('c2'));

      expect(
        await repository.load('alice', conversationId: 'peer'),
        hasLength(2),
      );
      await repository.remove('alice', 'c1');

      final loaded = await repository.load('alice');
      expect(loaded, hasLength(1));
      expect(loaded.single.clientId, 'c2');
      expect(await repository.load('bob'), isEmpty);
    });
  });
}
