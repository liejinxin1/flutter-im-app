import 'package:agora_im_flutter/app/coordinators/outbox_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  test('replays on start and reconnect, and stops after dispose', () async {
    final chat = FakeChatRepository();
    final session = FakeSessionRepository();
    addTearDown(chat.dispose);
    addTearDown(session.dispose);

    final coordinator = OutboxCoordinator(chat, session, 'alice')..start();
    await Future<void>.delayed(Duration.zero);
    expect(chat.flushOutboxCalls, 1);

    session.setConnected(true);
    await Future<void>.delayed(Duration.zero);
    expect(chat.flushOutboxCalls, 2);

    await coordinator.dispose();
    session.setConnected(true);
    await Future<void>.delayed(Duration.zero);

    expect(chat.flushOutboxCalls, 2);
  });
}
