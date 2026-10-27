import 'dart:async';

import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/session_repository.dart';

/// Replays persisted messages when the SDK reconnects.
///
/// Owned by the app shell for the lifetime of the signed-in session; the stream
/// subscription is always cancelled on dispose.
class OutboxCoordinator {
  OutboxCoordinator(this._chat, this._session, this._userId);

  final ChatRepository _chat;
  final SessionRepository _session;
  final String _userId;
  StreamSubscription<bool>? _subscription;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _subscription = _session.connectionChanges.listen((connected) {
      if (connected) unawaited(_chat.flushOutbox(_userId));
    });
    unawaited(_chat.flushOutbox(_userId));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
